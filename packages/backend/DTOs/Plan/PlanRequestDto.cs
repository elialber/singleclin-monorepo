using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.Plan;

/// <summary>
/// Data transfer object for creating or updating a plan
/// </summary>
public class PlanRequestDto
{
    /// <summary>
    /// Plan name
    /// </summary>
    [Required(ErrorMessage = "Plan name is required")]
    [StringLength(255, ErrorMessage = "Plan name cannot exceed 255 characters")]
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Plan description
    /// </summary>
    [StringLength(1000, ErrorMessage = "Description cannot exceed 1000 characters")]
    public string? Description { get; set; }

    /// <summary>
    /// Number of credits included in the plan
    /// </summary>
    [Required(ErrorMessage = "Credits is required")]
    [Range(1, int.MaxValue, ErrorMessage = "Credits must be greater than 0")]
    public int Credits { get; set; }

    /// <summary>
    /// Plan price
    /// </summary>
    [Required(ErrorMessage = "Price is required")]
    [RegularExpression(@"^\d+(\.\d{1,2})?$", ErrorMessage = "Price must be a valid decimal with up to 2 decimal places")]
    [Range(0, double.MaxValue, ErrorMessage = "Price must be greater than or equal to 0")]
    public decimal Price { get; set; }

    /// <summary>
    /// Original price (for discounts)
    /// </summary>
    [RegularExpression(@"^\d+(\.\d{1,2})?$", ErrorMessage = "Original price must be a valid decimal with up to 2 decimal places")]
    [Range(0, double.MaxValue, ErrorMessage = "Original price must be greater than or equal to 0")]
    public decimal? OriginalPrice { get; set; }

    /// <summary>
    /// Validity period in days
    /// </summary>
    [Range(1, 3650, ErrorMessage = "Validity days must be between 1 and 3650 (10 years)")]
    public int ValidityDays { get; set; } = 365;

    /// <summary>
    /// Whether the plan is active
    /// </summary>
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// Display order for sorting (optional - will be auto-calculated if not provided)
    /// </summary>
    [Range(0, int.MaxValue, ErrorMessage = "Display order must be greater than or equal to 0")]
    public int? DisplayOrder { get; set; }

    /// <summary>
    /// Whether this is a featured plan
    /// </summary>
    public bool IsFeatured { get; set; } = false;
}