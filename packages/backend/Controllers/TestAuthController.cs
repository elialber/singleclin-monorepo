using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SingleClin.API.Attributes;
using SingleClin.API.Data.Enums;

namespace SingleClin.API.Controllers;

/// <summary>
/// Test controller to demonstrate authorization attributes
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class TestAuthController : ControllerBase
{
    private readonly ILogger<TestAuthController> _logger;

    public TestAuthController(ILogger<TestAuthController> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Public endpoint - no authentication required
    /// </summary>
    [HttpGet("public")]
    [AllowAnonymous]
    public IActionResult PublicEndpoint()
    {
        return Ok(new { message = "This is a public endpoint" });
    }

    /// <summary>
    /// Requires any authenticated user
    /// </summary>
    [HttpGet("authenticated")]
    [Authorize]
    public IActionResult AuthenticatedEndpoint()
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var role = User.FindFirst("role")?.Value;
        return Ok(new
        {
            message = "You are authenticated",
            userId,
            role
        });
    }

    /// <summary>
    /// Admin only endpoint
    /// </summary>
    [HttpGet("admin-only")]
    [AuthorizeAdmin]
    public IActionResult AdminOnlyEndpoint()
    {
        return Ok(new { message = "Welcome Administrator!" });
    }

    /// <summary>
    /// Clinic users only endpoint (Origin or Partner)
    /// </summary>
    [HttpGet("clinic-only")]
    [AuthorizeClinic]
    public IActionResult ClinicOnlyEndpoint()
    {
        var clinicId = User.FindFirst("clinicId")?.Value;
        return Ok(new
        {
            message = "Welcome Clinic User!",
            clinicId
        });
    }

    /// <summary>
    /// Patient only endpoint
    /// </summary>
    [HttpGet("patient-only")]
    [AuthorizePatient]
    public IActionResult PatientOnlyEndpoint()
    {
        return Ok(new { message = "Welcome Patient!" });
    }

    /// <summary>
    /// Multiple roles allowed (Admin or Clinic)
    /// </summary>
    [HttpGet("admin-or-clinic")]
    [AuthorizeRole(UserRole.Administrator, UserRole.ClinicOrigin, UserRole.ClinicPartner)]
    public IActionResult AdminOrClinicEndpoint()
    {
        var role = User.FindFirst("role")?.Value;
        return Ok(new
        {
            message = "Welcome Admin or Clinic User!",
            role
        });
    }

    /// <summary>
    /// Clinic-specific resource - only accessible by the clinic owner
    /// </summary>
    [HttpGet("clinic/{clinicId}/details")]
    [AuthorizeClinicOwner("clinicId")]
    public IActionResult GetClinicDetails(Guid clinicId)
    {
        return Ok(new
        {
            message = "You have access to this clinic",
            clinicId,
            userClinicId = User.FindFirst("clinicId")?.Value
        });
    }

    /// <summary>
    /// Clinic resource accessible by admin or clinic owner
    /// </summary>
    [HttpGet("clinic/{clinicId}/admin-access")]
    [AuthorizeAdminOrClinicOwner("clinicId")]
    public IActionResult GetClinicAdminAccess(Guid clinicId)
    {
        var role = User.FindFirst("role")?.Value;
        return Ok(new
        {
            message = "You have admin or owner access to this clinic",
            clinicId,
            accessType = role == UserRole.Administrator.ToString() ? "Admin" : "Owner"
        });
    }

    /// <summary>
    /// Example of using authorization in action - check claims programmatically
    /// </summary>
    [HttpGet("check-claims")]
    [Authorize]
    public IActionResult CheckClaims()
    {
        var claims = User.Claims.Select(c => new { c.Type, c.Value }).ToList();
        return Ok(new
        {
            message = "Your claims",
            claims
        });
    }
}