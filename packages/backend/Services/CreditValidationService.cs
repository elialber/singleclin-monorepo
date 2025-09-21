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

            // Find user in AppDbContext
            var user = await _context.Users.FirstOrDefaultAsync(u => u.ApplicationUserId == userId);
            if (user == null)
            {
                _logger.LogWarning("User {UserId} not found in AppDbContext", userId);
                return (false, 0, new[] { "User not found" });
            }

            // Get user's active plans with remaining credits
            var activePlans = await _context.UserPlans
                .Where(up => up.UserId == user.Id &&
                           up.IsActive &&
                           up.CreditsRemaining > 0 &&
                           up.ExpirationDate > DateTime.UtcNow)
                .Include(up => up.Plan)
                .OrderBy(up => up.ExpirationDate) // Use credits from plans expiring first
                .ToListAsync();

            if (!activePlans.Any())
            {
                _logger.LogInformation("User {UserId} has no active plans with credits", userId);
                return (false, 0, new[] { "No active plans with credits available" });
            }

            // Calculate total available credits
            var totalAvailableCredits = activePlans.Sum(up => up.CreditsRemaining);

            _logger.LogInformation("User {UserId} has {AvailableCredits} total credits available, requires {CreditsRequired}",
                userId, totalAvailableCredits, creditsRequired);

            if (totalAvailableCredits < creditsRequired)
            {
                return (false, totalAvailableCredits, new[] { $"Insufficient credits. Available: {totalAvailableCredits}, Required: {creditsRequired}" });
            }

            return (true, totalAvailableCredits, Array.Empty<string>());
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

            // Find user in AppDbContext
            var user = await _context.Users.FirstOrDefaultAsync(u => u.ApplicationUserId == userId);
            if (user == null)
            {
                _logger.LogWarning("User {UserId} not found in AppDbContext", userId);
                return 0;
            }

            // Get total credits from active plans
            var totalCredits = await _context.UserPlans
                .Where(up => up.UserId == user.Id &&
                           up.IsActive &&
                           up.CreditsRemaining > 0 &&
                           up.ExpirationDate > DateTime.UtcNow)
                .SumAsync(up => up.CreditsRemaining);

            _logger.LogInformation("User {UserId} has {TotalCredits} available credits", userId, totalCredits);
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

            // Find user in AppDbContext
            var user = await _context.Users.FirstOrDefaultAsync(u => u.ApplicationUserId == userId);
            if (user == null)
            {
                _logger.LogWarning("User {UserId} not found in AppDbContext", userId);
                return Array.Empty<UserPlanResponseDto>();
            }

            var activePlans = await _context.UserPlans
                .Where(up => up.UserId == user.Id &&
                           up.IsActive &&
                           up.ExpirationDate > DateTime.UtcNow)
                .Include(up => up.Plan)
                .OrderBy(up => up.ExpirationDate)
                .ToListAsync();

            return activePlans.Select(up => new UserPlanResponseDto
            {
                Id = up.Id,
                UserId = userId,
                PlanId = up.PlanId,
                Plan = new PlanResponseDto
                {
                    Id = up.Plan.Id,
                    Name = up.Plan.Name,
                    Description = up.Plan.Description,
                    Credits = up.Plan.Credits,
                    Price = up.Plan.Price,
                    OriginalPrice = up.Plan.OriginalPrice,
                    ValidityDays = up.Plan.ValidityDays,
                    IsActive = up.Plan.IsActive,
                    DisplayOrder = up.Plan.DisplayOrder,
                    IsFeatured = up.Plan.IsFeatured,
                    CreatedAt = up.Plan.CreatedAt,
                    UpdatedAt = up.Plan.UpdatedAt
                },
                Credits = up.Credits,
                CreditsRemaining = up.CreditsRemaining,
                AmountPaid = up.AmountPaid,
                ExpirationDate = up.ExpirationDate,
                IsActive = up.IsActive,
                PaymentMethod = up.PaymentMethod,
                PaymentTransactionId = up.PaymentTransactionId,
                Notes = up.Notes,
                CreatedAt = up.CreatedAt,
                UpdatedAt = up.UpdatedAt
            });
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

            // Find user in AppDbContext
            var user = await _context.Users.FirstOrDefaultAsync(u => u.ApplicationUserId == userId);
            if (user == null)
            {
                _logger.LogWarning("User {UserId} not found in AppDbContext", userId);
                return false;
            }

            var hasActivePlans = await _context.UserPlans
                .AnyAsync(up => up.UserId == user.Id &&
                              up.IsActive &&
                              up.ExpirationDate > DateTime.UtcNow);

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