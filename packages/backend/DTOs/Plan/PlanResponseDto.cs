namespace SingleClin.API.DTOs.Plan;

/// <summary>
/// Data transfer object for plan response
/// </summary>
public class PlanResponseDto
{
    /// <summary>
    /// Plan unique identifier
    /// </summary>
    public Guid Id { get; set; }

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
    public int ValidityDays { get; set; }

    /// <summary>
    /// Whether the plan is active
    /// </summary>
    public bool IsActive { get; set; }

    /// <summary>
    /// Display order for sorting
    /// </summary>
    public int DisplayOrder { get; set; }

    /// <summary>
    /// Whether this is a featured plan
    /// </summary>
    public bool IsFeatured { get; set; }

    /// <summary>
    /// When the plan was created
    /// </summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// When the plan was last updated
    /// </summary>
    public DateTime UpdatedAt { get; set; }

    /// <summary>
    /// Calculated discount percentage (if OriginalPrice is set)
    /// </summary>
    public decimal? DiscountPercentage => OriginalPrice.HasValue && OriginalPrice > Price && OriginalPrice > 0
        ? Math.Round(((OriginalPrice.Value - Price) / OriginalPrice.Value) * 100, 2)
        : null;

    /// <summary>
    /// Calculated price per credit
    /// </summary>
    public decimal PricePerCredit => Credits > 0 ? Math.Round(Price / Credits, 2) : 0;
}