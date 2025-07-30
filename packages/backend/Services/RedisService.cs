using Microsoft.Extensions.Caching.Distributed;
using System.Security.Cryptography;
using System.Text;

namespace SingleClin.API.Services;

/// <summary>
/// Redis service implementation for QR Code nonce management
/// </summary>
public class RedisService : IRedisService
{
    private readonly IDistributedCache _distributedCache;
    private readonly ILogger<RedisService> _logger;

    private const string NONCE_PREFIX = "qr_nonce:";
    private const int DEFAULT_EXPIRATION_MINUTES = 30;

    public RedisService(IDistributedCache distributedCache, ILogger<RedisService> logger)
    {
        _distributedCache = distributedCache;
        _logger = logger;
    }

    /// <summary>
    /// Store a nonce with expiration for QR Code generation
    /// </summary>
    public async Task<bool> StoreNonceAsync(string nonce, string userData, int expirationMinutes = DEFAULT_EXPIRATION_MINUTES)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(nonce))
            {
                _logger.LogWarning("Attempted to store nonce with null or empty value");
                return false;
            }

            var key = GetNonceKey(nonce);
            var options = new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(expirationMinutes)
            };

            await _distributedCache.SetStringAsync(key, userData, options);
            
            _logger.LogInformation("Nonce stored successfully with {ExpirationMinutes} minutes expiration", expirationMinutes);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to store nonce in Redis");
            return false;
        }
    }

    /// <summary>
    /// Retrieve and consume (remove) a nonce from Redis
    /// </summary>
    public async Task<string?> ConsumeNonceAsync(string nonce)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(nonce))
            {
                _logger.LogWarning("Attempted to consume nonce with null or empty value");
                return null;
            }

            var key = GetNonceKey(nonce);
            
            // Get the value first
            var userData = await _distributedCache.GetStringAsync(key);
            
            if (userData == null)
            {
                _logger.LogWarning("Nonce {Nonce} not found or expired", nonce);
                return null;
            }

            // Remove the nonce to prevent reuse
            await _distributedCache.RemoveAsync(key);
            
            _logger.LogInformation("Nonce consumed successfully");
            return userData;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to consume nonce from Redis");
            return null;
        }
    }

    /// <summary>
    /// Check if a nonce exists without consuming it
    /// </summary>
    public async Task<bool> NonceExistsAsync(string nonce)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(nonce))
            {
                return false;
            }

            var key = GetNonceKey(nonce);
            var value = await _distributedCache.GetStringAsync(key);
            
            return value != null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to check nonce existence in Redis");
            return false;
        }
    }

    /// <summary>
    /// Generate a new unique nonce using cryptographically secure random bytes
    /// </summary>
    public string GenerateNonce()
    {
        try
        {
            // Generate 32 random bytes (256 bits) for strong uniqueness
            var randomBytes = new byte[32];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(randomBytes);
            }

            // Convert to Base64 and make URL-safe
            var nonce = Convert.ToBase64String(randomBytes)
                .Replace("+", "-")
                .Replace("/", "_")
                .Replace("=", "");

            _logger.LogDebug("Generated new nonce with length {Length}", nonce.Length);
            return nonce;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to generate nonce");
            // Fallback to GUID if crypto fails
            return Guid.NewGuid().ToString("N");
        }
    }

    /// <summary>
    /// Check Redis connection health
    /// </summary>
    public async Task<bool> IsConnectedAsync()
    {
        try
        {
            // Try to perform a simple operation to test connectivity
            var testKey = "health_check_" + Guid.NewGuid().ToString("N");
            var testValue = "test";
            
            await _distributedCache.SetStringAsync(testKey, testValue, new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(10)
            });
            
            var retrievedValue = await _distributedCache.GetStringAsync(testKey);
            await _distributedCache.RemoveAsync(testKey);
            
            var isConnected = retrievedValue == testValue;
            
            if (isConnected)
            {
                _logger.LogDebug("Redis health check passed");
            }
            else
            {
                _logger.LogWarning("Redis health check failed - value mismatch");
            }
            
            return isConnected;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Redis health check failed");
            return false;
        }
    }

    /// <summary>
    /// Get the full Redis key for a nonce
    /// </summary>
    private static string GetNonceKey(string nonce)
    {
        return NONCE_PREFIX + nonce;
    }
}