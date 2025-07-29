using SingleClin.API.Data.Models;

namespace SingleClin.API.Services;

/// <summary>
/// Service interface for refresh token management
/// </summary>
public interface IRefreshTokenService
{
    /// <summary>
    /// Create and store a new refresh token for a user
    /// </summary>
    /// <param name="userId">User ID</param>
    /// <param name="ipAddress">Client IP address</param>
    /// <param name="deviceInfo">Device information</param>
    /// <param name="expirationDays">Token expiration in days</param>
    /// <returns>The created refresh token</returns>
    Task<RefreshToken> CreateRefreshTokenAsync(Guid userId, string? ipAddress = null, string? deviceInfo = null, int? expirationDays = null);

    /// <summary>
    /// Validate a refresh token and return the associated user ID
    /// </summary>
    /// <param name="token">Refresh token to validate</param>
    /// <returns>User ID if valid, null otherwise</returns>
    Task<Guid?> ValidateRefreshTokenAsync(string token);

    /// <summary>
    /// Revoke a specific refresh token
    /// </summary>
    /// <param name="token">Token to revoke</param>
    /// <returns>Success status</returns>
    Task<bool> RevokeTokenAsync(string token);

    /// <summary>
    /// Revoke all refresh tokens for a user
    /// </summary>
    /// <param name="userId">User ID</param>
    /// <returns>Number of tokens revoked</returns>
    Task<int> RevokeAllUserTokensAsync(Guid userId);

    /// <summary>
    /// Get active refresh tokens for a user
    /// </summary>
    /// <param name="userId">User ID</param>
    /// <returns>List of active refresh tokens</returns>
    Task<IEnumerable<RefreshToken>> GetActiveUserTokensAsync(Guid userId);

    /// <summary>
    /// Clean up expired refresh tokens
    /// </summary>
    /// <returns>Number of tokens removed</returns>
    Task<int> CleanupExpiredTokensAsync();

    /// <summary>
    /// Update device info for a refresh token
    /// </summary>
    /// <param name="token">Refresh token</param>
    /// <param name="deviceInfo">New device information</param>
    /// <returns>Success status</returns>
    Task<bool> UpdateDeviceInfoAsync(string token, string deviceInfo);
}