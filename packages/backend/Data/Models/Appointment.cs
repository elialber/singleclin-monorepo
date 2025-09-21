using System.ComponentModel.DataAnnotations;
using SingleClin.API.Data.Models.Enums;

namespace SingleClin.API.Data.Models;

/// <summary>
/// Represents an appointment between a user and a service at a clinic
/// </summary>
public class Appointment : BaseEntity
{
    /// <summary>
    /// User who made the appointment
    /// </summary>
    [Required]
    public Guid UserId { get; set; }

    /// <summary>
    /// Service being booked
    /// </summary>
    [Required]
    public Guid ServiceId { get; set; }

    /// <summary>
    /// Clinic where the service will be provided
    /// </summary>
    [Required]
    public Guid ClinicId { get; set; }

    /// <summary>
    /// Scheduled date and time for the appointment
    /// </summary>
    [Required]
    public DateTime ScheduledDate { get; set; }

    /// <summary>
    /// Current status of the appointment
    /// </summary>
    [Required]
    public AppointmentStatus Status { get; set; } = AppointmentStatus.Scheduled;

    /// <summary>
    /// Associated transaction ID when credits are debited
    /// </summary>
    public Guid? TransactionId { get; set; }

    /// <summary>
    /// Total credits required for this appointment
    /// </summary>
    [Required]
    [Range(1, int.MaxValue, ErrorMessage = "Total credits must be greater than 0")]
    public int TotalCredits { get; set; }

    /// <summary>
    /// Unique token for appointment confirmation
    /// </summary>
    public string? ConfirmationToken { get; set; }

    // Navigation properties
    /// <summary>
    /// Navigation property to the user
    /// </summary>
    public User User { get; set; } = null!;

    /// <summary>
    /// Navigation property to the service
    /// </summary>
    public Service Service { get; set; } = null!;

    /// <summary>
    /// Navigation property to the clinic
    /// </summary>
    public Clinic Clinic { get; set; } = null!;

    /// <summary>
    /// Navigation property to the transaction
    /// </summary>
    public Transaction? Transaction { get; set; }
}