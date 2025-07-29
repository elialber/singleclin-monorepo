using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.Auth;

/// <summary>
/// Data transfer object for social login
/// </summary>
public class SocialLoginDto
{
    /// <summary>
    /// Firebase ID token from social provider
    /// </summary>
    [Required(ErrorMessage = "ID token is required")]
    public string IdToken { get; set; } = string.Empty;

    /// <summary>
    /// Social provider (google, apple)
    /// </summary>
    [Required(ErrorMessage = "Provider is required")]
    [RegularExpression("^(google|apple)$", ErrorMessage = "Provider must be 'google' or 'apple'")]
    public string Provider { get; set; } = string.Empty;

    /// <summary>
    /// Device information for tracking refresh tokens
    /// </summary>
    [MaxLength(500)]
    public string? DeviceInfo { get; set; }

    /// <summary>
    /// User's full name (optional, used if not provided by social provider)
    /// </summary>
    [MaxLength(200)]
    public string? FullName { get; set; }
}