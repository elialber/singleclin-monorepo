using SingleClin.API.DTOs.Clinic;

namespace SingleClin.API.DTOs.Appointment;

/// <summary>
/// Data transfer object for service information in appointment context
/// </summary>
public class ServiceDto
{
    /// <summary>
    /// Service unique identifier
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// Service name
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Service description
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// Cost in credits for this service
    /// </summary>
    public int CreditCost { get; set; }

    /// <summary>
    /// Service duration in minutes
    /// </summary>
    public int Duration { get; set; }

    /// <summary>
    /// Service category
    /// </summary>
    public string Category { get; set; } = string.Empty;

    /// <summary>
    /// Service image URL
    /// </summary>
    public string? ImageUrl { get; set; }

    /// <summary>
    /// Clinic information
    /// </summary>
    public ClinicResponseDto Clinic { get; set; } = null!;
}