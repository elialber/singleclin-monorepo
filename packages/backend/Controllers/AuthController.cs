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
    private readonly IWebHostEnvironment _hostEnvironment;

    public AuthController(IAuthService authService, ILogger<AuthController> logger, IWebHostEnvironment hostEnvironment)
    {
        _authService = authService;
        _logger = logger;
        _hostEnvironment = hostEnvironment;
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
    /// Get user claims for authenticated user
    /// </summary>
    /// <returns>User claims and permissions</returns>
    /// <response code="200">User claims retrieved successfully</response>
    /// <response code="401">Not authenticated</response>
    [HttpGet("claims")]
    [Authorize]
    [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetUserClaims()
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

        try
        {
            var claims = await _authService.GetUserClaimsAsync(userGuid);
            return Ok(claims);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving user claims for {UserId}", userGuid);
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Title = "Claims Retrieval Error",
                Detail = "An unexpected error occurred while retrieving user claims",
                Status = StatusCodes.Status500InternalServerError
            });
        }
    }

    /// <summary>
    /// Login with Firebase authentication token
    /// </summary>
    /// <param name="firebaseLoginDto">Firebase login information</param>
    /// <returns>Authentication response with tokens</returns>
    /// <response code="200">Firebase login successful</response>
    /// <response code="400">Invalid Firebase token</response>
    /// <response code="401">Firebase authentication failed</response>
    [HttpPost("login/firebase")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    public Task<IActionResult> FirebaseLogin([FromBody] FirebaseLoginDto firebaseLoginDto)
        => ExchangeFirebaseToken(firebaseLoginDto);

    /// <summary>
    /// Exchange a Firebase ID token for a SingleClin JWT + refresh token pair
    /// </summary>
    /// <param name="firebaseLoginDto">Firebase login information</param>
    /// <returns>Authentication response with tokens</returns>
    /// <response code="200">Token exchange successful</response>
    /// <response code="400">Invalid Firebase token</response>
    /// <response code="401">Firebase authentication failed</response>
    [HttpPost("firebase/exchange")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> ExchangeFirebaseToken([FromBody] FirebaseLoginDto firebaseLoginDto)
    {
        try
        {
            var ipAddress = GetIpAddress();
            var result = await _authService.FirebaseLoginAsync(firebaseLoginDto, ipAddress);

            if (!result.Success)
            {
                return result.Error?.Contains("Invalid token") ?? false
                    ? Unauthorized(new ProblemDetails
                    {
                        Title = "Authentication Failed",
                        Detail = result.Error,
                        Status = StatusCodes.Status401Unauthorized
                    })
                    : BadRequest(new ProblemDetails
                    {
                        Title = "Firebase Login Failed",
                        Detail = result.Error,
                        Status = StatusCodes.Status400BadRequest
                    });
            }

            _logger.LogInformation("Firebase token exchange successful: {Email}", result.Response!.Email);
            return Ok(result.Response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during Firebase token exchange");
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Title = "Firebase Token Exchange Error",
                Detail = "An unexpected error occurred during Firebase token exchange",
                Status = StatusCodes.Status500InternalServerError
            });
        }
    }

    /// <summary>
    /// Login with social provider (Google or Apple)
    /// </summary>
    /// <param name="socialLoginDto">Social login information</param>
    /// <returns>Authentication response with tokens</returns>
    /// <response code="200">Social login successful</response>
    /// <response code="400">Invalid social login data</response>
    /// <response code="503">Social login not available</response>
    [HttpPost("social-login")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status503ServiceUnavailable)]
    public async Task<IActionResult> SocialLogin([FromBody] SocialLoginDto socialLoginDto)
    {
        try
        {
            var ipAddress = GetIpAddress();
            var result = await _authService.SocialLoginAsync(socialLoginDto, ipAddress);

            if (!result.Success)
            {
                // Check if it's a configuration issue
                if (result.Error?.Contains("not configured") ?? false)
                {
                    return StatusCode(StatusCodes.Status503ServiceUnavailable, new ProblemDetails
                    {
                        Title = "Service Unavailable",
                        Detail = result.Error,
                        Status = StatusCodes.Status503ServiceUnavailable
                    });
                }

                return BadRequest(new ProblemDetails
                {
                    Title = "Social Login Failed",
                    Detail = result.Error,
                    Status = StatusCodes.Status400BadRequest
                });
            }

            _logger.LogInformation("Social login successful: {Email}, Provider: {Provider}",
                result.Response!.Email, socialLoginDto.Provider);
            return Ok(result.Response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during social login for provider {Provider}", socialLoginDto.Provider);
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Title = "Social Login Error",
                Detail = "An unexpected error occurred during social login",
                Status = StatusCodes.Status500InternalServerError
            });
        }
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

    /// <summary>
    /// [DEVELOPMENT ONLY] Create an Administrator account
    /// </summary>
    /// <param name="adminDto">Administrator account information</param>
    /// <returns>Created administrator details</returns>
    /// <response code="200">Administrator created successfully</response>
    /// <response code="400">Invalid data or email already exists</response>
    /// <response code="503">Not available in production</response>
    [HttpPost("create-admin")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status503ServiceUnavailable)]
    public async Task<IActionResult> CreateAdmin([FromBody] RegisterDto adminDto)
    {
        // Only allow in development environment
        if (!_hostEnvironment.IsDevelopment())
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new ProblemDetails
            {
                Title = "Service Unavailable",
                Detail = "Administrator creation is only available in development environment",
                Status = StatusCodes.Status503ServiceUnavailable
            });
        }

        try
        {
            // Force Administrator role
            adminDto.Role = UserRole.Administrator;

            var ipAddress = GetIpAddress();
            var result = await _authService.RegisterAsync(adminDto, ipAddress);

            if (!result.Success)
            {
                return BadRequest(new ProblemDetails
                {
                    Title = "Admin Creation Failed",
                    Detail = result.Error,
                    Status = StatusCodes.Status400BadRequest
                });
            }

            _logger.LogInformation("Administrator created successfully: {Email}", adminDto.Email);
            return Ok(result.Response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating administrator: {Email}", adminDto.Email);
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Title = "Admin Creation Error",
                Detail = "An unexpected error occurred while creating administrator",
                Status = StatusCodes.Status500InternalServerError
            });
        }
    }

    /// <summary>
    /// Sync Firebase user with backend database
    /// </summary>
    /// <param name="syncUserDto">Firebase user sync data</param>
    /// <returns>User authentication response</returns>
    /// <response code="200">User sync successful</response>
    /// <response code="400">Invalid sync data</response>
    /// <response code="401">Firebase authentication failed</response>
    [HttpPost("sync")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> SyncUser([FromBody] SyncUserDto syncUserDto)
    {
        try
        {
            var ipAddress = GetIpAddress();
            var result = await _authService.SyncUserWithBackendAsync(syncUserDto, ipAddress);

            if (!result.Success)
            {
                return BadRequest(new ProblemDetails
                {
                    Title = "User Sync Failed",
                    Detail = result.Error,
                    Status = StatusCodes.Status400BadRequest
                });
            }

            _logger.LogInformation("User sync successful: {Email}", result.Response!.Email);
            return Ok(result.Response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during user sync for {Email}", syncUserDto.Email);
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Title = "User Sync Error",
                Detail = "An unexpected error occurred during user sync",
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
