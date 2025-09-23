using Microsoft.Extensions.Caching.Distributed;
using System.Net;
using System.Text.Json;

namespace SingleClin.API.Middleware;

/// <summary>
/// Rate limiting middleware for clinic QR Code validation endpoints
/// </summary>
public class ClinicRateLimitingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IDistributedCache _cache;
    private readonly ILogger<ClinicRateLimitingMiddleware> _logger;
    private readonly IConfiguration _configuration;

    // Default rate limiting configuration
    private const int DefaultLimit = 100; // requests per minute
    private const int DefaultWindowMinutes = 1;
    private const string RateLimitPrefix = "rate_limit:clinic:";

    public ClinicRateLimitingMiddleware(
        RequestDelegate next,
        IDistributedCache cache,
        ILogger<ClinicRateLimitingMiddleware> logger,
        IConfiguration configuration)
    {
        _next = next;
        _cache = cache;
        _logger = logger;
        _configuration = configuration;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Only apply rate limiting to specific endpoints
        if (!ShouldApplyRateLimit(context))
        {
            await _next(context);
            return;
        }

        var clinicId = GetClinicIdFromContext(context);
        if (string.IsNullOrEmpty(clinicId))
        {
            // If no clinic ID, let the request proceed - authorization will handle it
            await _next(context);
            return;
        }

        try
        {
            var (isAllowed, rateLimitInfo) = await CheckRateLimitAsync(clinicId);

            // Add rate limit headers
            AddRateLimitHeaders(context, rateLimitInfo);

            if (!isAllowed)
            {
                _logger.LogWarning("Rate limit exceeded for clinic {ClinicId}. Limit: {Limit}, Window: {Window}min",
                    clinicId, rateLimitInfo.Limit, rateLimitInfo.WindowMinutes);

                await HandleRateLimitExceeded(context, rateLimitInfo);
                return;
            }

            // Update rate limit counter
            await UpdateRateLimitAsync(clinicId, rateLimitInfo);

            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in rate limiting middleware for clinic {ClinicId}", clinicId);
            // On error, allow the request to proceed
            await _next(context);
        }
    }

    /// <summary>
    /// Check if rate limiting should be applied to this request
    /// </summary>
    private static bool ShouldApplyRateLimit(HttpContext context)
    {
        var path = context.Request.Path.Value?.ToLowerInvariant();
        return path != null && (
            path.Contains("/transactions/validate-qr") ||
            path.Contains("/transactions/parse-qr")
        );
    }

    /// <summary>
    /// Extract clinic ID from JWT claims
    /// </summary>
    private static string? GetClinicIdFromContext(HttpContext context)
    {
        if (context.User?.Identity?.IsAuthenticated != true)
        {
            return null;
        }

        return context.User.FindFirst("clinicId")?.Value;
    }

    /// <summary>
    /// Check if the clinic has exceeded the rate limit
    /// </summary>
    private async Task<(bool isAllowed, RateLimitInfo rateLimitInfo)> CheckRateLimitAsync(string clinicId)
    {
        var rateLimitInfo = GetRateLimitConfig(clinicId);
        var key = GetRateLimitKey(clinicId);

        try
        {
            var currentCountStr = await _cache.GetStringAsync(key);
            var currentCount = string.IsNullOrEmpty(currentCountStr) ? 0 : int.Parse(currentCountStr);

            var isAllowed = currentCount < rateLimitInfo.Limit;
            rateLimitInfo.Remaining = Math.Max(0, rateLimitInfo.Limit - currentCount - (isAllowed ? 1 : 0));
            rateLimitInfo.Current = currentCount;

            return (isAllowed, rateLimitInfo);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to check rate limit for clinic {ClinicId}", clinicId);
            // On error, allow the request
            return (true, rateLimitInfo);
        }
    }

    /// <summary>
    /// Update the rate limit counter
    /// </summary>
    private async Task UpdateRateLimitAsync(string clinicId, RateLimitInfo rateLimitInfo)
    {
        var key = GetRateLimitKey(clinicId);

        try
        {
            var currentCountStr = await _cache.GetStringAsync(key);
            var currentCount = string.IsNullOrEmpty(currentCountStr) ? 0 : int.Parse(currentCountStr);
            var newCount = currentCount + 1;

            var options = new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(rateLimitInfo.WindowMinutes)
            };

            await _cache.SetStringAsync(key, newCount.ToString(), options);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update rate limit for clinic {ClinicId}", clinicId);
        }
    }

    /// <summary>
    /// Get rate limit configuration for clinic
    /// </summary>
    private RateLimitInfo GetRateLimitConfig(string clinicId)
    {
        // Get default configuration
        var limit = _configuration.GetValue<int>("RateLimit:QRValidation:DefaultLimit", DefaultLimit);
        var windowMinutes = _configuration.GetValue<int>("RateLimit:QRValidation:WindowMinutes", DefaultWindowMinutes);

        // Check for clinic-specific configuration
        var clinicLimit = _configuration.GetValue<int?>($"RateLimit:QRValidation:Clinics:{clinicId}:Limit");
        var clinicWindow = _configuration.GetValue<int?>($"RateLimit:QRValidation:Clinics:{clinicId}:WindowMinutes");

        return new RateLimitInfo
        {
            Limit = clinicLimit ?? limit,
            WindowMinutes = clinicWindow ?? windowMinutes,
            ResetTime = DateTime.UtcNow.AddMinutes(clinicWindow ?? windowMinutes)
        };
    }

    /// <summary>
    /// Generate Redis key for rate limiting
    /// </summary>
    private static string GetRateLimitKey(string clinicId)
    {
        var windowStart = DateTime.UtcNow.ToString("yyyyMMddHHmm");
        return $"{RateLimitPrefix}{clinicId}:{windowStart}";
    }

    /// <summary>
    /// Add rate limit headers to response
    /// </summary>
    private static void AddRateLimitHeaders(HttpContext context, RateLimitInfo rateLimitInfo)
    {
        context.Response.Headers["X-RateLimit-Limit"] = rateLimitInfo.Limit.ToString();
        context.Response.Headers["X-RateLimit-Remaining"] = rateLimitInfo.Remaining.ToString();
        context.Response.Headers["X-RateLimit-Reset"] = new DateTimeOffset(rateLimitInfo.ResetTime).ToUnixTimeSeconds().ToString();
        context.Response.Headers["X-RateLimit-Window"] = $"{rateLimitInfo.WindowMinutes}m";
    }

    /// <summary>
    /// Handle rate limit exceeded response
    /// </summary>
    private static async Task HandleRateLimitExceeded(HttpContext context, RateLimitInfo rateLimitInfo)
    {
        context.Response.StatusCode = (int)HttpStatusCode.TooManyRequests;
        context.Response.ContentType = "application/json";

        var response = new
        {
            error = new
            {
                code = "RATE_LIMIT_EXCEEDED",
                message = $"Rate limit exceeded. Limit: {rateLimitInfo.Limit} requests per {rateLimitInfo.WindowMinutes} minute(s)",
                details = new
                {
                    limit = rateLimitInfo.Limit,
                    windowMinutes = rateLimitInfo.WindowMinutes,
                    remaining = rateLimitInfo.Remaining,
                    resetTime = rateLimitInfo.ResetTime,
                    retryAfter = Math.Max(1, (int)(rateLimitInfo.ResetTime - DateTime.UtcNow).TotalSeconds)
                }
            },
            timestamp = DateTime.UtcNow
        };

        var jsonResponse = JsonSerializer.Serialize(response, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            WriteIndented = false
        });

        await context.Response.WriteAsync(jsonResponse);
    }
}

/// <summary>
/// Rate limit information for a clinic
/// </summary>
public class RateLimitInfo
{
    public int Limit { get; set; }
    public int Remaining { get; set; }
    public int Current { get; set; }
    public int WindowMinutes { get; set; }
    public DateTime ResetTime { get; set; }
}