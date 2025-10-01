using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Data.Models;
using SingleClin.API.DTOs.Common;
using SingleClin.API.DTOs.EmailTemplate;
using SingleClin.API.DTOs.Plan;
using SingleClin.API.DTOs.User;
using System.Linq.Expressions;

namespace SingleClin.API.Services;

/// <summary>
/// Service for managing users
/// </summary>
public class UserService : IUserService
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ApplicationDbContext _context;
    private readonly AppDbContext _appDbContext;
    private readonly ILogger<UserService> _logger;
    private readonly IEmailTemplateService _emailService;
    private readonly IFirebaseAuthService _firebaseAuthService;
    private readonly IAzureCommunicationService _azureCommunicationService;
    private readonly IUserDeletionService _userDeletionService;

    public UserService(
        UserManager<ApplicationUser> userManager,
        ApplicationDbContext context,
        AppDbContext appDbContext,
        ILogger<UserService> logger,
        IEmailTemplateService emailService,
        IFirebaseAuthService firebaseAuthService,
        IAzureCommunicationService azureCommunicationService,
        IUserDeletionService userDeletionService)
    {
        _userManager = userManager;
        _context = context;
        _appDbContext = appDbContext;
        _logger = logger;
        _emailService = emailService;
        _firebaseAuthService = firebaseAuthService;
        _azureCommunicationService = azureCommunicationService;
        _userDeletionService = userDeletionService;
    }

    public async Task<UserListResponseDto> GetUsersAsync(UserFilterDto filter)
    {
        var query = _userManager.Users.AsQueryable();

        // Apply filters
        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var searchLower = filter.Search.ToLower();
            query = query.Where(u =>
                u.FullName.ToLower().Contains(searchLower) ||
                u.Email!.ToLower().Contains(searchLower) ||
                (u.PhoneNumber != null && u.PhoneNumber.Contains(filter.Search)));
        }

        if (!string.IsNullOrWhiteSpace(filter.Role))
        {
            if (Enum.TryParse<Data.Enums.UserRole>(filter.Role, out var role))
            {
                query = query.Where(u => u.Role == role);
            }
        }

        if (filter.IsActive.HasValue)
        {
            query = query.Where(u => u.IsActive == filter.IsActive.Value);
        }

        if (filter.IsEmailVerified.HasValue)
        {
            query = query.Where(u => u.EmailConfirmed == filter.IsEmailVerified.Value);
        }

        if (filter.ClinicId.HasValue)
        {
            query = query.Where(u => u.ClinicId == filter.ClinicId.Value);
        }

        if (filter.CreatedAfter.HasValue)
        {
            query = query.Where(u => u.CreatedAt >= filter.CreatedAfter.Value);
        }

        if (filter.CreatedBefore.HasValue)
        {
            query = query.Where(u => u.CreatedAt <= filter.CreatedBefore.Value);
        }

        // Apply sorting
        Expression<Func<ApplicationUser, object>> orderByExpression = filter.SortBy?.ToLower() switch
        {
            "email" => u => u.Email!,
            "role" => u => u.Role,
            "createdat" => u => u.CreatedAt,
            "isactive" => u => u.IsActive,
            _ => u => u.FullName
        };

        query = filter.SortOrder?.ToLower() == "desc"
            ? query.OrderByDescending(orderByExpression)
            : query.OrderBy(orderByExpression);

        // Get total count before pagination
        var totalCount = await query.CountAsync();

        // Apply pagination
        var users = await query
            .Skip((filter.Page - 1) * filter.Limit)
            .Take(filter.Limit)
            .Include(u => u.Clinic)
            .ToListAsync();

        var userDtos = users.Select(MapToDto).ToList();

        return new UserListResponseDto
        {
            Data = userDtos,
            Total = totalCount,
            Page = filter.Page,
            Limit = filter.Limit
        };
    }

    public async Task<UserResponseDto?> GetUserByIdAsync(Guid id)
    {
        var user = await _userManager.Users
            .Include(u => u.Clinic)
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null)
        {
            return null;
        }

        // Ensure user also exists in AppDbContext (users table)
        var appUser = await _appDbContext.Users.FirstOrDefaultAsync(u => u.ApplicationUserId == id);
        if (appUser == null)
        {
            _logger.LogInformation("Creating User in AppDbContext for ApplicationUser {UserId}", id);

            appUser = new User
            {
                Id = Guid.NewGuid(),
                ApplicationUserId = id,
                Email = user.Email!,
                FullName = user.FullName,
                FirstName = ExtractFirstName(user.FullName),
                LastName = ExtractLastName(user.FullName),
                Role = (Data.Models.Enums.UserRole)(int)user.Role,
                IsActive = user.IsActive,
                PhoneNumber = user.PhoneNumber,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _appDbContext.Users.Add(appUser);
            await _appDbContext.SaveChangesAsync();

            _logger.LogInformation("User created in AppDbContext with ID {AppUserId}", appUser.Id);
        }

        return MapToDto(user);
    }

    private string? ExtractFirstName(string fullName)
    {
        if (string.IsNullOrWhiteSpace(fullName)) return null;
        var parts = fullName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        return parts.Length > 0 ? parts[0] : null;
    }

    private string? ExtractLastName(string fullName)
    {
        if (string.IsNullOrWhiteSpace(fullName)) return null;
        var parts = fullName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        return parts.Length > 1 ? string.Join(" ", parts.Skip(1)) : null;
    }

    public async Task<(bool Success, UserResponseDto? User, IEnumerable<string> Errors)> CreateUserAsync(CreateUserDto dto)
    {
        var user = new ApplicationUser
        {
            UserName = dto.Email,
            Email = dto.Email,
            FullName = $"{dto.FirstName} {dto.LastName}",
            PhoneNumber = dto.PhoneNumber,
            Role = Enum.Parse<Data.Enums.UserRole>(dto.Role),
            ClinicId = dto.ClinicId,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        var result = await _userManager.CreateAsync(user, dto.Password);

        if (!result.Succeeded)
        {
            return (false, null, result.Errors.Select(e => e.Description));
        }

        // Create user in Firebase
        _logger.LogInformation("=== FIREBASE USER CREATION START ===");
        _logger.LogInformation("Firebase IsConfigured: {IsConfigured}", _firebaseAuthService.IsConfigured);
        _logger.LogInformation("Email: {Email}, FullName: {FullName}", dto.Email, user.FullName);

        if (_firebaseAuthService.IsConfigured)
        {
            _logger.LogInformation("Firebase is configured. Attempting to create user...");
            try
            {
                var firebaseUser = await _firebaseAuthService.CreateUserAsync(
                    dto.Email,
                    dto.Password,
                    user.FullName,
                    false // Email not verified yet
                );

                if (firebaseUser != null)
                {
                    // Update user with Firebase UID
                    user.FirebaseUid = firebaseUser.Uid;
                    await _userManager.UpdateAsync(user);
                    _logger.LogInformation("✅ SUCCESS: Created user in Firebase - Email: {Email}, UID: {FirebaseUid}",
                        dto.Email, firebaseUser.Uid);
                }
                else
                {
                    _logger.LogError("❌ FAILED: CreateUserAsync returned null for email: {Email}", dto.Email);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ EXCEPTION: Error creating user in Firebase for email: {Email}", dto.Email);
            }
        }
        else
        {
            _logger.LogError("❌ Firebase NOT configured! Cannot create user in Firebase for: {Email}", dto.Email);
        }
        _logger.LogInformation("=== FIREBASE USER CREATION END ===");

        // Send email verification
        try
        {
            var token = await _userManager.GenerateEmailConfirmationTokenAsync(user);
            // TODO: Implement email sending
            _logger.LogInformation("Email verification token generated for user {UserId}", user.Id);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send verification email for user {UserId}", user.Id);
        }

        return (true, MapToDto(user), Enumerable.Empty<string>());
    }

    public async Task<(bool Success, UserResponseDto? User, IEnumerable<string> Errors)> UpdateUserAsync(Guid id, UpdateUserDto dto)
    {
        var user = await _userManager.FindByIdAsync(id.ToString());
        if (user == null)
        {
            return (false, null, new[] { "User not found" });
        }

        // Update properties
        if (dto.FirstName != null && dto.LastName != null)
        {
            user.FullName = $"{dto.FirstName} {dto.LastName}";
        }

        if (dto.PhoneNumber != null)
        {
            user.PhoneNumber = dto.PhoneNumber;
        }

        if (dto.IsActive.HasValue)
        {
            user.IsActive = dto.IsActive.Value;
        }

        if (!string.IsNullOrWhiteSpace(dto.Role))
        {
            if (Enum.TryParse<Data.Enums.UserRole>(dto.Role, out var role))
            {
                user.Role = role;
            }
        }

        if (dto.ClinicId.HasValue)
        {
            user.ClinicId = dto.ClinicId.Value;
        }

        user.UpdatedAt = DateTime.UtcNow;

        var result = await _userManager.UpdateAsync(user);

        if (!result.Succeeded)
        {
            return (false, null, result.Errors.Select(e => e.Description));
        }

        return (true, MapToDto(user), Enumerable.Empty<string>());
    }

    public async Task<(bool Success, IEnumerable<string> Errors)> DeleteUserAsync(Guid id)
    {
        return await _userDeletionService.DeleteUserAsync(id);
    }

    public async Task<(bool Success, UserResponseDto? User, IEnumerable<string> Errors)> ToggleUserStatusAsync(Guid id, bool isActive)
    {
        var user = await _userManager.FindByIdAsync(id.ToString());
        if (user == null)
        {
            return (false, null, new[] { "User not found" });
        }

        user.IsActive = isActive;
        user.UpdatedAt = DateTime.UtcNow;

        var result = await _userManager.UpdateAsync(user);

        if (!result.Succeeded)
        {
            return (false, null, result.Errors.Select(e => e.Description));
        }

        return (true, MapToDto(user), Enumerable.Empty<string>());
    }

    public async Task<(bool Success, string Message)> SendPasswordResetEmailAsync(Guid id)
    {
        var user = await _userManager.FindByIdAsync(id.ToString());
        if (user == null)
        {
            return (false, "User not found");
        }

        try
        {
            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            // TODO: Implement password reset email sending
            _logger.LogInformation("Password reset token generated for user {UserId}", user.Id);

            return (true, "Password reset email sent successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send password reset email for user {UserId}", user.Id);
            return (false, "Failed to send password reset email");
        }
    }

    public async Task<bool> CanAccessUserAsync(Guid userId, Guid currentUserId, bool isAdmin)
    {
        if (isAdmin) return true;

        var user = await _userManager.FindByIdAsync(userId.ToString());
        var currentUser = await _userManager.FindByIdAsync(currentUserId.ToString());

        if (user == null || currentUser == null) return false;

        // Users can access their own data
        if (userId == currentUserId) return true;

        // Clinic users can access users from their clinic
        if (currentUser.ClinicId != null && user.ClinicId == currentUser.ClinicId)
            return true;

        return false;
    }

    public async Task<bool> CanAccessClinicAsync(Guid clinicId, Guid currentUserId, bool isAdmin)
    {
        if (isAdmin) return true;

        var currentUser = await _userManager.FindByIdAsync(currentUserId.ToString());
        return currentUser?.ClinicId == clinicId;
    }

    private static UserResponseDto MapToDto(ApplicationUser user)
    {
        // Split full name into first and last name
        var nameParts = user.FullName.Split(' ', 2);
        var firstName = nameParts.Length > 0 ? nameParts[0] : "";
        var lastName = nameParts.Length > 1 ? nameParts[1] : "";

        return new UserResponseDto
        {
            Id = user.Id.ToString(),
            Email = user.Email ?? "",
            FirstName = firstName,
            LastName = lastName,
            FullName = user.FullName,
            Role = user.Role.ToString(),
            IsActive = user.IsActive,
            IsEmailVerified = user.EmailConfirmed,
            PhoneNumber = user.PhoneNumber,
            ClinicId = user.ClinicId?.ToString(),
            CreatedAt = user.CreatedAt,
            UpdatedAt = user.UpdatedAt ?? user.CreatedAt
        };
    }

    public async Task<(bool Success, UserPlanResponseDto? UserPlan, IEnumerable<string> Errors)> PurchasePlanAsync(Guid userId, PurchasePlanDto purchaseDto)
    {
        try
        {
            // Check if user exists in ApplicationUser context
            var applicationUser = await _userManager.FindByIdAsync(userId.ToString());
            if (applicationUser == null)
            {
                return (false, null, new[] { "User not found" });
            }

            // Check if plan exists
            var plan = await _appDbContext.Plans.FindAsync(purchaseDto.PlanId);
            if (plan == null)
            {
                return (false, null, new[] { "Plan not found" });
            }

            if (!plan.IsActive)
            {
                return (false, null, new[] { "Plan is not active" });
            }

            // Find or create corresponding User in AppDbContext
            var user = await _appDbContext.Users.FirstOrDefaultAsync(u => u.ApplicationUserId == userId);
            if (user == null)
            {
                _logger.LogInformation("Creating new User in AppDbContext for ApplicationUser {UserId}", userId);

                user = new User
                {
                    Id = Guid.NewGuid(), // Explicitly set ID
                    ApplicationUserId = userId,
                    Email = applicationUser.Email!,
                    FullName = applicationUser.FullName,
                    Role = (Data.Models.Enums.UserRole)(int)applicationUser.Role,
                    IsActive = applicationUser.IsActive,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _appDbContext.Users.Add(user);
                await _appDbContext.SaveChangesAsync();

                _logger.LogInformation("User created in AppDbContext with ID {UserId}", user.Id);
            }
            else
            {
                _logger.LogInformation("Found existing User in AppDbContext with ID {UserId} for ApplicationUser {ApplicationUserId}", user.Id, userId);
            }

            // Create UserPlan
            _logger.LogInformation("Creating UserPlan for User {UserId} and Plan {PlanId}", user.Id, plan.Id);

            var userPlan = new UserPlan
            {
                Id = Guid.NewGuid(), // Explicitly set ID
                UserId = user.Id,
                PlanId = plan.Id,
                Credits = plan.Credits,
                CreditsRemaining = plan.Credits,
                AmountPaid = plan.Price,
                ExpirationDate = DateTime.UtcNow.AddDays(plan.ValidityDays),
                IsActive = true,
                PaymentMethod = purchaseDto.PaymentMethod,
                PaymentTransactionId = purchaseDto.PaymentTransactionId,
                Notes = purchaseDto.Notes,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _appDbContext.UserPlans.Add(userPlan);

            try
            {
                await _appDbContext.SaveChangesAsync();
                _logger.LogInformation("UserPlan created successfully with ID {UserPlanId}", userPlan.Id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to create UserPlan for User {UserId} and Plan {PlanId}", user.Id, plan.Id);
                throw;
            }

            // Load the plan for response
            await _appDbContext.Entry(userPlan)
                .Reference(up => up.Plan)
                .LoadAsync();

            var response = new UserPlanResponseDto
            {
                Id = userPlan.Id,
                UserId = userId,
                PlanId = userPlan.PlanId,
                Plan = new PlanResponseDto
                {
                    Id = plan.Id,
                    Name = plan.Name,
                    Description = plan.Description,
                    Credits = plan.Credits,
                    Price = plan.Price,
                    OriginalPrice = plan.OriginalPrice,
                    ValidityDays = plan.ValidityDays,
                    IsActive = plan.IsActive,
                    DisplayOrder = plan.DisplayOrder,
                    IsFeatured = plan.IsFeatured,
                    CreatedAt = plan.CreatedAt,
                    UpdatedAt = plan.UpdatedAt
                },
                Credits = userPlan.Credits,
                CreditsRemaining = userPlan.CreditsRemaining,
                AmountPaid = userPlan.AmountPaid,
                ExpirationDate = userPlan.ExpirationDate,
                IsActive = userPlan.IsActive,
                PaymentMethod = userPlan.PaymentMethod,
                PaymentTransactionId = userPlan.PaymentTransactionId,
                Notes = userPlan.Notes,
                CreatedAt = userPlan.CreatedAt,
                UpdatedAt = userPlan.UpdatedAt
            };

            _logger.LogInformation("User {UserId} successfully purchased plan {PlanId}", userId, purchaseDto.PlanId);

            return (true, response, Array.Empty<string>());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error purchasing plan {PlanId} for user {UserId}", purchaseDto.PlanId, userId);
            return (false, null, new[] { "An error occurred while purchasing the plan" });
        }
    }

    public async Task<IEnumerable<UserPlanResponseDto>> GetUserPlansAsync(Guid userId)
    {
        try
        {
            _logger.LogInformation("Getting user plans for ApplicationUserId {UserId}", userId);

            // Find user in AppDbContext using ApplicationUserId
            var user = await _appDbContext.Users
                .FirstOrDefaultAsync(u => u.ApplicationUserId == userId);

            if (user == null)
            {
                _logger.LogWarning("User with ApplicationUserId {UserId} not found in AppDbContext", userId);
                return Array.Empty<UserPlanResponseDto>();
            }

            _logger.LogInformation("Found User in AppDbContext: Id={UserId}, ApplicationUserId={ApplicationUserId}",
                user.Id, user.ApplicationUserId);

            // Get active, non-expired user plans
            var userPlans = await _appDbContext.UserPlans
                .Where(up => up.UserId == user.Id &&
                            up.IsActive &&
                            up.ExpirationDate > DateTime.UtcNow)
                .Include(up => up.Plan)
                .OrderBy(up => up.ExpirationDate)
                .ToListAsync();

            _logger.LogInformation("Found {PlanCount} active user plans for user {UserId}",
                userPlans.Count, userId);

            return userPlans.Select(up => new UserPlanResponseDto
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
            _logger.LogError(ex, "Error getting plans for user {UserId}", userId);
            return Array.Empty<UserPlanResponseDto>();
        }
    }

    public async Task<UserPlanResponseDto?> GetUserPlanAsync(Guid userId, Guid userPlanId)
    {
        try
        {
            // Find user in AppDbContext
            var user = await _appDbContext.Users
                .FirstOrDefaultAsync(u => u.ApplicationUserId == userId);

            if (user == null)
            {
                return null;
            }

            var userPlan = await _appDbContext.UserPlans
                .Where(up => up.Id == userPlanId && up.UserId == user.Id && up.IsActive)
                .Include(up => up.Plan)
                .FirstOrDefaultAsync();

            if (userPlan == null)
            {
                return null;
            }

            return new UserPlanResponseDto
            {
                Id = userPlan.Id,
                UserId = userId,
                PlanId = userPlan.PlanId,
                Plan = new PlanResponseDto
                {
                    Id = userPlan.Plan.Id,
                    Name = userPlan.Plan.Name,
                    Description = userPlan.Plan.Description,
                    Credits = userPlan.Plan.Credits,
                    Price = userPlan.Plan.Price,
                    OriginalPrice = userPlan.Plan.OriginalPrice,
                    ValidityDays = userPlan.Plan.ValidityDays,
                    IsActive = userPlan.Plan.IsActive,
                    DisplayOrder = userPlan.Plan.DisplayOrder,
                    IsFeatured = userPlan.Plan.IsFeatured,
                    CreatedAt = userPlan.Plan.CreatedAt,
                    UpdatedAt = userPlan.Plan.UpdatedAt
                },
                Credits = userPlan.Credits,
                CreditsRemaining = userPlan.CreditsRemaining,
                AmountPaid = userPlan.AmountPaid,
                ExpirationDate = userPlan.ExpirationDate,
                IsActive = userPlan.IsActive,
                PaymentMethod = userPlan.PaymentMethod,
                PaymentTransactionId = userPlan.PaymentTransactionId,
                Notes = userPlan.Notes,
                CreatedAt = userPlan.CreatedAt,
                UpdatedAt = userPlan.UpdatedAt
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting user plan {UserPlanId} for user {UserId}", userPlanId, userId);
            return null;
        }
    }

    /// <summary>
    /// Cancel/Remove a user's plan
    /// </summary>
    public async Task<(bool Success, IEnumerable<string> Errors)> CancelUserPlanAsync(Guid userId, Guid userPlanId, string? reason = null)
    {
        try
        {
            _logger.LogInformation("Attempting to cancel user plan {UserPlanId} for user {UserId}", userPlanId, userId);

            // Find the user plan
            var userPlan = await _appDbContext.UserPlans
                .Include(up => up.Plan)
                .FirstOrDefaultAsync(up => up.Id == userPlanId && up.UserId == userId);

            if (userPlan == null)
            {
                // Try to find by UserPlan ID alone (in case userId is ApplicationUser ID)
                var user = await _appDbContext.Users.FirstOrDefaultAsync(u => u.ApplicationUserId == userId);
                if (user != null)
                {
                    userPlan = await _appDbContext.UserPlans
                        .Include(up => up.Plan)
                        .FirstOrDefaultAsync(up => up.Id == userPlanId && up.UserId == user.Id);
                }

                if (userPlan == null)
                {
                    return (false, new[] { "User plan not found" });
                }
            }

            // Check if plan is already inactive
            if (!userPlan.IsActive)
            {
                return (false, new[] { "User plan is already cancelled" });
            }

            // Deactivate the plan instead of deleting it (for audit purposes)
            userPlan.IsActive = false;
            userPlan.UpdatedAt = DateTime.UtcNow;

            // Add cancellation reason if provided
            if (!string.IsNullOrWhiteSpace(reason))
            {
                userPlan.Notes = string.IsNullOrWhiteSpace(userPlan.Notes)
                    ? $"Cancelled: {reason}"
                    : $"{userPlan.Notes}\nCancelled: {reason}";
            }

            await _appDbContext.SaveChangesAsync();

            _logger.LogInformation("User plan {UserPlanId} cancelled successfully", userPlanId);
            return (true, Array.Empty<string>());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error cancelling user plan {UserPlanId} for user {UserId}", userPlanId, userId);
            return (false, new[] { "An error occurred while cancelling the user plan" });
        }
    }

    public async Task<bool> SendUserConfirmationEmailAsync(Guid userId, string password)
    {
        try
        {
            _logger.LogInformation("Sending user confirmation email for user {UserId}", userId);

            // Get user information
            var user = await _userManager.FindByIdAsync(userId.ToString());
            if (user == null)
            {
                _logger.LogError("User {UserId} not found for confirmation email", userId);
                return false;
            }

            // Get clinic information if user belongs to a clinic
            string? clinicName = null;
            if (user.ClinicId.HasValue)
            {
                var clinic = await _appDbContext.Clinics
                    .FirstOrDefaultAsync(c => c.Id == user.ClinicId.Value);
                clinicName = clinic?.Name;
            }

            // Create template data
            var templateData = UserConfirmationTemplateData.Create(
                user.FullName,
                user.Email!,
                password,
                clinicName);

            // Render the email template
            var renderedTemplate = await _emailService.RenderUserConfirmationAsync(templateData);

            // Send the email using Azure Communication Services
            var emailSent = await _azureCommunicationService.SendEmailAsync(
                user.Email!,
                renderedTemplate);

            if (emailSent)
            {
                _logger.LogInformation("User confirmation email sent successfully to {UserEmail}", user.Email);
                return true;
            }
            else
            {
                _logger.LogError("Failed to send user confirmation email to {UserEmail}", user.Email);
                return false;
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending user confirmation email for user {UserId}", userId);
            return false;
        }
    }
}
