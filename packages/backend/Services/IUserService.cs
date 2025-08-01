using SingleClin.API.Data.Models;
using SingleClin.API.DTOs.Common;
using SingleClin.API.DTOs.User;

namespace SingleClin.API.Services;

/// <summary>
/// Interface for user management service
/// </summary>
public interface IUserService
{
    /// <summary>
    /// Get paginated list of users with filtering
    /// </summary>
    Task<UserListResponseDto> GetUsersAsync(UserFilterDto filter);

    /// <summary>
    /// Get user by ID
    /// </summary>
    Task<UserResponseDto?> GetUserByIdAsync(Guid id);

    /// <summary>
    /// Create new user
    /// </summary>
    Task<(bool Success, UserResponseDto? User, IEnumerable<string> Errors)> CreateUserAsync(CreateUserDto dto);

    /// <summary>
    /// Update user
    /// </summary>
    Task<(bool Success, UserResponseDto? User, IEnumerable<string> Errors)> UpdateUserAsync(Guid id, UpdateUserDto dto);

    /// <summary>
    /// Delete user
    /// </summary>
    Task<(bool Success, IEnumerable<string> Errors)> DeleteUserAsync(Guid id);

    /// <summary>
    /// Toggle user active status
    /// </summary>
    Task<(bool Success, UserResponseDto? User, IEnumerable<string> Errors)> ToggleUserStatusAsync(Guid id, bool isActive);

    /// <summary>
    /// Send password reset email
    /// </summary>
    Task<(bool Success, string Message)> SendPasswordResetEmailAsync(Guid id);

    /// <summary>
    /// Check if current user can access specified user
    /// </summary>
    Task<bool> CanAccessUserAsync(Guid userId, Guid currentUserId, bool isAdmin);

    /// <summary>
    /// Check if current user can access specified clinic
    /// </summary>
    Task<bool> CanAccessClinicAsync(Guid clinicId, Guid currentUserId, bool isAdmin);
}