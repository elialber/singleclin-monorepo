using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SingleClin.API.DTOs;
using SingleClin.API.DTOs.QRCode;
using SingleClin.API.Services;
using System.Security.Claims;
using Swashbuckle.AspNetCore.Annotations;

namespace SingleClin.API.Controllers;

/// <summary>
/// Controller for QR Code generation and validation
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class QRCodeController : BaseController
{
    private readonly IQRCodeService _qrCodeService;
    private readonly IQRCodeTokenService _qrCodeTokenService;
    private readonly IPlanService _planService;
    private readonly ILogger<QRCodeController> _logger;

    // Rate limiting: Track QR code generation per user
    private static readonly Dictionary<string, List<DateTime>> _userGenerationHistory = new();
    private static readonly object _rateLimitLock = new object();
    private const int MaxQRCodesPerMinute = 5;

    public QRCodeController(
        IQRCodeService qrCodeService,
        IQRCodeTokenService qrCodeTokenService,
        IPlanService planService,
        ILogger<QRCodeController> logger)
    {
        _qrCodeService = qrCodeService;
        _qrCodeTokenService = qrCodeTokenService;
        _planService = planService;
        _logger = logger;
    }

    /// <summary>
    /// Generate a new QR Code for the authenticated user
    /// </summary>
    /// <param name="request">QR Code generation parameters</param>
    /// <returns>QR Code data with embedded JWT token</returns>
    [HttpPost("generate")]
    [SwaggerOperation(
        Summary = "Generate QR Code",
        Description = "Generate a temporary QR Code with embedded JWT token for healthcare visits"
    )]
    [SwaggerResponse(200, "QR Code generated successfully", typeof(ResponseWrapper<QRCodeGenerateResponseDto>))]
    [SwaggerResponse(400, "Invalid request parameters", typeof(ResponseWrapper<object>))]
    [SwaggerResponse(401, "User not authenticated", typeof(ResponseWrapper<object>))]
    [SwaggerResponse(403, "User plan is inactive or expired", typeof(ResponseWrapper<object>))]
    [SwaggerResponse(429, "Rate limit exceeded", typeof(ResponseWrapper<object>))]
    [SwaggerResponse(500, "Internal server error", typeof(ResponseWrapper<object>))]
    public async Task<ActionResult<ResponseWrapper<QRCodeGenerateResponseDto>>> GenerateQRCode(
        [FromBody] QRCodeGenerateRequestDto request)
    {
        try
        {
            // Get current user ID
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
            {
                _logger.LogWarning("QR Code generation attempted without valid user ID");
                return Unauthorized(ResponseWrapper<object>.CreateFailure("User not authenticated"));
            }

            // Check rate limiting
            if (!CheckRateLimit(userId))
            {
                _logger.LogWarning("Rate limit exceeded for user {UserId}", userId);
                return StatusCode(429, ResponseWrapper<object>.CreateFailure(
                    $"Rate limit exceeded. Maximum {MaxQRCodesPerMinute} QR codes per minute allowed"));
            }

            // Get user's active plan - we need the plan ID for QR Code generation
            var userGuid = Guid.Parse(userId);
            
            // For now, we'll need to get the user's current plan to get the plan ID
            // This could be optimized by storing plan ID in the user's JWT claims
            var userPlan = await _qrCodeService.ValidateUserPlanAsync(userGuid);
            if (!userPlan)
            {
                _logger.LogWarning("User {UserId} has no valid plan for QR Code generation", userId);
                return Forbid(ResponseWrapper<object>.CreateFailure("No valid plan found or plan is inactive").ToString());
            }

            // Generate QR Code using orchestrator service
            var qrCodeResult = await _qrCodeService.GenerateQRCodeAsync(
                userGuid, // Using userId as userPlanId for now - this should be the actual userPlanId
                userId,
                request.Size ?? 300,
                request.ExpirationMinutes ?? 30);

            // Check if QR Code generation was successful
            if (!qrCodeResult.Success)
            {
                _logger.LogWarning("QR Code generation failed for user {UserId}: {ErrorMessage}", 
                    userId, qrCodeResult.ErrorMessage);
                
                var errorResponse = new QRCodeGenerateResponseDto
                {
                    Success = false,
                    ErrorMessage = qrCodeResult.ErrorMessage
                };

                return BadRequest(ResponseWrapper<QRCodeGenerateResponseDto>.CreateFailure(
                    qrCodeResult.ErrorMessage ?? "QR Code generation failed", errorResponse));
            }

            // Create response
            var response = new QRCodeGenerateResponseDto
            {
                Success = qrCodeResult.Success,
                QRCode = qrCodeResult.QRCodeDataUrl,
                Token = qrCodeResult.Token,
                Nonce = qrCodeResult.Nonce,
                ExpiresAt = qrCodeResult.ExpiresAt,
                GeneratedAt = qrCodeResult.GeneratedAt
            };

            _logger.LogInformation("QR Code generated successfully for user {UserId} with nonce {Nonce}", 
                userId, qrCodeResult.Nonce);

            return Ok(ResponseWrapper<QRCodeGenerateResponseDto>.CreateSuccess(response));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to generate QR Code");
            
            var errorResponse = new QRCodeGenerateResponseDto
            {
                Success = false,
                ErrorMessage = "Failed to generate QR Code"
            };

            return StatusCode(500, ResponseWrapper<QRCodeGenerateResponseDto>.CreateFailure(
                "Internal server error", errorResponse));
        }
    }

    /// <summary>
    /// Validate a QR Code token (for clinic use)
    /// </summary>
    /// <param name="token">JWT token from QR Code</param>
    /// <returns>Token validation result with user plan information</returns>
    [HttpPost("validate")]
    [Authorize(Policy = "CanValidateQR")]
    [SwaggerOperation(
        Summary = "Validate QR Code Token",
        Description = "Validate and consume a QR Code token (clinic use only)"
    )]
    [SwaggerResponse(200, "Token validated successfully")]
    [SwaggerResponse(400, "Invalid or expired token")]
    [SwaggerResponse(403, "Insufficient permissions")]
    public async Task<ActionResult<ResponseWrapper<object>>> ValidateQRCode([FromBody] string token)
    {
        try
        {
            var claims = await _qrCodeTokenService.ValidateAndConsumeTokenAsync(token);
            if (claims == null)
            {
                return BadRequest(ResponseWrapper<object>.CreateFailure("Invalid or expired QR Code token"));
            }

            // Get user plan details for clinic
            var userPlan = await _planService.GetUserPlanByIdAsync(claims.UserPlanId);
            if (userPlan == null)
            {
                return BadRequest(ResponseWrapper<object>.CreateFailure("User plan not found"));
            }

            var result = new
            {
                valid = true,
                userId = claims.UserId,
                userPlan = new
                {
                    id = userPlan.Id,
                    planName = userPlan.Plan.Name,
                    creditsRemaining = userPlan.CreditsRemaining,
                    isActive = userPlan.IsActive,
                    expiresAt = userPlan.ExpiresAt
                },
                tokenInfo = new
                {
                    nonce = claims.Nonce,
                    issuedAt = claims.IssuedAt,
                    expiresAt = claims.ExpiresAt
                }
            };

            _logger.LogInformation("QR Code token validated and consumed for user plan {UserPlanId}", 
                claims.UserPlanId);

            return Ok(ResponseWrapper<object>.CreateSuccess(result));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to validate QR Code token");
            return StatusCode(500, ResponseWrapper<object>.CreateFailure("Internal server error"));
        }
    }

    /// <summary>
    /// Get QR Code generation metrics (admin only)
    /// </summary>
    /// <returns>QR Code generation statistics</returns>
    [HttpGet("metrics")]
    [Authorize(Policy = "RequireAdminRole")]
    [SwaggerOperation(
        Summary = "Get QR Code Metrics",
        Description = "Get QR Code generation statistics (admin only)"
    )]
    [SwaggerResponse(200, "Metrics retrieved successfully")]
    [SwaggerResponse(403, "Insufficient permissions")]
    public async Task<ActionResult<ResponseWrapper<QRCodeMetrics>>> GetMetrics()
    {
        try
        {
            var metrics = await _qrCodeService.GetMetricsAsync();
            return Ok(ResponseWrapper<QRCodeMetrics>.CreateSuccess(metrics));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve QR Code metrics");
            return StatusCode(500, ResponseWrapper<object>.CreateFailure("Internal server error"));
        }
    }

    /// <summary>
    /// Check rate limiting for QR Code generation
    /// </summary>
    private bool CheckRateLimit(string userId)
    {
        lock (_rateLimitLock)
        {
            var now = DateTime.UtcNow;
            var oneMinuteAgo = now.AddMinutes(-1);

            // Initialize user history if not exists
            if (!_userGenerationHistory.ContainsKey(userId))
            {
                _userGenerationHistory[userId] = new List<DateTime>();
            }

            var userHistory = _userGenerationHistory[userId];

            // Remove old entries (older than 1 minute)
            userHistory.RemoveAll(timestamp => timestamp < oneMinuteAgo);

            // Check if user exceeded rate limit
            if (userHistory.Count >= MaxQRCodesPerMinute)
            {
                return false;
            }

            // Add current request
            userHistory.Add(now);
            return true;
        }
    }
}