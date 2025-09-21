using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.Appointment;

/// <summary>
/// Data transfer object for scheduling an appointment
/// </summary>
public class AppointmentScheduleDto
{
    /// <summary>
    /// Service ID for the appointment
    /// </summary>
    [Required(ErrorMessage = "Service ID is required")]
    public Guid ServiceId { get; set; }

    /// <summary>
    /// Clinic ID where the service will be provided
    /// </summary>
    [Required(ErrorMessage = "Clinic ID is required")]
    public Guid ClinicId { get; set; }

    /// <summary>
    /// Scheduled date and time for the appointment
    /// </summary>
    [Required(ErrorMessage = "Scheduled date is required")]
    public DateTime ScheduledDate { get; set; }
}