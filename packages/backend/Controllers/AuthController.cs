using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SingleClin.API.DTOs.Auth;
using SingleClin.API.Services;
using SingleClin.API.Data.Enums;
using System.Security.Claims;

namespace SingleClin.API.Controllers;

/// <summary>
/// Controller for authentication endpoints
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IAuthService authService, ILogger<AuthController> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    /// <summary>
    /// Register a new user
    /// </summary>
    /// <param name="registerDto">Registration information</param>
    /// <returns>Authentication response with tokens</returns>
    /// <response code="200">Registration successful</response>
    /// <response code="400">Invalid registration data or email already exists</response>
    [HttpPost("register")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Register([FromBody] RegisterDto registerDto)
    {
        try
        {
            // Validate role is allowed for self-registration
            if (registerDto.Role == UserRole.Administrator)
            {
                return BadRequest(new ProblemDetails
                {
                    Title = "Invalid Role",
                    Detail = "Administrator accounts cannot be created through self-registration",
                    Status = StatusCodes.Status400BadRequest
                });
            }

            // Validate clinic name for clinic users
            if ((registerDto.Role == UserRole.ClinicOrigin || registerDto.Role == UserRole.ClinicPartner) 
                && string.IsNullOrWhiteSpace(registerDto.ClinicName))
            {
                return BadRequest(new ProblemDetails
                {
                    Title = "Missing Clinic Name",
                    Detail = "Clinic name is required for clinic users",
                    Status = StatusCodes.Status400BadRequest
                });
            }

            var ipAddress = GetIpAddress();
            var result = await _authService.RegisterAsync(registerDto, ipAddress);

            if (!result.Success)
            {
                return BadRequest(new ProblemDetails
                {
                    Title = "Registration Failed",
                    Detail = result.Error,
                    Status = StatusCodes.Status400BadRequest
                });
            }

            _logger.LogInformation("User registered successfully: {Email}, Role: {Role}", registerDto.Email, registerDto.Role);
            return Ok(result.Response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during registration for {Email}", registerDto.Email);
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Title = "Registration Error",
                Detail = "An unexpected error occurred during registration",
                Status = StatusCodes.Status500InternalServerError
            });
        }
    }

    /// <summary>
    /// Login with email and password
    /// </summary>
    /// <param name="loginDto">Login credentials</param>
    /// <returns>Authentication response with tokens</returns>
    /// <response code="200">Login successful</response>
    /// <response code="401">Invalid credentials</response>
    [HttpPost("login")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login([FromBody] LoginDto loginDto)
    {
        try
        {
            var ipAddress = GetIpAddress();
            var result = await _authService.LoginAsync(loginDto, ipAddress);

            if (!result.Success)
            {
                return Unauthorized(new ProblemDetails
                {
                    Title = "Login Failed",
                    Detail = result.Error,
                    Status = StatusCodes.Status401Unauthorized
                });
            }

            _logger.LogInformation("User logged in successfully: {Email}", loginDto.Email);
            return Ok(result.Response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during login for {Email}", loginDto.Email);
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Title = "Login Error",
                Detail = "An unexpected error occurred during login",
                Status = StatusCodes.Status500InternalServerError
            });
        }
    }

    /// <summary>
    /// Refresh access token using refresh token
    /// </summary>
    /// <param name="refreshTokenDto">Refresh token information</param>
    /// <returns>New authentication response with tokens</returns>
    /// <response code="200">Token refreshed successfully</response>
    /// <response code="401">Invalid or expired refresh token</response>
    [HttpPost("refresh")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenDto refreshTokenDto)
    {
        try
        {
            var ipAddress = GetIpAddress();
            var result = await _authService.RefreshTokenAsync(refreshTokenDto.RefreshToken, ipAddress);

            if (!result.Success)
            {
                return Unauthorized(new ProblemDetails
                {
                    Title = "Token Refresh Failed",
                    Detail = result.Error,
                    Status = StatusCodes.Status401Unauthorized
                });
            }

            _logger.LogInformation("Token refreshed successfully for user: {UserId}", result.Response!.UserId);
            return Ok(result.Response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during token refresh");
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Title = "Token Refresh Error",
                Detail = "An unexpected error occurred during token refresh",
                Status = StatusCodes.Status500InternalServerError
            });
        }
    }

    /// <summary>
    /// Logout current user
    /// </summary>
    /// <returns>Success status</returns>
    /// <response code="200">Logout successful</response>
    /// <response code="401">Not authenticated</response>
    [HttpPost("logout")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Logout()
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
            {
                return Unauthorized(new ProblemDetails
                {
                    Title = "Invalid User",
                    Detail = "User ID not found in token",
                    Status = StatusCodes.Status401Unauthorized
                });
            }

            // Get refresh token from header if provided
            string? refreshToken = null;
            if (Request.Headers.TryGetValue("X-Refresh-Token", out var tokenValue))
            {
                refreshToken = tokenValue.ToString();
            }

            var success = await _authService.LogoutAsync(userGuid, refreshToken);
            if (!success)
            {
                _logger.LogWarning("Logout failed for user: {UserId}", userGuid);
            }

            _logger.LogInformation("User logged out: {UserId}", userGuid);
            return Ok(new { message = "Logout successful" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during logout");
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Title = "Logout Error",
                Detail = "An unexpected error occurred during logout",
                Status = StatusCodes.Status500InternalServerError
            });
        }
    }

    /// <summary>
    /// Get current user information
    /// </summary>
    /// <returns>Current user details</returns>
    /// <response code="200">User information retrieved</response>
    /// <response code="401">Not authenticated</response>
    [HttpGet("me")]
    [Authorize]
    [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    public IActionResult GetCurrentUser()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var email = User.FindFirst(ClaimTypes.Email)?.Value;
        var role = User.FindFirst("role")?.Value;
        var clinicId = User.FindFirst("clinicId")?.Value;

        return Ok(new
        {
            userId,
            email,
            role,
            clinicId
        });
    }

    /// <summary>
    /// Revoke all refresh tokens for current user (logout from all devices)
    /// </summary>
    /// <returns>Number of tokens revoked</returns>
    /// <response code="200">Tokens revoked successfully</response>
    /// <response code="401">Not authenticated</response>
    [HttpPost("revoke-all-tokens")]
    [Authorize]
    [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> RevokeAllTokens()
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
            {
                return Unauthorized(new ProblemDetails
                {
                    Title = "Invalid User",
                    Detail = "User ID not found in token",
                    Status = StatusCodes.Status401Unauthorized
                });
            }

            var count = await _authService.RevokeAllUserTokensAsync(userGuid);
            _logger.LogInformation("Revoked {Count} tokens for user: {UserId}", count, userGuid);

            return Ok(new { message = $"Revoked {count} tokens successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error revoking all tokens");
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Title = "Token Revocation Error",
                Detail = "An unexpected error occurred while revoking tokens",
                Status = StatusCodes.Status500InternalServerError
            });
        }
    }

    private string? GetIpAddress()
    {
        // Check for forwarded IP (when behind proxy/load balancer)
        var forwardedFor = Request.Headers["X-Forwarded-For"].FirstOrDefault();
        if (!string.IsNullOrEmpty(forwardedFor))
        {
            return forwardedFor.Split(',')[0].Trim();
        }

        // Check for real IP header
        var realIp = Request.Headers["X-Real-IP"].FirstOrDefault();
        if (!string.IsNullOrEmpty(realIp))
        {
            return realIp;
        }

        // Fall back to remote IP address
        return HttpContext.Connection.RemoteIpAddress?.ToString();
    }
}