using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.Auth;

/// <summary>
/// Data transfer object for Firebase authentication
/// </summary>
public class FirebaseLoginDto
{
    /// <summary>
    /// Firebase ID token obtained from Firebase Auth
    /// </summary>
    [Required(ErrorMessage = "Firebase token is required")]
    public string FirebaseToken { get; set; } = string.Empty;

    /// <summary>
    /// Device information for tracking
    /// </summary>
    public string? DeviceInfo { get; set; }

    /// <summary>
    /// Whether to remember the login (create long-lived refresh token)
    /// </summary>
    public bool RememberMe { get; set; } = false;
}