using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SingleClin.API.Services;
using SingleClin.API.DTOs.Appointment;
using Swashbuckle.AspNetCore.Annotations;
using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.Controllers;

/// <summary>
/// Controller for managing appointments
/// </summary>
[ApiController]
[Route("api/[controller]")]
[SwaggerTag("Appointment management endpoints")]
public class AppointmentsController : BaseController
{
    private readonly IAppointmentService _appointmentService;
    private readonly ICreditValidationService _creditValidationService;
    private readonly ITransactionService _transactionService;

    public AppointmentsController(
        IAppointmentService appointmentService,
        ICreditValidationService creditValidationService,
        ITransactionService transactionService)
    {
        _appointmentService = appointmentService;
        _creditValidationService = creditValidationService;
        _transactionService = transactionService;
    }

    /// <summary>
    /// Schedule a new appointment
    /// </summary>
    /// <param name="scheduleDto">Appointment scheduling data</param>
    /// <returns>Appointment summary with confirmation details</returns>
    /// <response code="201">Appointment scheduled successfully</response>
    /// <response code="400">Invalid appointment data or insufficient credits</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="404">Service or clinic not found</response>
    [HttpPost("schedule")]
    [SwaggerOperation(
        Summary = "Schedule appointment",
        Description = "Creates a new appointment reservation. The appointment must be confirmed within 30 minutes."
    )]
    [ProducesResponseType(typeof(AppointmentSummaryDto), 201)]
    [ProducesResponseType(400)]
    [ProducesResponseType(401)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> ScheduleAppointment([FromBody] AppointmentScheduleDto scheduleDto)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                return ValidationErrorResponse();
            }

            if (!Guid.TryParse(CurrentUserId, out var userId))
            {
                return UnauthorizedResponse("Invalid user ID");
            }

            Logger.LogInformation("User {UserId} scheduling appointment for service {ServiceId} at clinic {ClinicId}",
                userId, scheduleDto.ServiceId, scheduleDto.ClinicId);

            var result = await _appointmentService.ScheduleAppointmentAsync(userId, scheduleDto);

            if (!result.Success)
            {
                return BadRequestResponse("Failed to schedule appointment", result.Errors.ToList());
            }

