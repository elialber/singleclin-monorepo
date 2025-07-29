using SingleClin.API.Data.Models.Enums;

namespace SingleClin.API.Data.Models;

/// <summary>
/// Represents a user in the system
/// </summary>
public class User : BaseEntity
{
    /// <summary>
    /// User's email address (unique)
    /// </summary>
    public string Email { get; set; } = string.Empty;
    
    /// <summary>
    /// User's role in the system
    /// </summary>
    public UserRole Role { get; set; }
    
    /// <summary>
    /// User's display name
    /// </summary>
    public string? DisplayName { get; set; }
    
    /// <summary>
    /// User's phone number
    /// </summary>
    public string? PhoneNumber { get; set; }
    
    /// <summary>
    /// Firebase UID for authentication
    /// </summary>
    public string? FirebaseUid { get; set; }
    
    /// <summary>
    /// Indicates if the user account is active
    /// </summary>
    public bool IsActive { get; set; } = true;
    
    /// <summary>
    /// User's purchased plans
    /// </summary>
    public ICollection<UserPlan> UserPlans { get; set; } = new List<UserPlan>();
}