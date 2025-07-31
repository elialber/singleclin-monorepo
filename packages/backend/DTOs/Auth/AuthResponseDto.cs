using SingleClin.API.Data.Enums;

namespace SingleClin.API.DTOs.Auth;

/// <summary>
/// Data transfer object for authentication response
/// </summary>
public class AuthResponseDto
{
    /// <summary>
    /// JWT access token
    /// </summary>
    public string AccessToken { get; set; } = string.Empty;

    /// <summary>
    /// Refresh token for getting new access tokens
    /// </summary>
    public string RefreshToken { get; set; } = string.Empty;

    /// <summary>
    /// Access token expiration time in seconds
    /// </summary>
    public int ExpiresIn { get; set; }

    /// <summary>
    /// User's ID
    /// </summary>
    public Guid UserId { get; set; }

    /// <summary>
    /// User's email
    /// </summary>
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// User's full name
    /// </summary>
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// User's role
    /// </summary>
    public UserRole Role { get; set; }

    /// <summary>
    /// Associated clinic ID (for clinic users)
    /// </summary>
    public Guid? ClinicId { get; set; }

    /// <summary>
    /// Indicates if this is the user's first login
    /// </summary>
    public bool IsFirstLogin { get; set; }

    /// <summary>
    /// Indicates if the user's email is verified
    /// </summary>
    public bool IsEmailVerified { get; set; }
}