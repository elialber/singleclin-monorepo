using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using SingleClin.API.Data;
using Microsoft.EntityFrameworkCore;

namespace SingleClin.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ConfigDebugController : ControllerBase
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<ConfigDebugController> _logger;
    private readonly AppDbContext _context;

    public ConfigDebugController(IConfiguration configuration, ILogger<ConfigDebugController> logger, AppDbContext context)
    {
        _configuration = configuration;
        _logger = logger;
        _context = context;
    }

    [HttpGet("all")]
    public IActionResult GetAllConfig()
    {
        var configData = new Dictionary<string, object>();

        // Get all configuration as JSON
        foreach (var section in _configuration.GetChildren())
        {
            configData[section.Key] = GetConfigSection(section);
        }

        return Ok(new
        {
            Environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT"),
            ConfigData = configData
        });
    }

    [HttpGet("firebase")]
    public IActionResult GetFirebaseConfig()
    {
        var firebaseSection = _configuration.GetSection("Firebase");

        var result = new
        {
            Environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT"),
            FirebaseSectionExists = firebaseSection.Exists(),
            FirebaseProjectId = _configuration["Firebase:ProjectId"],
            FirebaseServiceAccount = _configuration["Firebase:ServiceAccountKeyPath"],
            FirebaseSection = GetConfigSection(firebaseSection),
            AllFirebaseKeys = firebaseSection.GetChildren().Select(c => new { c.Key, c.Value }).ToList()
        };

        _logger.LogInformation("Firebase Config Debug: {@Result}", result);

        return Ok(result);
    }

    [HttpPost("migrate-add-is-active")]
    public async Task<IActionResult> AddIsActiveColumnAsync()
    {
        try
        {
            _logger.LogInformation("Starting migration to add is_active column to ClinicServices");

            // Execute the SQL commands
            var commands = new[]
            {
                "ALTER TABLE \"ClinicServices\" ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true;",
                "CREATE INDEX IF NOT EXISTS \"IX_ClinicServices_IsActive\" ON \"ClinicServices\" (is_active);",
                "UPDATE \"ClinicServices\" SET is_active = true WHERE is_active IS NULL;"
            };

            var results = new List<string>();

            foreach (var command in commands)
            {
                try
                {
                    var result = await _context.Database.ExecuteSqlRawAsync(command);
                    results.Add($"Command executed successfully: {command} (affected rows: {result})");
                    _logger.LogInformation("Successfully executed: {Command}", command);
                }
                catch (Exception ex)
                {
                    var errorMsg = $"Error executing command '{command}': {ex.Message}";
                    results.Add(errorMsg);
                    _logger.LogError(ex, "Error executing command: {Command}", command);
                }
            }

            return Ok(new
            {
                Success = true,
                Message = "Migration completed",
                Results = results,
                Timestamp = DateTime.UtcNow
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during migration");
            return StatusCode(500, new
            {
                Success = false,
                Message = "Migration failed",
                Error = ex.Message,
                Timestamp = DateTime.UtcNow
            });
        }
    }

    private object GetConfigSection(IConfigurationSection section)
    {
        var children = section.GetChildren().ToList();

        if (!children.Any())
        {
            return section.Value;
        }

        var result = new Dictionary<string, object>();
        foreach (var child in children)
        {
            result[child.Key] = GetConfigSection(child);
        }

        return result;
    }
}