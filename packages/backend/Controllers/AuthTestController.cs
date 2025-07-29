using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace SingleClin.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthTestController : ControllerBase
{
    private readonly ILogger<AuthTestController> _logger;

    public AuthTestController(ILogger<AuthTestController> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Public endpoint - no authentication required
    /// </summary>
    [HttpGet("public")]
    public IActionResult GetPublic()
    {
        return Ok(new { message = "This is a public endpoint" });
    }

    /// <summary>
    /// Protected endpoint - requires authentication
    /// </summary>
    [HttpGet("protected")]
    [Authorize]
    public IActionResult GetProtected()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var email = User.FindFirst(ClaimTypes.Email)?.Value;
        var role = User.FindFirst(ClaimTypes.Role)?.Value;
        var clinicId = User.FindFirst("clinicId")?.Value;

        return Ok(new
        {
            message = "This is a protected endpoint",
            user = new
            {
                userId,
                email,
                role,
                clinicId
            }
        });
    }

    /// <summary>
    /// Admin only endpoint
    /// </summary>
    [HttpGet("admin-only")]
    [Authorize(Policy = "AdminOnly")]
    public IActionResult GetAdminOnly()
    {
        return Ok(new { message = "This endpoint is for admins only" });
    }

    /// <summary>
    /// Clinic only endpoint
    /// </summary>
    [HttpGet("clinic-only")]
    [Authorize(Policy = "ClinicOnly")]
    public IActionResult GetClinicOnly()
    {
        var clinicId = User.FindFirst("clinicId")?.Value;
        return Ok(new
        {
            message = "This endpoint is for clinics only",
            clinicId
        });
    }

    /// <summary>
    /// Patient only endpoint
    /// </summary>
    [HttpGet("patient-only")]
    [Authorize(Policy = "PatientOnly")]
    public IActionResult GetPatientOnly()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Ok(new
        {
            message = "This endpoint is for patients only",
            userId
        });
    }
}