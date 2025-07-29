using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.Auth;

/// <summary>
/// Data transfer object for refresh token request
/// </summary>
public class RefreshTokenDto
{
    /// <summary>
    /// The refresh token
    /// </summary>
    [Required(ErrorMessage = "Refresh token is required")]
    public string RefreshToken { get; set; } = string.Empty;

    /// <summary>
    /// Device information for tracking refresh tokens
    /// </summary>
    [MaxLength(500)]
    public string? DeviceInfo { get; set; }
}