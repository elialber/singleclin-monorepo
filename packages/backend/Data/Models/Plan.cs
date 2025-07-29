namespace SingleClin.API.Data.Models;

/// <summary>
/// Represents a plan that users can purchase
/// </summary>
public class Plan : BaseEntity
{
    /// <summary>
    /// Plan name
    /// </summary>
    public string Name { get; set; } = string.Empty;
    
    /// <summary>
    /// Plan description
    /// </summary>
    public string? Description { get; set; }
    
    /// <summary>
    /// Number of credits included in the plan
    /// </summary>
    public int Credits { get; set; }
    
    /// <summary>
    /// Plan price
    /// </summary>
    public decimal Price { get; set; }
    
    /// <summary>
    /// Original price (for showing discounts)
    /// </summary>
    public decimal? OriginalPrice { get; set; }
    
    /// <summary>
    /// Validity period in days
    /// </summary>
    public int ValidityDays { get; set; } = 365;
    
    /// <summary>
    /// Indicates if the plan is active for purchase
    /// </summary>
    public bool IsActive { get; set; } = true;
    
    /// <summary>
    /// Display order
    /// </summary>
    public int DisplayOrder { get; set; } = 0;
    
    /// <summary>
    /// Indicates if this is a featured plan
    /// </summary>
    public bool IsFeatured { get; set; } = false;
    
    /// <summary>
    /// User plans purchased from this plan
    /// </summary>
    public ICollection<UserPlan> UserPlans { get; set; } = new List<UserPlan>();
}