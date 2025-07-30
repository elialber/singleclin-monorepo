using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SingleClin.API.DTOs;
using SingleClin.API.DTOs.QRCode;
using SingleClin.API.Services;
using System.Security.Claims;
using Swashbuckle.AspNetCore.Annotations;

namespace SingleClin.API.Controllers;

/// <summary>
/// Controller for transaction management and QR Code validation
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class TransactionController : BaseController
{
    private readonly IQRCodeValidationService _qrValidationService;
    private readonly ILogger<TransactionController> _logger;

    public TransactionController(
        IQRCodeValidationService qrValidationService,
        ILogger<TransactionController> logger)
    {
        _qrValidationService = qrValidationService;
        _logger = logger;
    }

    /// <summary>
    /// Validate QR Code and process transaction (clinic use)
    /// </summary>
    /// <param name="request">QR Code validation request</param>
    /// <returns>Validation result with patient and transaction information</returns>
    [HttpPost("validate-qr")]
    [Authorize(Policy = "CanValidateQR")]
    [SwaggerOperation(
        Summary = "Validate QR Code",
        Description = "Validate a patient's QR Code and process the transaction. Creates a transaction record and debits credits from the patient's plan."
    )]
    [SwaggerResponse(200, "QR Code validated successfully", typeof(ResponseWrapper<QRCodeValidateResponseDto>))]
    [SwaggerResponse(400, "Invalid request or QR Code validation failed", typeof(ResponseWrapper<QRCodeValidateResponseDto>))]
    [SwaggerResponse(401, "Clinic not authenticated", typeof(ResponseWrapper<object>))]
    [SwaggerResponse(403, "Clinic not authorized to validate QR codes", typeof(ResponseWrapper<object>))]
    [SwaggerResponse(429, "Rate limit exceeded", typeof(ResponseWrapper<object>))]
    [SwaggerResponse(500, "Internal server error", typeof(ResponseWrapper<object>))]
    public async Task<ActionResult<ResponseWrapper<QRCodeValidateResponseDto>>> ValidateQRCode(
        [FromBody] QRCodeValidateRequestDto request)
    {
        try
        {
            // Validate that the clinic ID in the request matches the authenticated clinic
            var authenticatedClinicId = GetAuthenticatedClinicId();
            if (authenticatedClinicId != request.ClinicId)
            {
                _logger.LogWarning("Clinic ID mismatch: authenticated {AuthenticatedId}, requested {RequestedId}", 
                    authenticatedClinicId, request.ClinicId);
                return Forbid("Clinic ID in request does not match authenticated clinic");
            }

            _logger.LogInformation("Processing QR Code validation for clinic {ClinicId}", request.ClinicId);

            // Validate QR Code and process transaction
            var result = await _qrValidationService.ValidateQRCodeAsync(request);

            if (result.Success)
            {
                _logger.LogInformation("QR Code validation successful - Transaction: {TransactionCode}, Clinic: {ClinicId}", 
                    result.TransactionCode, request.ClinicId);
                
                return Ok(ResponseWrapper<QRCodeValidateResponseDto>.CreateSuccess(result, "QR Code validated successfully"));
            }
            else
            {
                _logger.LogWarning("QR Code validation failed for clinic {ClinicId}: {ErrorCode} - {ErrorMessage}", 
                    request.ClinicId, result.Error?.Code, result.Error?.Message);
                
                return BadRequest(ResponseWrapper<QRCodeValidateResponseDto>.CreateFailure(
                    result.Error?.Message ?? "QR Code validation failed", result));
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error during QR Code validation for clinic {ClinicId}", request.ClinicId);
            
            var errorResult = new QRCodeValidateResponseDto
            {
                Success = false,
                Error = new ValidationError
                {
                    Code = "INTERNAL_ERROR",
                    Message = "An internal error occurred during validation"
                },
                ValidatedAt = DateTime.UtcNow
            };

            return StatusCode(500, ResponseWrapper<QRCodeValidateResponseDto>.CreateFailure(
                "Internal server error", errorResult));
        }
    }

    /// <summary>
    /// Parse QR Code token without processing transaction (preview)
    /// </summary>
    /// <param name="qrToken">QR Code token to parse</param>
    /// <returns>Token information for preview</returns>
    [HttpPost("parse-qr")]
    [Authorize(Policy = "CanValidateQR")]
    [SwaggerOperation(
        Summary = "Parse QR Code Token",
        Description = "Parse QR Code token to preview patient information without processing the transaction"
    )]
    [SwaggerResponse(200, "QR Code parsed successfully")]
    [SwaggerResponse(400, "Invalid QR Code token")]
    [SwaggerResponse(403, "Insufficient permissions")]
    public async Task<ActionResult<ResponseWrapper<object>>> ParseQRCode([FromBody] string qrToken)
    {
        try
        {
            var claims = await _qrValidationService.ParseQRCodeTokenAsync(qrToken);
            if (claims == null)
            {
                return BadRequest(ResponseWrapper<object>.CreateFailure("Invalid or expired QR Code token"));
            }

            var result = new
            {
                valid = true,
                userPlanId = claims.UserPlanId,
                userId = claims.UserId,
                nonce = claims.Nonce,
                issuedAt = claims.IssuedAt,
                expiresAt = claims.ExpiresAt,
                isExpired = claims.IsExpired,
                tokenType = claims.TokenType
            };

            return Ok(ResponseWrapper<object>.CreateSuccess(result));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to parse QR Code token");
            return StatusCode(500, ResponseWrapper<object>.CreateFailure("Internal server error"));
        }
    }

    /// <summary>
    /// Get transactions for the authenticated clinic
    /// </summary>
    /// <param name="page">Page number (default: 1)</param>
    /// <param name="pageSize">Page size (default: 20, max: 100)</param>
    /// <returns>Paginated list of transactions</returns>
    [HttpGet("clinic-transactions")]
    [Authorize(Policy = "RequireClinicRole")]
    [SwaggerOperation(
        Summary = "Get Clinic Transactions",
        Description = "Get paginated list of transactions for the authenticated clinic"
    )]
    [SwaggerResponse(200, "Transactions retrieved successfully")]
    [SwaggerResponse(403, "Insufficient permissions")]
    public async Task<ActionResult<ResponseWrapper<object>>> GetClinicTransactions(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        try
        {
            var clinicId = GetAuthenticatedClinicId();
            if (clinicId == Guid.Empty)
            {
                return Forbid("No clinic ID found in authentication token");
            }

            // Validate pagination parameters
            page = Math.Max(1, page);
            pageSize = Math.Min(100, Math.Max(1, pageSize));

            // This would need to be implemented with proper pagination
            // For now, return a placeholder response
            var result = new
            {
                page,
                pageSize,
                totalCount = 0,
                totalPages = 0,
                transactions = new object[0]
            };

            return Ok(ResponseWrapper<object>.CreateSuccess(result));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve clinic transactions");
            return StatusCode(500, ResponseWrapper<object>.CreateFailure("Internal server error"));
        }
    }

    /// <summary>
    /// Get authenticated clinic ID from JWT claims
    /// </summary>
    /// <returns>Clinic ID if found, empty GUID otherwise</returns>
    private Guid GetAuthenticatedClinicId()
    {
        var clinicIdClaim = User.FindFirst("clinicId")?.Value;
        if (string.IsNullOrEmpty(clinicIdClaim))
        {
            return Guid.Empty;
        }

        return Guid.TryParse(clinicIdClaim, out var clinicId) ? clinicId : Guid.Empty;
    }
}