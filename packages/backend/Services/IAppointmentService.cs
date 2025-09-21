using SingleClin.API.DTOs.Appointment;

namespace SingleClin.API.Services;

/// <summary>
/// Interface for appointment service
/// </summary>
public interface IAppointmentService
{
    /// <summary>
    /// Schedule a new appointment
    /// </summary>
    /// <param name="userId">User ID</param>
    /// <param name="scheduleDto">Appointment schedule data</param>
    /// <returns>Appointment summary with confirmation details</returns>
    Task<(bool Success, AppointmentSummaryDto? AppointmentSummary, IEnumerable<string> Errors)> ScheduleAppointmentAsync(Guid userId, AppointmentScheduleDto scheduleDto);

    /// <summary>
    /// Confirm a scheduled appointment and debit credits
    /// </summary>
    /// <param name="userId">User ID</param>
    /// <param name="confirmationDto">Confirmation data</param>
    /// <returns>Confirmed appointment details</returns>
    Task<(bool Success, AppointmentResponseDto? Appointment, IEnumerable<string> Errors)> ConfirmAppointmentAsync(Guid userId, AppointmentConfirmationDto confirmationDto);

    /// <summary>
    /// Get appointment by ID
    /// </summary>
    /// <param name="userId">User ID</param>
    /// <param name="appointmentId">Appointment ID</param>
    /// <returns>Appointment details</returns>
    Task<AppointmentResponseDto?> GetAppointmentByIdAsync(Guid userId, Guid appointmentId);

    /// <summary>
    /// Get user's appointments
    /// </summary>
    /// <param name="userId">User ID</param>
    /// <param name="includeCompleted">Include completed appointments</param>
    /// <returns>List of appointments</returns>
    Task<IEnumerable<AppointmentResponseDto>> GetUserAppointmentsAsync(Guid userId, bool includeCompleted = false);

    /// <summary>
    /// Cancel an appointment
    /// </summary>
    /// <param name="userId">User ID</param>
    /// <param name="appointmentId">Appointment ID</param>
    /// <param name="reason">Cancellation reason</param>
    /// <returns>Success status and updated appointment</returns>
    Task<(bool Success, AppointmentResponseDto? Appointment, IEnumerable<string> Errors)> CancelAppointmentAsync(Guid userId, Guid appointmentId, string? reason = null);

    /// <summary>
    /// Complete an appointment (for clinic use)
    /// </summary>
    /// <param name="appointmentId">Appointment ID</param>
    /// <param name="clinicId">Clinic ID</param>
    /// <returns>Success status and updated appointment</returns>
    Task<(bool Success, AppointmentResponseDto? Appointment, IEnumerable<string> Errors)> CompleteAppointmentAsync(Guid appointmentId, Guid clinicId);

    /// <summary>
    /// Get appointments by confirmation token
    /// </summary>
    /// <param name="confirmationToken">Confirmation token</param>
    /// <returns>Appointment summary</returns>
    Task<AppointmentSummaryDto?> GetAppointmentByTokenAsync(string confirmationToken);
}