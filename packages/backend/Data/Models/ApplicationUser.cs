using Microsoft.AspNetCore.Identity;
using SingleClin.API.Data.Enums;

namespace SingleClin.API.Data.Models;

/// <summary>
/// Extended user class for ASP.NET Core Identity
/// </summary>
public class ApplicationUser : IdentityUser<Guid>
{
    /// <summary>
    /// User's role in the system
    /// </summary>
    public UserRole Role { get; set; } = UserRole.Patient;
    
    /// <summary>
    /// Associated clinic ID (for clinic users only)
    /// </summary>
    public Guid? ClinicId { get; set; }
    
    /// <summary>
    /// Navigation property to the associated clinic
    /// </summary>
    public virtual Clinic? Clinic { get; set; }
    
    /// <summary>
    /// User's full name
    /// </summary>
    public string FullName { get; set; } = string.Empty;
    
    /// <summary>
    /// Whether the user account is active
    /// </summary>
    public bool IsActive { get; set; } = true;
    
    /// <summary>
    /// Date when the user was created
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    /// <summary>
    /// Date when the user was last updated
    /// </summary>
    public DateTime? UpdatedAt { get; set; }
    
    /// <summary>
    /// Date when the user last logged in
    /// </summary>
    public DateTime? LastLoginAt { get; set; }
    
    /// <summary>
    /// Firebase UID for users authenticated via Firebase
    /// </summary>
    public string? FirebaseUid { get; set; }
    
    /// <summary>
    /// Refresh tokens for JWT authentication
    /// </summary>
    public virtual ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();
    
    /// <summary>
    /// User plans (for patients)
    /// </summary>
    public virtual ICollection<UserPlan> UserPlans { get; set; } = new List<UserPlan>();
}