using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Data.Models;
using SingleClin.API.Data.Models.Enums;
using SingleClin.API.DTOs.Appointment;
using SingleClin.API.DTOs.Clinic;
using System.Security.Cryptography;
using System.Text;

namespace SingleClin.API.Services;

/// <summary>
/// Service for managing appointments and credit debit operations
/// </summary>
public class AppointmentService : IAppointmentService
{
    private readonly AppDbContext _context;
    private readonly ICreditValidationService _creditValidationService;
    private readonly ILogger<AppointmentService> _logger;

    public AppointmentService(
        AppDbContext context,
        ICreditValidationService creditValidationService,
        ILogger<AppointmentService> logger)
    {
        _context = context;
        _creditValidationService = creditValidationService;
        _logger = logger;
    }

    public async Task<(bool Success, AppointmentSummaryDto? AppointmentSummary, IEnumerable<string> Errors)> ScheduleAppointmentAsync(Guid userId, AppointmentScheduleDto scheduleDto)
    {
        try
        {
            _logger.LogInformation("Scheduling appointment for user {UserId} with service {ServiceId} at clinic {ClinicId}",
                userId, scheduleDto.ServiceId, scheduleDto.ClinicId);

            // Find user in AppDbContext
            var user = await _context.Users.FirstOrDefaultAsync(u => u.ApplicationUserId == userId);
            if (user == null)
            {
                return (false, null, new[] { "User not found" });
            }

            // Validate service exists and is active
            var service = await _context.Services
                .Include(s => s.Clinic)
                .FirstOrDefaultAsync(s => s.Id == scheduleDto.ServiceId && s.IsActive);

            if (service == null)
            {
                return (false, null, new[] { "Service not found or inactive" });
            }

            // Validate clinic exists and is active
            var clinic = await _context.Clinics.FirstOrDefaultAsync(c => c.Id == scheduleDto.ClinicId && c.IsActive);
            if (clinic == null)
            {
                return (false, null, new[] { "Clinic not found or inactive" });
            }

            // Validate service belongs to clinic or is available at clinic
            if (service.ClinicId != scheduleDto.ClinicId)
            {
                return (false, null, new[] { "Service is not available at the selected clinic" });
            }

            // Validate scheduled date is in the future
            if (scheduleDto.ScheduledDate <= DateTime.UtcNow)
            {
                return (false, null, new[] { "Scheduled date must be in the future" });
            }

            // Validate user has sufficient credits
            var creditValidation = await _creditValidationService.ValidateUserCreditsAsync(userId, service.CreditCost);
            if (!creditValidation.HasSufficientCredits)
            {
                return (false, null, creditValidation.Errors);
            }

            // Generate confirmation token
            var confirmationToken = GenerateConfirmationToken();

            // Create appointment
            var appointment = new Appointment
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                ServiceId = scheduleDto.ServiceId,
                ClinicId = scheduleDto.ClinicId,
                ScheduledDate = scheduleDto.ScheduledDate,
                Status = AppointmentStatus.Scheduled,
                TotalCredits = service.CreditCost,
                ConfirmationToken = confirmationToken,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Appointments.Add(appointment);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Appointment {AppointmentId} scheduled successfully for user {UserId}", appointment.Id, userId);

            // Create appointment summary
            var appointmentSummary = new AppointmentSummaryDto
            {
                Id = appointment.Id,
                Service = new ServiceDto
                {
                    Id = service.Id,
                    Name = service.Name,
                    Description = service.Description,
                    CreditCost = service.CreditCost,
                    Duration = service.Duration,
                    Category = service.Category,
                    ImageUrl = service.ImageUrl,
                    Clinic = new ClinicResponseDto
                    {
                        Id = clinic.Id,
                        Name = clinic.Name,
                        Address = clinic.Address,
                        PhoneNumber = clinic.PhoneNumber,
                        Email = clinic.Email,
                        IsActive = clinic.IsActive,
                        Type = clinic.Type,
                        CreatedAt = clinic.CreatedAt,
                        UpdatedAt = clinic.UpdatedAt
                    }
                },
                Clinic = new ClinicResponseDto
                {
                    Id = clinic.Id,
                    Name = clinic.Name,
                    Address = clinic.Address,
                    PhoneNumber = clinic.PhoneNumber,
                    Email = clinic.Email,
                    IsActive = clinic.IsActive,
                    Type = clinic.Type,
                    CreatedAt = clinic.CreatedAt,
                    UpdatedAt = clinic.UpdatedAt
                },
                ScheduledDate = appointment.ScheduledDate,
                TotalCredits = appointment.TotalCredits,
                ConfirmationToken = appointment.ConfirmationToken!,
                UserCurrentCredits = creditValidation.AvailableCredits,
                UserRemainingCredits = creditValidation.AvailableCredits - appointment.TotalCredits,
                Status = appointment.Status
            };

            return (true, appointmentSummary, Array.Empty<string>());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error scheduling appointment for user {UserId}", userId);
            return (false, null, new[] { "An error occurred while scheduling the appointment" });
        }
    }

