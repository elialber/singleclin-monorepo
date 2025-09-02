namespace SingleClin.API.DTOs.Plan;

/// <summary>
/// DTO for user plan response
/// </summary>
public class UserPlanResponseDto
{
    /// <summary>
    /// User plan ID
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// User ID
    /// </summary>
    public Guid UserId { get; set; }

    /// <summary>
    /// Plan ID
    /// </summary>
    public Guid PlanId { get; set; }

    /// <summary>
    /// Plan information
    /// </summary>
    public PlanResponseDto Plan { get; set; } = null!;

    /// <summary>
    /// Total credits purchased
    /// </summary>
    public int Credits { get; set; }

    /// <summary>
    /// Credits remaining
    /// </summary>
    public int CreditsRemaining { get; set; }

    /// <summary>
    /// Credits used
    /// </summary>
    public int CreditsUsed => Credits - CreditsRemaining;

    /// <summary>
    /// Amount paid for the plan
    /// </summary>
    public decimal AmountPaid { get; set; }

    /// <summary>
    /// When the plan expires
    /// </summary>
    public DateTime ExpirationDate { get; set; }

    /// <summary>
    /// Whether the plan is active
    /// </summary>
    public bool IsActive { get; set; }

    /// <summary>
    /// Whether the plan is expired
    /// </summary>
    public bool IsExpired => DateTime.UtcNow > ExpirationDate;

    /// <summary>
    /// Payment method used
    /// </summary>
    public string? PaymentMethod { get; set; }

    /// <summary>
    /// Payment transaction ID
    /// </summary>
    public string? PaymentTransactionId { get; set; }

    /// <summary>
    /// Purchase notes
    /// </summary>
    public string? Notes { get; set; }

    /// <summary>
    /// When the plan was purchased
    /// </summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// Last update date
    /// </summary>
    public DateTime UpdatedAt { get; set; }
}