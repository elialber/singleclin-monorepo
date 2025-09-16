namespace SingleClin.API.Data.Models;

/// <summary>
/// Refresh token for JWT authentication
/// </summary>
public class RefreshToken : BaseEntity
{
    /// <summary>
    /// The token value
    /// </summary>
    public string Token { get; set; } = string.Empty;

    /// <summary>
    /// User ID this token belongs to
    /// </summary>
    public Guid UserId { get; set; }

    /// <summary>
    /// Navigation property to the user
    /// </summary>
    public virtual ApplicationUser User { get; set; } = null!;

    /// <summary>
    /// When the token expires
    /// </summary>
    public DateTime ExpiresAt { get; set; }

    /// <summary>
    /// Whether the token has been revoked
    /// </summary>
    public bool IsRevoked { get; set; } = false;

    /// <summary>
    /// When the token was revoked
    /// </summary>
    public DateTime? RevokedAt { get; set; }

    /// <summary>
    /// Device information for the token
    /// </summary>
    public string? DeviceInfo { get; set; }

    /// <summary>
    /// IP address from which the token was created
    /// </summary>
    public string? IpAddress { get; set; }

    /// <summary>
    /// Check if the token is active
    /// </summary>
    public bool IsActive => !IsRevoked && DateTime.UtcNow < ExpiresAt;
}