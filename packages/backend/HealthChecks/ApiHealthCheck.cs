using Microsoft.Extensions.Diagnostics.HealthChecks;
using System.Reflection;

namespace SingleClin.API.HealthChecks;

/// <summary>
/// General API health check
/// </summary>
public class ApiHealthCheck : IHealthCheck
{
    private readonly IConfiguration _configuration;
    private readonly IWebHostEnvironment _environment;

    public ApiHealthCheck(IConfiguration configuration, IWebHostEnvironment environment)
    {
        _configuration = configuration;
        _environment = environment;
    }

    public Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context, 
        CancellationToken cancellationToken = default)
    {
        try
        {
            var assembly = Assembly.GetExecutingAssembly();
            var version = assembly.GetName().Version?.ToString() ?? "Unknown";
            var buildDate = File.GetLastWriteTime(assembly.Location);

            var data = new Dictionary<string, object>
            {
                { "version", version },
                { "buildDate", buildDate.ToString("yyyy-MM-dd HH:mm:ss") },
                { "environment", _environment.EnvironmentName },
                { "uptime", GetUptime() },
                { "machineName", Environment.MachineName },
                { "osVersion", Environment.OSVersion.ToString() },
                { "processorCount", Environment.ProcessorCount },
                { "contentRoot", _environment.ContentRootPath },
                { "jwtConfigured", !string.IsNullOrEmpty(_configuration["JWT:SecretKey"]) },
                { "corsEnabled", true }
            };

            return Task.FromResult(HealthCheckResult.Healthy("API is running", data));
        }
        catch (Exception ex)
        {
            return Task.FromResult(HealthCheckResult.Unhealthy("API health check failed", ex));
        }
    }

    private string GetUptime()
    {
        var uptime = DateTime.UtcNow - System.Diagnostics.Process.GetCurrentProcess().StartTime.ToUniversalTime();
        return $"{(int)uptime.TotalDays}d {uptime.Hours}h {uptime.Minutes}m {uptime.Seconds}s";
    }
}