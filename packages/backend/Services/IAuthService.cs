using SingleClin.API.DTOs.Auth;

namespace SingleClin.API.Services;

/// <summary>
/// Service interface for authentication operations
/// </summary>
public interface IAuthService
{
    /// <summary>
    /// Register a new user
    /// </summary>
    /// <param name="registerDto">Registration data</param>
    /// <param name="ipAddress">Client IP address</param>
    /// <returns>Authentication response with tokens</returns>
    Task<(bool Success, AuthResponseDto? Response, string? Error)> RegisterAsync(RegisterDto registerDto, string? ipAddress = null);

    /// <summary>
    /// Authenticate a user with email and password
    /// </summary>
    /// <param name="loginDto">Login credentials</param>
    /// <param name="ipAddress">Client IP address</param>
    /// <returns>Authentication response with tokens</returns>
    Task<(bool Success, AuthResponseDto? Response, string? Error)> LoginAsync(LoginDto loginDto, string? ipAddress = null);

    /// <summary>
    /// Refresh access token using refresh token
    /// </summary>
    /// <param name="refreshToken">Refresh token</param>
    /// <param name="ipAddress">Client IP address</param>
    /// <returns>New authentication response with tokens</returns>
    Task<(bool Success, AuthResponseDto? Response, string? Error)> RefreshTokenAsync(string refreshToken, string? ipAddress = null);

    /// <summary>
    /// Logout user by invalidating refresh token
    /// </summary>
    /// <param name="userId">User ID</param>
    /// <param name="refreshToken">Current refresh token to invalidate</param>
    /// <returns>Success status</returns>
    Task<bool> LogoutAsync(Guid userId, string? refreshToken = null);

    /// <summary>
    /// Revoke all refresh tokens for a user
    /// </summary>
    /// <param name="userId">User ID</param>
    /// <returns>Number of tokens revoked</returns>
    Task<int> RevokeAllUserTokensAsync(Guid userId);

    /// <summary>
    /// Clean up expired refresh tokens
    /// </summary>
    /// <returns>Number of tokens removed</returns>
    Task<int> CleanupExpiredTokensAsync();

    /// <summary>
    /// Authenticate a user with social login
    /// </summary>
    /// <param name="socialLoginDto">Social login data</param>
    /// <param name="ipAddress">Client IP address</param>
    /// <returns>Authentication response with tokens</returns>
    Task<(bool Success, AuthResponseDto? Response, string? Error)> SocialLoginAsync(SocialLoginDto socialLoginDto, string? ipAddress = null);

    /// <summary>
    /// Get user claims for authenticated user
    /// </summary>
    /// <param name="userId">User ID</param>
    /// <returns>Dictionary of user claims</returns>
    Task<Dictionary<string, string>> GetUserClaimsAsync(Guid userId);
}