using Microsoft.Extensions.Caching.Memory;

namespace SingleClin.API.Services;

/// <summary>
/// Orchestrator service for QR Code generation workflow
/// </summary>
public class QRCodeService : IQRCodeService
{
    private readonly IQRCodeTokenService _tokenService;
    private readonly IQRCodeGeneratorService _generatorService;
    private readonly IPlanService _planService;
    private readonly IMemoryCache _memoryCache;
    private readonly ILogger<QRCodeService> _logger;

    // Metrics tracking
    private static long _totalGenerated = 0;
    private static long _successfulGenerated = 0;
    private static long _failedGenerated = 0;
    private static DateTime _lastGenerated = DateTime.MinValue;
    private static readonly object _metricsLock = new object();

    // Cache keys
    private const string QR_CACHE_PREFIX = "qr_code_";
    private const string USER_PLAN_CACHE_PREFIX = "user_plan_validation_";

    public QRCodeService(
        IQRCodeTokenService tokenService,
        IQRCodeGeneratorService generatorService,
        IPlanService planService,
        IMemoryCache memoryCache,
        ILogger<QRCodeService> logger)
    {
        _tokenService = tokenService;
        _generatorService = generatorService;
        _planService = planService;
        _memoryCache = memoryCache;
        _logger = logger;
    }

    /// <summary>
    /// Generate complete QR Code for a user plan
    /// </summary>
    public async Task<QRCodeResult> GenerateQRCodeAsync(Guid userPlanId, string userId, int size = 300, int expirationMinutes = 30)
    {
        var startTime = DateTime.UtcNow;

        try
        {
            _logger.LogInformation("Starting QR Code generation for user plan {UserPlanId}", userPlanId);

            // Check cache first (1-minute cache to avoid unnecessary regeneration)
            var cacheKey = $"{QR_CACHE_PREFIX}{userPlanId}_{userId}_{size}_{expirationMinutes}";
            if (_memoryCache.TryGetValue(cacheKey, out QRCodeResult? cachedResult) && cachedResult != null)
            {
                _logger.LogDebug("Returning cached QR Code for user plan {UserPlanId}", userPlanId);
                return cachedResult;
            }

            // Validate user plan
            var isValidPlan = await ValidateUserPlanAsync(userPlanId);
            if (!isValidPlan)
            {
                var errorResult = new QRCodeResult
                {
                    Success = false,
                    ErrorMessage = "User plan is inactive, expired, or not found"
                };

                RecordMetrics(false);
                _logger.LogWarning("QR Code generation failed: Invalid user plan {UserPlanId}", userPlanId);
                return errorResult;
            }

            // Generate JWT token with nonce
            _logger.LogDebug("Generating JWT token for user plan {UserPlanId}", userPlanId);
            var (token, nonce) = await _tokenService.GenerateTokenAsync(userPlanId, userId, expirationMinutes);

            // Generate QR Code image
            _logger.LogDebug("Generating QR Code image with size {Size}px", size);
            var qrCodeDataUrl = _generatorService.GenerateQRCode(token, size);

            // Create successful result
            var result = new QRCodeResult
            {
                Success = true,
                QRCodeDataUrl = qrCodeDataUrl,
                Token = token,
                Nonce = nonce,
                ExpiresAt = DateTime.UtcNow.AddMinutes(expirationMinutes),
                GeneratedAt = DateTime.UtcNow
            };

            // Cache result for 1 minute
            var cacheOptions = new MemoryCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(1),
                Priority = CacheItemPriority.Normal
            };
            _memoryCache.Set(cacheKey, result, cacheOptions);

            // Record successful metrics
            RecordMetrics(true);

            var duration = DateTime.UtcNow - startTime;
            _logger.LogInformation("QR Code generated successfully for user plan {UserPlanId} in {Duration}ms",
                userPlanId, duration.TotalMilliseconds);

            // Audit log
            _logger.LogInformation("AUDIT: QR Code generated - UserPlan: {UserPlanId}, User: {UserId}, Nonce: {Nonce}, ExpiresAt: {ExpiresAt}",
                userPlanId, userId, nonce, result.ExpiresAt);

            return result;
        }
        catch (Exception ex)
        {
            RecordMetrics(false);

            var errorResult = new QRCodeResult
            {
                Success = false,
                ErrorMessage = "Internal error occurred during QR Code generation"
            };

            var duration = DateTime.UtcNow - startTime;
            _logger.LogError(ex, "QR Code generation failed for user plan {UserPlanId} after {Duration}ms",
                userPlanId, duration.TotalMilliseconds);

            return errorResult;
        }
    }

    /// <summary>
    /// Validate user plan before QR Code generation
    /// </summary>
    public async Task<bool> ValidateUserPlanAsync(Guid userPlanId)
    {
        try
        {
            // Check cache first (5-minute cache for plan validation)
            var cacheKey = $"{USER_PLAN_CACHE_PREFIX}{userPlanId}";
            if (_memoryCache.TryGetValue(cacheKey, out bool cachedValidation))
            {
                _logger.LogDebug("Returning cached plan validation for {UserPlanId}: {IsValid}", userPlanId, cachedValidation);
                return cachedValidation;
            }

            // Get user plan from service
            var userPlan = await _planService.GetUserPlanByIdAsync(userPlanId);
            if (userPlan == null)
            {
                _logger.LogWarning("User plan {UserPlanId} not found", userPlanId);
                CacheValidationResult(cacheKey, false);
                return false;
            }

            // Check if plan is active and not expired
            var isValid = userPlan.IsActive && !userPlan.IsExpired && userPlan.CreditsRemaining > 0;

            if (!isValid)
            {
                _logger.LogWarning("User plan {UserPlanId} validation failed - Active: {IsActive}, Expired: {IsExpired}, Credits: {Credits}",
                    userPlanId, userPlan.IsActive, userPlan.IsExpired, userPlan.CreditsRemaining);
            }
            else
            {
                _logger.LogDebug("User plan {UserPlanId} validation successful", userPlanId);
            }

            CacheValidationResult(cacheKey, isValid);
            return isValid;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error validating user plan {UserPlanId}", userPlanId);
            return false;
        }
    }

    /// <summary>
    /// Get QR Code generation metrics
    /// </summary>
    public async Task<QRCodeMetrics> GetMetricsAsync()
    {
        return await Task.FromResult(new QRCodeMetrics
        {
            TotalGenerated = _totalGenerated,
            SuccessfulGenerated = _successfulGenerated,
            FailedGenerated = _failedGenerated,
            LastGenerated = _lastGenerated,
            MetricsUpdatedAt = DateTime.UtcNow
        });
    }

    /// <summary>
    /// Record QR Code generation metrics
    /// </summary>
    private void RecordMetrics(bool success)
    {
        lock (_metricsLock)
        {
            _totalGenerated++;
            _lastGenerated = DateTime.UtcNow;

            if (success)
            {
                _successfulGenerated++;
            }
            else
            {
                _failedGenerated++;
            }
        }
    }

    /// <summary>
    /// Cache plan validation result
    /// </summary>
    private void CacheValidationResult(string cacheKey, bool isValid)
    {
        var cacheOptions = new MemoryCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5),
            Priority = CacheItemPriority.High // Plan validation is important
        };
        _memoryCache.Set(cacheKey, isValid, cacheOptions);
    }
}
