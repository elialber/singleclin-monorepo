using SingleClin.API.Data.Models.Enums;

namespace SingleClin.API.DTOs.Appointment;

/// <summary>
/// Data transfer object for appointment response
/// </summary>
public class AppointmentResponseDto
{
    /// <summary>
    /// Appointment unique identifier
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// User ID who made the appointment
    /// </summary>
    public Guid UserId { get; set; }

    /// <summary>
    /// Service details
    /// </summary>
    public ServiceDto Service { get; set; } = null!;

    /// <summary>
    /// Scheduled date and time
    /// </summary>
    public DateTime ScheduledDate { get; set; }

    /// <summary>
    /// Appointment status
    /// </summary>
    public AppointmentStatus Status { get; set; }

    /// <summary>
    /// Total credits for this appointment
    /// </summary>
    public int TotalCredits { get; set; }

    /// <summary>
    /// Transaction ID if appointment is confirmed
    /// </summary>
    public Guid? TransactionId { get; set; }

    /// <summary>
    /// Confirmation token (only for scheduled appointments)
    /// </summary>
    public string? ConfirmationToken { get; set; }

    /// <summary>
    /// Appointment creation date
    /// </summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// Last update date
    /// </summary>
    public DateTime UpdatedAt { get; set; }
}