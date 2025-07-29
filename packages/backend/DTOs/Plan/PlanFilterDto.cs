using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.Plan;

/// <summary>
/// Data transfer object for filtering plans
/// </summary>
public class PlanFilterDto
{
    /// <summary>
    /// Page number (1-based)
    /// </summary>
    [Range(1, int.MaxValue, ErrorMessage = "Page number must be greater than 0")]
    public int PageNumber { get; set; } = 1;

    /// <summary>
    /// Number of items per page
    /// </summary>
    [Range(1, 100, ErrorMessage = "Page size must be between 1 and 100")]
    public int PageSize { get; set; } = 10;

    /// <summary>
    /// Filter by active status
    /// </summary>
    public bool? IsActive { get; set; }

    /// <summary>
    /// Filter by featured status
    /// </summary>
    public bool? IsFeatured { get; set; }

    /// <summary>
    /// Search term for name or description
    /// </summary>
    [StringLength(100, ErrorMessage = "Search term cannot exceed 100 characters")]
    public string? SearchTerm { get; set; }

    /// <summary>
    /// Minimum price filter
    /// </summary>
    [Range(0, double.MaxValue, ErrorMessage = "Minimum price must be greater than or equal to 0")]
    public decimal? MinPrice { get; set; }

    /// <summary>
    /// Maximum price filter
    /// </summary>
    [Range(0, double.MaxValue, ErrorMessage = "Maximum price must be greater than or equal to 0")]
    public decimal? MaxPrice { get; set; }

    /// <summary>
    /// Minimum credits filter
    /// </summary>
    [Range(1, int.MaxValue, ErrorMessage = "Minimum credits must be greater than 0")]
    public int? MinCredits { get; set; }

    /// <summary>
    /// Maximum credits filter
    /// </summary>
    [Range(1, int.MaxValue, ErrorMessage = "Maximum credits must be greater than 0")]
    public int? MaxCredits { get; set; }

    /// <summary>
    /// Sort field
    /// </summary>
    public string SortBy { get; set; } = "DisplayOrder";

    /// <summary>
    /// Sort direction (asc or desc)
    /// </summary>
    public string SortDirection { get; set; } = "asc";
}