using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.DTOs.Plan;

namespace SingleClin.API.Services;

/// <summary>
/// Service for validating user credits and plan information
/// </summary>
public class CreditValidationService : ICreditValidationService
{
    private readonly AppDbContext _context;
    private readonly ILogger<CreditValidationService> _logger;

    public CreditValidationService(
        AppDbContext context,
        ILogger<CreditValidationService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<(bool HasSufficientCredits, int AvailableCredits, IEnumerable<string> Errors)> ValidateUserCreditsAsync(Guid userId, int creditsRequired)
    {
        try
        {
            _logger.LogInformation("Validating credits for user {UserId}, required: {CreditsRequired}", userId, creditsRequired);

            if (creditsRequired <= 0)
            {
                return (false, 0, new[] { "Credits required must be greater than zero" });
            }

            // Get total available credits from active user plans
            // FIXED: Use ApplicationUserId instead of UserId
            var availableCredits = await _context.UserPlans
                .Include(up => up.User)
                .Where(up => up.User.ApplicationUserId == userId && up.IsActive)
                .SumAsync(up => up.CreditsRemaining);

            _logger.LogInformation("User {UserId} has {AvailableCredits} credits available, requires {CreditsRequired}",
                userId, availableCredits, creditsRequired);

            if (availableCredits < creditsRequired)
            {
                return (false, availableCredits, new[] { $"Insufficient credits. Available: {availableCredits}, Required: {creditsRequired}" });
            }

            return (true, availableCredits, Array.Empty<string>());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error validating credits for user {UserId}", userId);
            return (false, 0, new[] { "An error occurred while validating credits" });
        }
    }

    public async Task<int> GetAvailableCreditsAsync(Guid userId)
    {
        try
        {
            _logger.LogInformation("Getting available credits for user {UserId}", userId);

            // Check if user exists first by ApplicationUserId (JWT ID)
            var userExists = await _context.Users.AnyAsync(u => u.ApplicationUserId == userId);
            if (!userExists)
            {
                _logger.LogWarning("User with ApplicationUserId {UserId} not found in database", userId);
                return 0;
            }

            // Get all UserPlans for this user by ApplicationUserId and log details
            var allUserPlans = await _context.UserPlans
                .Include(up => up.User)
                .Include(up => up.Plan)
                .Where(up => up.User.ApplicationUserId == userId)
                .Select(up => new {
                    UserPlanId = up.Id,
                    PlanName = up.Plan.Name,
                    up.Credits,
                    up.CreditsRemaining,
                    up.IsActive,
                    up.ExpirationDate,
                    IsExpired = up.ExpirationDate < DateTime.UtcNow,
                    up.CreatedAt
                })
                .ToListAsync();

            _logger.LogInformation("Found {UserPlanCount} UserPlans for user {UserId}: {@UserPlans}",
                allUserPlans.Count, userId, allUserPlans);

            // Get total available credits from active, non-expired user plans
            var totalCredits = await _context.UserPlans
                .Include(up => up.User)
                .Where(up => up.User.ApplicationUserId == userId &&
                            up.IsActive &&
                            up.ExpirationDate > DateTime.UtcNow)
                .SumAsync(up => up.CreditsRemaining);

            _logger.LogInformation("User {UserId} has {TotalCredits} available credits from active, non-expired plans",
                userId, totalCredits);

            return totalCredits;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting available credits for user {UserId}", userId);
            return 0;
        }
    }

    public async Task<IEnumerable<UserPlanResponseDto>> GetUserActivePlansAsync(Guid userId)
    {
        try
        {
            _logger.LogInformation("Getting active plans for user {UserId}", userId);

            // Get active, non-expired user plans with plan details
            // FIXED: Use ApplicationUserId instead of UserId
            var userPlans = await _context.UserPlans
                .Include(up => up.Plan)
                .Include(up => up.User)
                .Where(up => up.User.ApplicationUserId == userId &&
                            up.IsActive &&
                            up.ExpirationDate > DateTime.UtcNow)
                .Select(up => new UserPlanResponseDto
                {
                    Id = up.Id,
                    UserId = up.UserId,
                    PlanId = up.PlanId,
                    Plan = new PlanResponseDto
                    {
                        Id = up.Plan.Id,
                        Name = up.Plan.Name,
                        Description = up.Plan.Description,
                        Credits = up.Plan.Credits,
                        Price = up.Plan.Price,
                        IsActive = up.Plan.IsActive
                    },
                    Credits = up.Credits,
                    CreditsRemaining = up.CreditsRemaining,
                    AmountPaid = up.AmountPaid,
                    ExpirationDate = up.ExpirationDate,
                    IsActive = up.IsActive,
                    CreatedAt = up.CreatedAt,
                    UpdatedAt = up.UpdatedAt
                })
                .ToListAsync();

            _logger.LogInformation("User {UserId} has {PlanCount} active plans", userId, userPlans.Count);
            return userPlans;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting active plans for user {UserId}", userId);
            return Array.Empty<UserPlanResponseDto>();
        }
    }

    public async Task<bool> HasActivePlansAsync(Guid userId)
    {
        try
        {
            _logger.LogInformation("Checking if user {UserId} has active plans", userId);

            // Check if user has any active, non-expired plans
            // FIXED: Use ApplicationUserId instead of UserId
            var hasActivePlans = await _context.UserPlans
                .Include(up => up.User)
                .AnyAsync(up => up.User.ApplicationUserId == userId && up.IsActive);

            _logger.LogInformation("User {UserId} has active plans: {HasActivePlans}", userId, hasActivePlans);
            return hasActivePlans;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking active plans for user {UserId}", userId);
            return false;
        }
    }
}