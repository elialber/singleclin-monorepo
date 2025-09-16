namespace SingleClin.API.Data.Models;

/// <summary>
/// Represents a service offered by a clinic
/// </summary>
public class Service : BaseEntity
{
    /// <summary>
    /// Service name
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Service description
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// Service price
    /// </summary>
    public decimal Price { get; set; }

    /// <summary>
    /// Service duration in minutes
    /// </summary>
    public int Duration { get; set; }

    /// <summary>
    /// Service category
    /// </summary>
    public string Category { get; set; } = string.Empty;

    /// <summary>
    /// Indicates if the service is available
    /// </summary>
    public bool IsAvailable { get; set; } = true;

    /// <summary>
    /// Service image URL
    /// </summary>
    public string? ImageUrl { get; set; }

    /// <summary>
    /// Clinic ID that offers this service
    /// </summary>
    public Guid ClinicId { get; set; }

    /// <summary>
    /// Navigation property to the clinic
    /// </summary>
    public Clinic Clinic { get; set; } = null!;
}