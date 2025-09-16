using Microsoft.Extensions.Diagnostics.HealthChecks;
using SingleClin.API.Services;

namespace SingleClin.API.HealthChecks;

/// <summary>
/// Health check for Redis connection
/// </summary>
public class RedisHealthCheck : IHealthCheck
{
    private readonly IRedisService _redisService;
    private readonly ILogger<RedisHealthCheck> _logger;

    public RedisHealthCheck(IRedisService redisService, ILogger<RedisHealthCheck> logger)
    {
        _redisService = redisService;
        _logger = logger;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var isConnected = await _redisService.IsConnectedAsync();

            if (isConnected)
            {
                _logger.LogDebug("Redis health check passed");
                return HealthCheckResult.Healthy("Redis is connected and operational");
            }
            else
            {
                _logger.LogWarning("Redis health check failed - connection test failed");
                return HealthCheckResult.Unhealthy("Redis connection test failed");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Redis health check failed with exception");
            return HealthCheckResult.Unhealthy($"Redis health check failed: {ex.Message}", ex);
        }
    }
}