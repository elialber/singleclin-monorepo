using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.Appointment;

/// <summary>
/// Data transfer object for confirming an appointment
/// </summary>
public class AppointmentConfirmationDto
{
    /// <summary>
    /// Unique confirmation token for the appointment
    /// </summary>
    [Required(ErrorMessage = "Confirmation token is required")]
    [StringLength(255, ErrorMessage = "Confirmation token cannot exceed 255 characters")]
    public string ConfirmationToken { get; set; } = string.Empty;
}