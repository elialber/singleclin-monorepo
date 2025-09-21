using SingleClin.API.Data.Models;
using SingleClin.API.Data.Models.Enums;
using SingleClin.API.DTOs.Clinic;

namespace SingleClin.API.DTOs.Appointment;

/// <summary>
/// Data transfer object for appointment summary (used in confirmation screen)
/// </summary>
public class AppointmentSummaryDto
{
    /// <summary>
    /// Appointment unique identifier
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// Service details
    /// </summary>
    public ServiceDto Service { get; set; } = null!;

    /// <summary>
    /// Clinic details
    /// </summary>
    public ClinicResponseDto Clinic { get; set; } = null!;

    /// <summary>
    /// Scheduled date and time
    /// </summary>
    public DateTime ScheduledDate { get; set; }

    /// <summary>
    /// Total credits required for this appointment
    /// </summary>
    public int TotalCredits { get; set; }

    /// <summary>
    /// Confirmation token for this appointment
    /// </summary>
    public string ConfirmationToken { get; set; } = string.Empty;

    /// <summary>
    /// User's current available credits
    /// </summary>
    public int UserCurrentCredits { get; set; }

    /// <summary>
    /// User's remaining credits after this appointment
    /// </summary>
    public int UserRemainingCredits { get; set; }

    /// <summary>
    /// Current appointment status
    /// </summary>
    public AppointmentStatus Status { get; set; }
}