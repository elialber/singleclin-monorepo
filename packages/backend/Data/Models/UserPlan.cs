using SingleClin.API.Data.Models.Enums;

namespace SingleClin.API.Data.Models;

/// <summary>
/// Represents a plan purchased by a user
/// </summary>
public class UserPlan : BaseEntity
{
    /// <summary>
    /// User who purchased the plan
    /// </summary>
    public Guid UserId { get; set; }
    
    /// <summary>
    /// Navigation property to User
    /// </summary>
    public User User { get; set; } = null!;
    
    /// <summary>
    /// Plan that was purchased
    /// </summary>
    public Guid PlanId { get; set; }
    
    /// <summary>
    /// Navigation property to Plan
    /// </summary>
    public Plan Plan { get; set; } = null!;
    
    /// <summary>
    /// Number of credits purchased
    /// </summary>
    public int Credits { get; set; }
    
    /// <summary>
    /// Number of credits remaining
    /// </summary>
    public int CreditsRemaining { get; set; }
    
    /// <summary>
    /// Amount paid for the plan
    /// </summary>
    public decimal AmountPaid { get; set; }
    
    /// <summary>
    /// Date when the plan expires
    /// </summary>
    public DateTime ExpirationDate { get; set; }
    
    /// <summary>
    /// Indicates if the plan is currently active
    /// </summary>
    public bool IsActive { get; set; } = true;
    
    /// <summary>
    /// Payment method used
    /// </summary>
    public string? PaymentMethod { get; set; }
    
    /// <summary>
    /// Payment transaction ID from payment provider
    /// </summary>
    public string? PaymentTransactionId { get; set; }
    
    /// <summary>
    /// Notes about the purchase
    /// </summary>
    public string? Notes { get; set; }
    
    /// <summary>
    /// Transactions made using this plan
    /// </summary>
    public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();

    /// <summary>
    /// Gets the number of credits used
    /// </summary>
    public int CreditsUsed => Credits - CreditsRemaining;

    /// <summary>
    /// Gets the expiration date (alias for ExpirationDate)
    /// </summary>
    public DateTime ExpiresAt => ExpirationDate;

    /// <summary>
    /// Checks if the plan is expired
    /// </summary>
    public bool IsExpired => DateTime.UtcNow > ExpirationDate;
}