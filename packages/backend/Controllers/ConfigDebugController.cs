using Microsoft.AspNetCore.Mvc;
using System.Text.Json;

namespace SingleClin.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ConfigDebugController : ControllerBase
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<ConfigDebugController> _logger;

    public ConfigDebugController(IConfiguration configuration, ILogger<ConfigDebugController> logger)
    {
        _configuration = configuration;
        _logger = logger;
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