using Microsoft.AspNetCore.Mvc;
using SingleClin.API.Services;

namespace SingleClin.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class FirebaseTestController : ControllerBase
{
    private readonly IFirebaseAuthService _firebaseAuthService;
    private readonly ILogger<FirebaseTestController> _logger;
    private readonly IConfiguration _configuration;

    public FirebaseTestController(IFirebaseAuthService firebaseAuthService, ILogger<FirebaseTestController> logger, IConfiguration configuration)
    {
        _firebaseAuthService = firebaseAuthService;
        _logger = logger;
        _configuration = configuration;
    }

    [HttpGet("status")]
    public IActionResult GetFirebaseStatus()
    {
        _logger.LogInformation("Checking Firebase status...");
        
        var status = new
        {
            IsConfigured = _firebaseAuthService.IsConfigured,
            FirebaseAppExists = FirebaseAdmin.FirebaseApp.DefaultInstance != null,
            FirebaseProject = FirebaseAdmin.FirebaseApp.DefaultInstance?.Options?.ProjectId,
            Environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT"),
            ConfigProjectId = _configuration["Firebase:ProjectId"],
            ConfigServiceAccount = _configuration["Firebase:ServiceAccountKeyPath"],
            Timestamp = DateTime.UtcNow
        };
        
        _logger.LogInformation("Firebase Status: {@Status}", status);
        
        return Ok(status);
    }

    [HttpPost("test-create-user")]
    public async Task<IActionResult> TestCreateUser([FromBody] TestUserDto dto)
    {
        _logger.LogInformation("Test create user called for email: {Email}", dto.Email);
        
        if (!_firebaseAuthService.IsConfigured)
        {
            return BadRequest(new { error = "Firebase is not configured" });
        }

        try
        {
            var result = await _firebaseAuthService.CreateUserAsync(
                dto.Email,
                dto.Password,
                dto.DisplayName,
                false
            );

            if (result == null)
            {
                return BadRequest(new { error = "Failed to create user in Firebase" });
            }

            return Ok(new
            {
                success = true,
                uid = result.Uid,
                email = result.Email,
                displayName = result.DisplayName
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating test user");
            return StatusCode(500, new { error = ex.Message });
        }
    }
}

public class TestUserDto
{
    public required string Email { get; set; }
    public required string Password { get; set; }
    public string? DisplayName { get; set; }
}