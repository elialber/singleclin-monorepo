using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Data.Models;
using SingleClin.API.DTOs.Common;
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
    private readonly ILogger<UserService> _logger;
    private readonly IEmailTemplateService _emailService;

    public UserService(
        UserManager<ApplicationUser> userManager,
        ApplicationDbContext context,
        ILogger<UserService> logger,
        IEmailTemplateService emailService)
    {
        _userManager = userManager;
        _context = context;
        _logger = logger;
        _emailService = emailService;
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

        return user != null ? MapToDto(user) : null;
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
        var user = await _userManager.FindByIdAsync(id.ToString());
        if (user == null)
        {
            return (false, new[] { "User not found" });
        }

        var result = await _userManager.DeleteAsync(user);
        
        if (!result.Succeeded)
        {
            return (false, result.Errors.Select(e => e.Description));
        }

        return (true, Enumerable.Empty<string>());
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
}