    public async Task<(bool Success, AppointmentResponseDto? Appointment, IEnumerable<string> Errors)> ConfirmAppointmentAsync(Guid userId, AppointmentConfirmationDto confirmationDto)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            _logger.LogInformation("Confirming appointment for user {UserId} with token {Token}",
                userId, confirmationDto.ConfirmationToken);

            // Find user in AppDbContext
            var user = await _context.Users.FirstOrDefaultAsync(u => u.ApplicationUserId == userId);
            if (user == null)
            {
                return (false, null, new[] { "User not found" });
            }

            // Find appointment by confirmation token
            var appointment = await _context.Appointments
                .Include(a => a.Service)
                .ThenInclude(s => s.Clinic)
                .FirstOrDefaultAsync(a => a.ConfirmationToken == confirmationDto.ConfirmationToken &&
                                        a.UserId == user.Id &&
                                        a.Status == AppointmentStatus.Scheduled);

            if (appointment == null)
            {
                return (false, null, new[] { "Invalid confirmation token or appointment not found" });
            }

            // Validate appointment hasn't expired (example: 30 minutes to confirm)
            if (appointment.CreatedAt.AddMinutes(30) < DateTime.UtcNow)
            {
                return (false, null, new[] { "Confirmation token has expired" });
            }

            // Re-validate credits (in case user's plans changed)
            var creditValidation = await _creditValidationService.ValidateUserCreditsAsync(userId, appointment.TotalCredits);
            if (!creditValidation.HasSufficientCredits)
            {
                return (false, null, creditValidation.Errors);
            }

            // Debit credits from user plans (FIFO - first expiring first)
            var creditsToDebit = appointment.TotalCredits;
            var userPlans = await _context.UserPlans
                .Where(up => up.UserId == user.Id &&
                           up.IsActive &&
                           up.CreditsRemaining > 0 &&
                           up.ExpirationDate > DateTime.UtcNow)
                .OrderBy(up => up.ExpirationDate)
                .ToListAsync();

            Transaction? createdTransaction = null;
            foreach (var userPlan in userPlans)
            {
                if (creditsToDebit <= 0) break;

                var creditsFromThisPlan = Math.Min(creditsToDebit, userPlan.CreditsRemaining);

                // Create transaction record
                if (createdTransaction == null)
                {
                    createdTransaction = new Transaction
                    {
                        Id = Guid.NewGuid(),
                        Code = GenerateTransactionCode(),
                        UserPlanId = userPlan.Id,
                        ClinicId = appointment.ClinicId,
                        Status = TransactionStatus.Validated,
                        CreditsUsed = creditsFromThisPlan,
                        ServiceDescription = appointment.Service.Name,
                        ServiceType = appointment.Service.Category,
                        Amount = 0, // No monetary amount, just credits
                        CreatedAt = DateTime.UtcNow,
                        ValidationDate = DateTime.UtcNow,
                        ValidatedBy = "SYSTEM_APPOINTMENT",
                        ValidationNotes = $"Appointment confirmation - Service: {appointment.Service.Name}",
                        UpdatedAt = DateTime.UtcNow
                    };

                    _context.Transactions.Add(createdTransaction);
                }
                else
                {
                    // Update existing transaction with total credits
                    createdTransaction.CreditsUsed += creditsFromThisPlan;
                }

                // Debit credits from user plan
                userPlan.CreditsRemaining -= creditsFromThisPlan;
                userPlan.UpdatedAt = DateTime.UtcNow;
                creditsToDebit -= creditsFromThisPlan;

                _logger.LogInformation("Debited {Credits} credits from UserPlan {UserPlanId} for appointment {AppointmentId}",
                    creditsFromThisPlan, userPlan.Id, appointment.Id);
            }

            if (creditsToDebit > 0)
            {
                await transaction.RollbackAsync();
                return (false, null, new[] { "Insufficient credits available" });
            }

            // Update appointment status
            appointment.Status = AppointmentStatus.Confirmed;
            appointment.TransactionId = createdTransaction?.Id;
            appointment.ConfirmationToken = null; // Clear token after confirmation
            appointment.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            _logger.LogInformation("Appointment {AppointmentId} confirmed successfully for user {UserId}",
                appointment.Id, userId);

            // Create response
            var appointmentResponse = MapToAppointmentResponseDto(appointment);

