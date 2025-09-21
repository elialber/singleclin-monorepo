namespace SingleClin.API.Data.Models.Enums;

/// <summary>
/// Represents the status of an appointment
/// </summary>
public enum AppointmentStatus
{
    /// <summary>
    /// Appointment has been scheduled but not confirmed
    /// </summary>
    Scheduled = 0,

    /// <summary>
    /// Appointment has been confirmed and credits debited
    /// </summary>
    Confirmed = 1,

    /// <summary>
    /// Appointment has been completed
    /// </summary>
    Completed = 2,

    /// <summary>
    /// Appointment has been cancelled
    /// </summary>
    Cancelled = 3
}