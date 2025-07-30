using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Data.Models;
using SingleClin.API.Data.Models.Enums;
using SingleClin.API.DTOs.QRCode;
using SingleClin.API.Exceptions;

namespace SingleClin.API.Services;

/// <summary>
/// Service for validating QR Code tokens and processing transactions
/// </summary>
public class QRCodeValidationService : IQRCodeValidationService
{
    private readonly ApplicationDbContext _context;
    private readonly IQRCodeTokenService _tokenService;
    private readonly ILogger<QRCodeValidationService> _logger;

    public QRCodeValidationService(
        ApplicationDbContext context,
        IQRCodeTokenService tokenService,
        ILogger<QRCodeValidationService> logger)
    {
        _context = context;
        _tokenService = tokenService;
        _logger = logger;
    }

    /// <summary>
    /// Validate QR Code token and process transaction
    /// </summary>
    public async Task<QRCodeValidateResponseDto> ValidateQRCodeAsync(QRCodeValidateRequestDto request)
    {
        try
        {
            _logger.LogInformation("Starting QR Code validation for clinic {ClinicId}", request.ClinicId);

            // Check if clinic is authorized
            var isAuthorized = await IsClinicAuthorizedAsync(request.ClinicId);
            if (!isAuthorized)
            {
                throw new UnauthorizedClinicException(request.ClinicId);
            }

            // Validate and consume QR Code token
            var tokenClaims = await _tokenService.ValidateAndConsumeTokenAsync(request.QRToken);
            if (tokenClaims == null)
            {
                throw new InvalidQRException("Token validation failed");
            }

            // Use database transaction to ensure consistency
            using var transaction = await _context.Database.BeginTransactionAsync();
            
            try
            {
                // Get user plan and validate
                var userPlan = await _context.UserPlans
                    .Include(up => up.Plan)
                    .Include(up => up.User)
                    .FirstOrDefaultAsync(up => up.Id == tokenClaims.UserPlanId);

                if (userPlan == null || !userPlan.IsActive || userPlan.IsExpired)
                {
                    throw new InvalidUserPlanException(tokenClaims.UserPlanId);
                }

                // Check credits availability
                var creditsRequired = 1; // Default to 1 credit
                if (userPlan.CreditsRemaining < creditsRequired)
                {
                    throw new InsufficientCreditsException(userPlan.CreditsRemaining, creditsRequired);
                }

                // Get clinic information
                var clinic = await _context.Clinics.FindAsync(request.ClinicId);
                if (clinic == null)
                {
                    throw new UnauthorizedClinicException(request.ClinicId);
                }

                // Create transaction record
                var transactionRecord = new Data.Models.Transaction
                {
                    Id = Guid.NewGuid(),
                    Code = GenerateTransactionCode(),
                    UserPlanId = userPlan.Id,
                    ClinicId = request.ClinicId,
                    Status = TransactionStatus.Validated,
                    CreditsUsed = creditsRequired,
                    ServiceDescription = request.ServiceDescription ?? request.ServiceType ?? "QR Code Service",
                    ValidationDate = DateTime.UtcNow,
                    ValidatedBy = "System", // Could be enhanced to include clinic user info
                    QRToken = request.QRToken,
                    QRNonce = tokenClaims.Nonce,
                    ServiceType = request.ServiceType,
                    Amount = request.Amount ?? 10.00m, // Default amount
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.Transactions.Add(transactionRecord);

                // Debit credits from user plan
                userPlan.CreditsRemaining -= creditsRequired;
                userPlan.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                _logger.LogInformation("QR Code validation successful - Transaction: {TransactionCode}, UserPlan: {UserPlanId}, Clinic: {ClinicId}",
                    transactionRecord.Code, userPlan.Id, request.ClinicId);

                // Create successful response
                var response = new QRCodeValidateResponseDto
                {
                    Success = true,
                    TransactionId = transactionRecord.Id,
                    TransactionCode = transactionRecord.Code,
                    Patient = new PatientInfo
                    {
                        UserId = userPlan.User.Id,
                        Name = userPlan.User.FirstName + " " + userPlan.User.LastName,
                        Email = userPlan.User.Email,
                        Phone = userPlan.User.PhoneNumber
                    },
                    UserPlan = new UserPlanInfo
                    {
                        Id = userPlan.Id,
                        PlanName = userPlan.Plan.Name,
                        CreditsRemaining = userPlan.CreditsRemaining,
                        CreditsUsed = userPlan.CreditsUsed,
                        IsActive = userPlan.IsActive,
                        ExpiresAt = userPlan.ExpiresAt
                    },
                    Transaction = new TransactionInfo
                    {
                        Id = transactionRecord.Id,
                        Code = transactionRecord.Code,
                        CreditsUsed = transactionRecord.CreditsUsed,
                        Amount = transactionRecord.Amount,
                        ServiceType = transactionRecord.ServiceType,
                        ServiceDescription = transactionRecord.ServiceDescription,
                        CreatedAt = transactionRecord.CreatedAt
                    },
                    ValidatedAt = DateTime.UtcNow
                };

                return response;
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
        catch (QRCodeValidationException ex)
        {
            _logger.LogWarning("QR Code validation failed: {ErrorCode} - {Message}", ex.ErrorCode, ex.Message);
            
            return new QRCodeValidateResponseDto
            {
                Success = false,
                Error = new ValidationError
                {
                    Code = ex.ErrorCode,
                    Message = ex.Message,
                    Details = CreateErrorDetails(ex)
                },
                ValidatedAt = DateTime.UtcNow
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error during QR Code validation for clinic {ClinicId}", request.ClinicId);
            
            return new QRCodeValidateResponseDto
            {
                Success = false,
                Error = new ValidationError
                {
                    Code = "INTERNAL_ERROR",
                    Message = "An internal error occurred during validation"
                },
                ValidatedAt = DateTime.UtcNow
            };
        }
    }

    /// <summary>
    /// Parse QR Code token without consuming nonce
    /// </summary>
    public async Task<QRTokenClaims?> ParseQRCodeTokenAsync(string qrToken)
    {
        try
        {
            return await _tokenService.ParseTokenAsync(qrToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to parse QR Code token");
            return null;
        }
    }

    /// <summary>
    /// Check if clinic is authorized to validate QR codes
    /// </summary>
    public async Task<bool> IsClinicAuthorizedAsync(Guid clinicId)
    {
        try
        {
            var clinic = await _context.Clinics
                .Where(c => c.Id == clinicId)
                .Select(c => new { c.Id, c.IsActive })
                .FirstOrDefaultAsync();

            return clinic != null && clinic.IsActive;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to check clinic authorization for {ClinicId}", clinicId);
            return false;
        }
    }

    /// <summary>
    /// Generate unique transaction code
    /// </summary>
    private string GenerateTransactionCode()
    {
        var timestamp = DateTime.UtcNow.ToString("yyyyMMddHHmmss");
        var random = Random.Shared.Next(1000, 9999);
        return $"TXN{timestamp}{random}";
    }

    /// <summary>
    /// Create error details dictionary from exception
    /// </summary>
    private Dictionary<string, object>? CreateErrorDetails(QRCodeValidationException ex)
    {
        return ex switch
        {
            QRExpiredException expiredEx => new Dictionary<string, object>
            {
                ["expiresAt"] = expiredEx.ExpiresAt
            },
            QRAlreadyUsedException usedEx => new Dictionary<string, object>
            {
                ["nonce"] = usedEx.Nonce
            },
            InsufficientCreditsException creditsEx => new Dictionary<string, object>
            {
                ["availableCredits"] = creditsEx.AvailableCredits,
                ["requiredCredits"] = creditsEx.RequiredCredits
            },
            InvalidUserPlanException planEx => new Dictionary<string, object>
            {
                ["userPlanId"] = planEx.UserPlanId
            },
            UnauthorizedClinicException clinicEx => new Dictionary<string, object>
            {
                ["clinicId"] = clinicEx.ClinicId
            },
            _ => null
        };
    }
}