using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.Plan;

/// <summary>
/// DTO for purchasing a plan
/// </summary>
public class PurchasePlanDto
{
    /// <summary>
    /// ID of the plan to purchase
    /// </summary>
    [Required]
    public Guid PlanId { get; set; }

    /// <summary>
    /// Payment method used (optional)
    /// </summary>
    public string? PaymentMethod { get; set; }

    /// <summary>
    /// Payment transaction ID from payment provider (optional)
    /// </summary>
    public string? PaymentTransactionId { get; set; }

    /// <summary>
    /// Optional notes about the purchase
    /// </summary>
    public string? Notes { get; set; }
}