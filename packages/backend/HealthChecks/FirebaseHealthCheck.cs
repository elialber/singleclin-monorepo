using Microsoft.Extensions.Diagnostics.HealthChecks;
using FirebaseAdmin;
using FirebaseAdmin.Auth;

namespace SingleClin.API.HealthChecks;

/// <summary>
/// Health check for Firebase Admin SDK connectivity
/// </summary>
public class FirebaseHealthCheck : IHealthCheck
{
    private readonly ILogger<FirebaseHealthCheck> _logger;

    public FirebaseHealthCheck(ILogger<FirebaseHealthCheck> logger)
    {
        _logger = logger;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            // Check if Firebase is initialized
            if (FirebaseApp.DefaultInstance == null)
            {
                return HealthCheckResult.Degraded(
                    "Firebase Admin SDK is not initialized. Only internal JWT authentication is available.");
            }

            // Try to get Firebase Auth instance
            var auth = FirebaseAuth.DefaultInstance;
            if (auth == null)
            {
                return HealthCheckResult.Unhealthy("Firebase Auth instance is not available");
            }

            // Try to create a custom token as a connectivity test
            var testClaims = new Dictionary<string, object>
            {
                { "healthCheck", true },
                { "timestamp", DateTimeOffset.UtcNow.ToUnixTimeSeconds() }
            };

            var token = await auth.CreateCustomTokenAsync("health-check-user", testClaims, cancellationToken);

            if (string.IsNullOrEmpty(token))
            {
                return HealthCheckResult.Unhealthy("Failed to create test token");
            }

            return HealthCheckResult.Healthy("Firebase Admin SDK is operational", new Dictionary<string, object>
            {
                { "projectId", FirebaseApp.DefaultInstance.Options.ProjectId ?? "Unknown" },
                { "serviceConnected", true }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Firebase health check failed");
            return HealthCheckResult.Unhealthy("Firebase health check failed", ex, new Dictionary<string, object>
            {
                { "error", ex.Message }
            });
        }
    }
}