            return (true, appointmentResponse, Array.Empty<string>());
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            _logger.LogError(ex, "Error confirming appointment for user {UserId}", userId);
            return (false, null, new[] { "An error occurred while confirming the appointment" });
        }
    }

    public async Task<AppointmentResponseDto?> GetAppointmentByIdAsync(Guid userId, Guid appointmentId)
    {
        try
        {
            _logger.LogInformation("Getting appointment {AppointmentId} for user {UserId}", appointmentId, userId);

            var user = await _context.Users.FirstOrDefaultAsync(u => u.ApplicationUserId == userId);
            if (user == null)
            {
                return null;
            }

            var appointment = await _context.Appointments
                .Include(a => a.Service)
                .ThenInclude(s => s.Clinic)
                .FirstOrDefaultAsync(a => a.Id == appointmentId && a.UserId == user.Id);

            return appointment == null ? null : MapToAppointmentResponseDto(appointment);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting appointment {AppointmentId} for user {UserId}", appointmentId, userId);
            return null;
        }
    }

    public async Task<IEnumerable<AppointmentResponseDto>> GetUserAppointmentsAsync(Guid userId, bool includeCompleted = false)
    {
        try
        {
            _logger.LogInformation("Getting appointments for user {UserId}, includeCompleted: {IncludeCompleted}",
                userId, includeCompleted);

            var user = await _context.Users.FirstOrDefaultAsync(u => u.ApplicationUserId == userId);
            if (user == null)
            {
                return Array.Empty<AppointmentResponseDto>();
            }

            var query = _context.Appointments
                .Include(a => a.Service)
                .ThenInclude(s => s.Clinic)
                .Where(a => a.UserId == user.Id);

            if (!includeCompleted)
            {
                query = query.Where(a => a.Status != AppointmentStatus.Completed &&
                                       a.Status != AppointmentStatus.Cancelled);
            }

            var appointments = await query
                .OrderByDescending(a => a.ScheduledDate)
                .ToListAsync();

            return appointments.Select(MapToAppointmentResponseDto);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting appointments for user {UserId}", userId);
            return Array.Empty<AppointmentResponseDto>();
        }
    }

    public async Task<(bool Success, AppointmentResponseDto? Appointment, IEnumerable<string> Errors)> CancelAppointmentAsync(Guid userId, Guid appointmentId, string? reason = null)
    {
        try
        {
            _logger.LogInformation("Cancelling appointment {AppointmentId} for user {UserId}", appointmentId, userId);

            var user = await _context.Users.FirstOrDefaultAsync(u => u.ApplicationUserId == userId);
            if (user == null)
            {
                return (false, null, new[] { "User not found" });
            }

            var appointment = await _context.Appointments
                .Include(a => a.Service)
                .ThenInclude(s => s.Clinic)
                .FirstOrDefaultAsync(a => a.Id == appointmentId && a.UserId == user.Id);

            if (appointment == null)
            {
                return (false, null, new[] { "Appointment not found" });
            }

            if (appointment.Status == AppointmentStatus.Cancelled)
            {
                return (false, null, new[] { "Appointment is already cancelled" });
            }

            if (appointment.Status == AppointmentStatus.Completed)
            {
                return (false, null, new[] { "Cannot cancel a completed appointment" });
            }

            // Update appointment status
            appointment.Status = AppointmentStatus.Cancelled;
            appointment.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            _logger.LogInformation("Appointment {AppointmentId} cancelled successfully", appointmentId);

            return (true, MapToAppointmentResponseDto(appointment), Array.Empty<string>());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error cancelling appointment {AppointmentId}", appointmentId);
            return (false, null, new[] { "An error occurred while cancelling the appointment" });
        }
    }

    public async Task<(bool Success, AppointmentResponseDto? Appointment, IEnumerable<string> Errors)> CompleteAppointmentAsync(Guid appointmentId, Guid clinicId)
    {
        try
        {
            _logger.LogInformation("Completing appointment {AppointmentId} at clinic {ClinicId}", appointmentId, clinicId);

            var appointment = await _context.Appointments
                .Include(a => a.Service)
                .ThenInclude(s => s.Clinic)
                .FirstOrDefaultAsync(a => a.Id == appointmentId && a.ClinicId == clinicId);

            if (appointment == null)
            {
                return (false, null, new[] { "Appointment not found for this clinic" });
            }

            if (appointment.Status != AppointmentStatus.Confirmed)
            {
                return (false, null, new[] { "Only confirmed appointments can be completed" });
            }

            // Update appointment status
            appointment.Status = AppointmentStatus.Completed;
            appointment.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            _logger.LogInformation("Appointment {AppointmentId} completed successfully", appointmentId);

            return (true, MapToAppointmentResponseDto(appointment), Array.Empty<string>());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error completing appointment {AppointmentId}", appointmentId);
            return (false, null, new[] { "An error occurred while completing the appointment" });
        }
    }

    public async Task<AppointmentSummaryDto?> GetAppointmentByTokenAsync(string confirmationToken)
    {
        try
        {
            _logger.LogInformation("Getting appointment by token");

            var appointment = await _context.Appointments
                .Include(a => a.Service)
                .ThenInclude(s => s.Clinic)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.ConfirmationToken == confirmationToken &&
                                        a.Status == AppointmentStatus.Scheduled);

            if (appointment == null)
            {
                return null;
            }

            // Get user's current credits
            var userCredits = await _creditValidationService.GetAvailableCreditsAsync(appointment.User.ApplicationUserId);

            return new AppointmentSummaryDto
            {
                Id = appointment.Id,
                Service = new ServiceDto
                {
                    Id = appointment.Service.Id,
                    Name = appointment.Service.Name,
                    Description = appointment.Service.Description,
                    CreditCost = appointment.Service.CreditCost,
                    Duration = appointment.Service.Duration,
                    Category = appointment.Service.Category,
                    ImageUrl = appointment.Service.ImageUrl,
                    Clinic = new ClinicResponseDto
                    {
                        Id = appointment.Service.Clinic.Id,
                        Name = appointment.Service.Clinic.Name,
                        Address = appointment.Service.Clinic.Address,
                        PhoneNumber = appointment.Service.Clinic.PhoneNumber,
                        Email = appointment.Service.Clinic.Email,
                        IsActive = appointment.Service.Clinic.IsActive,
                        Type = appointment.Service.Clinic.Type,
                        CreatedAt = appointment.Service.Clinic.CreatedAt,
                        UpdatedAt = appointment.Service.Clinic.UpdatedAt
                    }
                },
                Clinic = new ClinicResponseDto
                {
                    Id = appointment.Service.Clinic.Id,
                    Name = appointment.Service.Clinic.Name,
                    Address = appointment.Service.Clinic.Address,
                    PhoneNumber = appointment.Service.Clinic.PhoneNumber,
                    Email = appointment.Service.Clinic.Email,
                    IsActive = appointment.Service.Clinic.IsActive,
                    Type = appointment.Service.Clinic.Type,
                    CreatedAt = appointment.Service.Clinic.CreatedAt,
                    UpdatedAt = appointment.Service.Clinic.UpdatedAt
                },
                ScheduledDate = appointment.ScheduledDate,
                TotalCredits = appointment.TotalCredits,
                ConfirmationToken = appointment.ConfirmationToken!,
                UserCurrentCredits = userCredits,
                UserRemainingCredits = userCredits - appointment.TotalCredits,
                Status = appointment.Status
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting appointment by token");
            return null;
        }
    }

    private AppointmentResponseDto MapToAppointmentResponseDto(Appointment appointment)
    {
        return new AppointmentResponseDto
        {
            Id = appointment.Id,
            UserId = appointment.User?.ApplicationUserId ?? Guid.Empty,
            Service = new ServiceDto
            {
                Id = appointment.Service.Id,
                Name = appointment.Service.Name,
                Description = appointment.Service.Description,
                CreditCost = appointment.Service.CreditCost,
                Duration = appointment.Service.Duration,
                Category = appointment.Service.Category,
                ImageUrl = appointment.Service.ImageUrl,
                Clinic = new ClinicResponseDto
                {
                    Id = appointment.Service.Clinic.Id,
                    Name = appointment.Service.Clinic.Name,
                    Address = appointment.Service.Clinic.Address,
                    PhoneNumber = appointment.Service.Clinic.PhoneNumber,
                    Email = appointment.Service.Clinic.Email,
                    IsActive = appointment.Service.Clinic.IsActive,
                    Type = appointment.Service.Clinic.Type,
                    CreatedAt = appointment.Service.Clinic.CreatedAt,
                    UpdatedAt = appointment.Service.Clinic.UpdatedAt
                }
            },
            ScheduledDate = appointment.ScheduledDate,
            Status = appointment.Status,
            TotalCredits = appointment.TotalCredits,
            TransactionId = appointment.TransactionId,
            ConfirmationToken = appointment.ConfirmationToken,
            CreatedAt = appointment.CreatedAt,
            UpdatedAt = appointment.UpdatedAt
        };
    }

    private string GenerateConfirmationToken()
    {
        using var rng = RandomNumberGenerator.Create();
        var bytes = new byte[32];
        rng.GetBytes(bytes);
        return Convert.ToBase64String(bytes).Replace("+", "-").Replace("/", "_").Replace("=", "");
    }

    private string GenerateTransactionCode()
    {
        var timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        var randomBytes = new byte[4];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomBytes);
        var randomNumber = BitConverter.ToUInt32(randomBytes, 0) % 10000;
        return $"APT{timestamp}{randomNumber:D4}";
    }
}