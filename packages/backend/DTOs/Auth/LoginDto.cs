using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.Auth;

/// <summary>
/// Data transfer object for user login
/// </summary>
public class LoginDto
{
    /// <summary>
    /// User's email address
    /// </summary>
    [Required(ErrorMessage = "Email is required")]
    [EmailAddress(ErrorMessage = "Invalid email format")]
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// User's password
    /// </summary>
    [Required(ErrorMessage = "Password is required")]
    public string Password { get; set; } = string.Empty;

    /// <summary>
    /// Whether to remember the user (for longer refresh token expiration)
    /// </summary>
    public bool RememberMe { get; set; } = false;

    /// <summary>
    /// Device information for tracking refresh tokens
    /// </summary>
    [MaxLength(500)]
    public string? DeviceInfo { get; set; }
}