            return CreatedResponse(result.AppointmentSummary, "Appointment scheduled successfully. Please confirm within 30 minutes.");
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error scheduling appointment for user {UserId}", CurrentUserId);
            return InternalServerErrorResponse();
        }
    }

    /// <summary>
    /// Confirm a scheduled appointment and debit credits
    /// </summary>
    /// <param name="confirmationDto">Appointment confirmation data</param>
    /// <returns>Confirmed appointment details</returns>
    /// <response code="200">Appointment confirmed successfully</response>
    /// <response code="400">Invalid confirmation token or insufficient credits</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="404">Appointment not found</response>
    [HttpPost("confirm")]
    [SwaggerOperation(
        Summary = "Confirm appointment",
        Description = "Confirms a scheduled appointment and debits the required credits from user's plans"
    )]
    [ProducesResponseType(typeof(AppointmentResponseDto), 200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(401)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> ConfirmAppointment([FromBody] AppointmentConfirmationDto confirmationDto)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                return ValidationErrorResponse();
            }

            if (!Guid.TryParse(CurrentUserId, out var userId))
            {
                return UnauthorizedResponse("Invalid user ID");
            }

            Logger.LogInformation("User {UserId} confirming appointment with token {Token}",
                userId, confirmationDto.ConfirmationToken);

            var result = await _appointmentService.ConfirmAppointmentAsync(userId, confirmationDto);

            if (!result.Success)
            {
                return BadRequestResponse("Failed to confirm appointment", result.Errors.ToList());
            }

            return OkResponse(result.Appointment, "Appointment confirmed successfully. Credits have been debited.");
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error confirming appointment for user {UserId}", CurrentUserId);
            return InternalServerErrorResponse();
        }
    }

    /// <summary>
    /// Get appointment details by ID
    /// </summary>
    /// <param name="appointmentId">Appointment ID</param>
    /// <returns>Appointment details</returns>
    /// <response code="200">Returns appointment details</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Access forbidden - not your appointment</response>
    /// <response code="404">Appointment not found</response>
    [HttpGet("{appointmentId:guid}")]
    [SwaggerOperation(
        Summary = "Get appointment by ID",
        Description = "Retrieves detailed information about a specific appointment"
    )]
    [ProducesResponseType(typeof(AppointmentResponseDto), 200)]
    [ProducesResponseType(401)]
    [ProducesResponseType(403)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> GetAppointmentById([Required] Guid appointmentId)
    {
        try
        {
            if (!Guid.TryParse(CurrentUserId, out var userId))
            {
                return UnauthorizedResponse("Invalid user ID");
            }

            Logger.LogInformation("User {UserId} getting appointment {AppointmentId}", userId, appointmentId);

            var appointment = await _appointmentService.GetAppointmentByIdAsync(userId, appointmentId);

            if (appointment == null)
            {
                return NotFoundResponse("Appointment not found");
            }

            return OkResponse(appointment, "Appointment retrieved successfully");
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error getting appointment {AppointmentId} for user {UserId}",
                appointmentId, CurrentUserId);
            return InternalServerErrorResponse();
        }
    }

    /// <summary>
    /// Get user's appointments
    /// </summary>
    /// <param name="includeCompleted">Include completed appointments (default: false)</param>
    /// <returns>List of user's appointments</returns>
    /// <response code="200">Returns list of appointments</response>
    /// <response code="401">Unauthorized</response>
    [HttpGet("my-appointments")]
    [SwaggerOperation(
        Summary = "Get my appointments",
        Description = "Retrieves all appointments for the current user"
    )]
    [ProducesResponseType(typeof(IEnumerable<AppointmentResponseDto>), 200)]
    [ProducesResponseType(401)]
    public async Task<IActionResult> GetMyAppointments([FromQuery] bool includeCompleted = false)
    {
        try
        {
            Logger.LogInformation("GetMyAppointments called - CurrentUserId: {CurrentUserId}", CurrentUserId);
            
            if (string.IsNullOrEmpty(CurrentUserId))
            {
                Logger.LogWarning("CurrentUserId is null or empty");
                return UnauthorizedResponse("User ID not found in token");
            }
            
            if (!Guid.TryParse(CurrentUserId, out var userId))
            {
                Logger.LogWarning("Failed to parse CurrentUserId '{CurrentUserId}' to Guid", CurrentUserId);
                return UnauthorizedResponse("Invalid user ID format");
            }

            Logger.LogInformation("User {UserId} getting appointments, includeCompleted: {IncludeCompleted}",
                userId, includeCompleted);

            var appointments = await _appointmentService.GetUserAppointmentsAsync(userId, includeCompleted);

            Logger.LogInformation("Retrieved {Count} appointments for user {UserId}", appointments.Count(), userId);
            return OkResponse(appointments, $"Retrieved {appointments.Count()} appointments");
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error getting appointments for user {UserId}", CurrentUserId);
            return InternalServerErrorResponse();
        }
    }

    /// <summary>
    /// Cancel an appointment
    /// </summary>
    /// <param name="appointmentId">Appointment ID</param>
    /// <param name="reason">Cancellation reason (optional)</param>
    /// <returns>Cancelled appointment details</returns>
    /// <response code="200">Appointment cancelled successfully</response>
    /// <response code="400">Cannot cancel appointment in current state</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Access forbidden - not your appointment</response>
    /// <response code="404">Appointment not found</response>
    [HttpPost("{appointmentId:guid}/cancel")]
    [SwaggerOperation(
        Summary = "Cancel appointment",
        Description = "Cancels an appointment. Credits are refunded if the appointment was confirmed."
    )]
    [ProducesResponseType(typeof(AppointmentResponseDto), 200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(401)]
    [ProducesResponseType(403)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> CancelAppointment(
        [Required] Guid appointmentId,
        [FromBody] string? reason = null)
    {
        try
        {
            if (!Guid.TryParse(CurrentUserId, out var userId))
            {
                return UnauthorizedResponse("Invalid user ID");
            }

            Logger.LogInformation("User {UserId} cancelling appointment {AppointmentId} with reason: {Reason}",
                userId, appointmentId, reason);

            var result = await _appointmentService.CancelAppointmentAsync(userId, appointmentId, reason);

            if (!result.Success)
            {
                return BadRequestResponse("Failed to cancel appointment", result.Errors.ToList());
            }

            // If appointment was confirmed, refund credits via transaction service
            if (result.Appointment?.TransactionId.HasValue == true)
            {
                var refundReason = $"Appointment cancellation: {reason ?? "No reason provided"}";
                var refundResult = await _transactionService.RefundAppointmentCreditsAsync(
                    result.Appointment.TransactionId.Value, refundReason);

                if (refundResult.Success)
                {
                    Logger.LogInformation("Credits refunded for cancelled appointment {AppointmentId}", appointmentId);
                }
                else
                {
                    Logger.LogWarning("Failed to refund credits for appointment {AppointmentId}: {Errors}",
                        appointmentId, string.Join(", ", refundResult.Errors));
                }
            }

            return OkResponse(result.Appointment, "Appointment cancelled successfully. Credits have been refunded if applicable.");
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error cancelling appointment {AppointmentId} for user {UserId}",
                appointmentId, CurrentUserId);
            return InternalServerErrorResponse();
        }
    }

    /// <summary>
    /// Get appointment summary by confirmation token (public endpoint)
    /// </summary>
    /// <param name="token">Confirmation token</param>
    /// <returns>Appointment summary for confirmation</returns>
    /// <response code="200">Returns appointment summary</response>
    /// <response code="400">Invalid token</response>
    /// <response code="404">Appointment not found or token expired</response>
    [HttpGet("confirmation/{token}")]
    [AllowAnonymous]
    [SwaggerOperation(
        Summary = "Get appointment by token",
        Description = "Retrieves appointment summary using confirmation token (public endpoint for confirmation page)"
    )]
    [ProducesResponseType(typeof(AppointmentSummaryDto), 200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> GetAppointmentByToken([Required] string token)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(token))
            {
                return BadRequestResponse("Confirmation token is required");
            }

            Logger.LogInformation("Getting appointment by token");

            var appointmentSummary = await _appointmentService.GetAppointmentByTokenAsync(token);

            if (appointmentSummary == null)
            {
                return NotFoundResponse("Appointment not found or confirmation token has expired");
            }

            return OkResponse(appointmentSummary, "Appointment summary retrieved successfully");
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error getting appointment by token");
            return InternalServerErrorResponse();
        }
    }

    /// <summary>
    /// Complete an appointment (for clinic use)
    /// </summary>
    /// <param name="appointmentId">Appointment ID</param>
    /// <returns>Completed appointment details</returns>
    /// <response code="200">Appointment completed successfully</response>
    /// <response code="400">Cannot complete appointment in current state</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Access forbidden - clinic access required</response>
    /// <response code="404">Appointment not found</response>
    [HttpPost("{appointmentId:guid}/complete")]
    [Authorize(Roles = "Clinic,ClinicOrigin,ClinicPartner,Admin")]
    [SwaggerOperation(
        Summary = "Complete appointment",
        Description = "Marks an appointment as completed (clinic staff only)"
    )]
    [ProducesResponseType(typeof(AppointmentResponseDto), 200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(401)]
    [ProducesResponseType(403)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> CompleteAppointment([Required] Guid appointmentId)
    {
        try
        {
            var clinicId = GetUserClinicId();
            if (!clinicId.HasValue)
            {
                return ForbiddenResponse("Clinic association required");
            }

            Logger.LogInformation("Clinic {ClinicId} completing appointment {AppointmentId}",
                clinicId.Value, appointmentId);

            var result = await _appointmentService.CompleteAppointmentAsync(appointmentId, clinicId.Value);

            if (!result.Success)
            {
                return BadRequestResponse("Failed to complete appointment", result.Errors.ToList());
            }

            return OkResponse(result.Appointment, "Appointment completed successfully");
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error completing appointment {AppointmentId}", appointmentId);
            return InternalServerErrorResponse();
        }
    }

    /// <summary>
    /// Get current user's available credits
    /// </summary>
    /// <returns>User's available credits information</returns>
    /// <response code="200">Returns user's credit information</response>
    /// <response code="401">Unauthorized</response>
    [HttpGet("my-credits")]
    [SwaggerOperation(
        Summary = "Get my credits",
        Description = "Retrieves current user's available credits and active plans"
    )]
    [ProducesResponseType(200)]
    [ProducesResponseType(401)]
    public async Task<IActionResult> GetMyCredits()
    {
        try
        {
            if (!Guid.TryParse(CurrentUserId, out var userId))
            {
                return UnauthorizedResponse("Invalid user ID");
            }

            Logger.LogInformation("User {UserId} getting credit information", userId);

            var availableCredits = await _creditValidationService.GetAvailableCreditsAsync(userId);
            var activePlans = await _creditValidationService.GetUserActivePlansAsync(userId);
            var hasActivePlans = await _creditValidationService.HasActivePlansAsync(userId);

            var creditInfo = new
            {
                TotalAvailableCredits = availableCredits,
                HasActivePlans = hasActivePlans,
                ActivePlans = activePlans.Select(plan => new
                {
                    plan.Id,
                    plan.Plan.Name,
                    plan.CreditsRemaining,
                    plan.ExpirationDate,
                    DaysUntilExpiration = (plan.ExpirationDate - DateTime.UtcNow).Days
                })
            };

            return OkResponse(creditInfo, "Credit information retrieved successfully");
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error getting credit information for user {UserId}", CurrentUserId);
            return InternalServerErrorResponse();
        }
    }
}