using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.Clinic;

/// <summary>
/// Data transfer object for clinic service
/// </summary>
public class ClinicServiceDto
{
    /// <summary>
    /// Service unique identifier
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// Service name
    /// </summary>
    [Required(ErrorMessage = "Service name is required")]
    [StringLength(100, ErrorMessage = "Service name cannot exceed 100 characters")]
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Service description
    /// </summary>
    [StringLength(500, ErrorMessage = "Service description cannot exceed 500 characters")]
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// Service price
    /// </summary>
    [Required(ErrorMessage = "Service price is required")]
    [Range(0, double.MaxValue, ErrorMessage = "Service price must be non-negative")]
    public decimal Price { get; set; }

    /// <summary>
    /// Cost in credits for this service
    /// </summary>
    [Required(ErrorMessage = "Credit cost is required")]
    [Range(1, int.MaxValue, ErrorMessage = "Credit cost must be at least 1")]
    public int CreditCost { get; set; }

    /// <summary>
    /// Service duration in minutes
    /// </summary>
    [Required(ErrorMessage = "Service duration is required")]
    [Range(1, int.MaxValue, ErrorMessage = "Service duration must be at least 1 minute")]
    public int Duration { get; set; }

    /// <summary>
    /// Service category
    /// </summary>
    [Required(ErrorMessage = "Service category is required")]
    [StringLength(50, ErrorMessage = "Service category cannot exceed 50 characters")]
    public string Category { get; set; } = string.Empty;

    /// <summary>
    /// Indicates if the service is active
    /// </summary>
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// Service image URL
    /// </summary>
    [Url(ErrorMessage = "Service image URL must be a valid URL")]
    public string? ImageUrl { get; set; }
}