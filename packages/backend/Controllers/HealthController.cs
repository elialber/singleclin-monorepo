using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;

namespace SingleClin.API.Controllers;

/// <summary>
/// Health check endpoints documentation
/// </summary>
[ApiController]
[Route("api/[controller]")]
[AllowAnonymous]
[SwaggerTag("Health check endpoints for monitoring API status")]
public class HealthController : ControllerBase
{
    /// <summary>
    /// Get information about available health check endpoints
    /// </summary>
    /// <response code="200">Returns information about health check endpoints</response>
    [HttpGet("info")]
    [SwaggerOperation(
        Summary = "Get health check endpoints information",
        Description = "Returns information about all available health check endpoints and their purposes",
        OperationId = "GetHealthCheckInfo"
    )]
    [SwaggerResponse(200, "Health check endpoints information", typeof(object))]
    public IActionResult GetHealthCheckInfo()
    {
        var endpoints = new
        {
            description = "SingleClin API Health Check Endpoints",
            endpoints = new object[]
            {
                new
                {
                    path = "/health",
                    method = "GET",
                    description = "Basic health check endpoint",
                    response = "Returns 200 (Healthy), 503 (Unhealthy), or 200 (Degraded) status codes"
                },
                new
                {
                    path = "/health/detailed",
                    method = "GET",
                    description = "Detailed health check with JSON response",
                    response = "Returns detailed JSON with status of all health checks, timing, and diagnostic data"
                },
                new
                {
                    path = "/health/live",
                    method = "GET",
                    description = "Liveness probe for Kubernetes/Docker",
                    response = "Returns 200 if the API process is alive and responding"
                },
                new
                {
                    path = "/health/ready",
                    method = "GET",
                    description = "Readiness probe for Kubernetes/Docker",
                    response = "Returns 200 if the API is ready to accept traffic (including external dependencies)"
                }
            },
            healthChecks = new object[]
            {
                new
                {
                    name = "api",
                    description = "General API health including version, uptime, and configuration status",
                    tags = new string[] { "api", "live" }
                },
                new
                {
                    name = "firebase",
                    description = "Firebase Admin SDK connectivity and authentication service",
                    tags = new string[] { "firebase", "auth" },
                    note = "Returns Degraded if Firebase is not configured (internal JWT still works)"
                }
            }
        };

        return Ok(endpoints);
    }

    /// <summary>
    /// Test CORS configuration
    /// </summary>
    /// <response code="200">Returns CORS test response with headers information</response>
    [HttpGet("cors-test")]
    [HttpOptions("cors-test")]
    [SwaggerOperation(
        Summary = "Test CORS configuration",
        Description = "Use this endpoint to test if CORS is properly configured for your frontend origin",
        OperationId = "TestCors"
    )]
    [SwaggerResponse(200, "CORS test response", typeof(object))]
    public IActionResult TestCors()
    {
        var response = new
        {
            message = "CORS test successful",
            timestamp = DateTime.UtcNow,
            headers = new
            {
                origin = Request.Headers["Origin"].ToString(),
                method = Request.Method,
                allowedOrigins = new[]
                {
                    "http://localhost:3000",
                    "http://localhost:4200",
                    "http://localhost:5173",
                    "capacitor://localhost",
                    "http://localhost"
                }
            }
        };

        return Ok(response);
    }
}