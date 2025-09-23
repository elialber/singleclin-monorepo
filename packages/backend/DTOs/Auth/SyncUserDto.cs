using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.Auth;

/// <summary>
/// Data transfer object for syncing Firebase user with backend
/// </summary>
public class SyncUserDto
{
    /// <summary>
    /// Firebase UID
    /// </summary>
    [Required]
    public string FirebaseUid { get; set; } = string.Empty;

    /// <summary>
    /// User's email
    /// </summary>
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// User's display name
    /// </summary>
    public string? DisplayName { get; set; }

    /// <summary>
    /// User's photo URL
    /// </summary>
    public string? PhotoUrl { get; set; }

    /// <summary>
    /// Whether the user's email is verified in Firebase
    /// </summary>
    public bool? IsEmailVerified { get; set; }
}