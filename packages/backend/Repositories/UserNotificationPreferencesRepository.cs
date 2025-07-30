using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Distributed;
using SingleClin.API.Data;
using SingleClin.API.Data.Models;
using System.Text.Json;

namespace SingleClin.API.Repositories
{
    public class UserNotificationPreferencesRepository : IUserNotificationPreferencesRepository
    {
        private readonly ApplicationDbContext _context;
        private readonly IDistributedCache _cache;
        private readonly ILogger<UserNotificationPreferencesRepository> _logger;
        private const int CacheExpirationMinutes = 30;

        public UserNotificationPreferencesRepository(
            ApplicationDbContext context,
            IDistributedCache cache,
            ILogger<UserNotificationPreferencesRepository> logger)
        {
            _context = context;
            _cache = cache;
            _logger = logger;
        }

        public async Task<UserNotificationPreferences?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            try
            {
                // Try to get from cache first
                var cacheKey = GetCacheKey(userId);
                var cachedPreferences = await _cache.GetStringAsync(cacheKey, cancellationToken);
                
                if (!string.IsNullOrEmpty(cachedPreferences))
                {
                    _logger.LogDebug("Retrieved notification preferences from cache for user {UserId}", userId);
                    return JsonSerializer.Deserialize<UserNotificationPreferences>(cachedPreferences);
                }

                // Get from database
                var preferences = await _context.UserNotificationPreferences
                    .FirstOrDefaultAsync(p => p.UserId == userId, cancellationToken);

                // Cache the result if found
                if (preferences != null)
                {
                    await CachePreferencesAsync(preferences, cancellationToken);
                }

                return preferences;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving notification preferences for user {UserId}", userId);
                throw;
            }
        }

        public async Task<UserNotificationPreferences> CreateAsync(UserNotificationPreferences preferences, CancellationToken cancellationToken = default)
        {
            try
            {
                preferences.CreatedAt = DateTime.UtcNow;
                preferences.UpdatedAt = DateTime.UtcNow;

                _context.UserNotificationPreferences.Add(preferences);
                await _context.SaveChangesAsync(cancellationToken);

                // Cache the new preferences
                await CachePreferencesAsync(preferences, cancellationToken);

                _logger.LogInformation("Created notification preferences for user {UserId}", preferences.UserId);
                return preferences;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating notification preferences for user {UserId}", preferences.UserId);
                throw;
            }
        }

        public async Task<UserNotificationPreferences> UpdateAsync(UserNotificationPreferences preferences, CancellationToken cancellationToken = default)
        {
            try
            {
                var existingPreferences = await _context.UserNotificationPreferences
                    .FirstOrDefaultAsync(p => p.UserId == preferences.UserId, cancellationToken);

                if (existingPreferences == null)
                {
                    throw new InvalidOperationException($"Notification preferences not found for user {preferences.UserId}");
                }

                // Update properties
                existingPreferences.EnablePush = preferences.EnablePush;
                existingPreferences.EnableEmail = preferences.EnableEmail;
                existingPreferences.LowBalanceThreshold = preferences.LowBalanceThreshold;
                existingPreferences.PreferredLanguage = preferences.PreferredLanguage;
                existingPreferences.EnablePromotional = preferences.EnablePromotional;
                existingPreferences.EnablePayment = preferences.EnablePayment;
                existingPreferences.QuietHoursStart = preferences.QuietHoursStart;
                existingPreferences.QuietHoursEnd = preferences.QuietHoursEnd;
                existingPreferences.DeviceToken = preferences.DeviceToken;
                existingPreferences.DevicePlatform = preferences.DevicePlatform;
                existingPreferences.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync(cancellationToken);

                // Update cache
                await CachePreferencesAsync(existingPreferences, cancellationToken);

                _logger.LogInformation("Updated notification preferences for user {UserId}", preferences.UserId);
                return existingPreferences;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating notification preferences for user {UserId}", preferences.UserId);
                throw;
            }
        }

        public async Task<UserNotificationPreferences> GetOrCreateDefaultAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            try
            {
                var existing = await GetByUserIdAsync(userId, cancellationToken);
                if (existing != null)
                {
                    return existing;
                }

                // Create default preferences
                var defaultPreferences = UserNotificationPreferences.CreateDefault(userId);
                return await CreateAsync(defaultPreferences, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting or creating default notification preferences for user {UserId}", userId);
                throw;
            }
        }

        public async Task<bool> DeleteAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            try
            {
                var preferences = await _context.UserNotificationPreferences
                    .FirstOrDefaultAsync(p => p.UserId == userId, cancellationToken);

                if (preferences == null)
                {
                    return false;
                }

                _context.UserNotificationPreferences.Remove(preferences);
                await _context.SaveChangesAsync(cancellationToken);

                // Remove from cache
                var cacheKey = GetCacheKey(userId);
                await _cache.RemoveAsync(cacheKey, cancellationToken);

                _logger.LogInformation("Deleted notification preferences for user {UserId}", userId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting notification preferences for user {UserId}", userId);
                throw;
            }
        }

        public async Task<List<UserNotificationPreferences>> GetUsersWithLowBalanceThresholdAsync(int balanceThreshold, CancellationToken cancellationToken = default)
        {
            try
            {
                return await _context.UserNotificationPreferences
                    .Where(p => p.LowBalanceThreshold >= balanceThreshold && 
                               (p.EnablePush || p.EnableEmail))
                    .Include(p => p.User)
                    .ToListAsync(cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving users with low balance threshold {Threshold}", balanceThreshold);
                throw;
            }
        }

        public async Task<bool> UpdateDeviceTokenAsync(Guid userId, string deviceToken, string platform, CancellationToken cancellationToken = default)
        {
            try
            {
                var preferences = await _context.UserNotificationPreferences
                    .FirstOrDefaultAsync(p => p.UserId == userId, cancellationToken);

                if (preferences == null)
                {
                    // Create default preferences with device token
                    var defaultPreferences = UserNotificationPreferences.CreateDefault(userId);
                    defaultPreferences.DeviceToken = deviceToken;
                    defaultPreferences.DevicePlatform = platform;
                    await CreateAsync(defaultPreferences, cancellationToken);
                    return true;
                }

                // Update existing preferences
                preferences.DeviceToken = deviceToken;
                preferences.DevicePlatform = platform;
                preferences.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync(cancellationToken);

                // Update cache
                await CachePreferencesAsync(preferences, cancellationToken);

                _logger.LogInformation("Updated device token for user {UserId}, platform: {Platform}", userId, platform);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating device token for user {UserId}", userId);
                throw;
            }
        }

        private async Task CachePreferencesAsync(UserNotificationPreferences preferences, CancellationToken cancellationToken)
        {
            try
            {
                var cacheKey = GetCacheKey(preferences.UserId);
                var serializedPreferences = JsonSerializer.Serialize(preferences);
                var cacheOptions = new DistributedCacheEntryOptions
                {
                    AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(CacheExpirationMinutes)
                };

                await _cache.SetStringAsync(cacheKey, serializedPreferences, cacheOptions, cancellationToken);
                _logger.LogDebug("Cached notification preferences for user {UserId}", preferences.UserId);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to cache notification preferences for user {UserId}", preferences.UserId);
                // Don't throw - caching failure shouldn't break the operation
            }
        }

        private static string GetCacheKey(Guid userId)
        {
            return $"notification_preferences_{userId}";
        }
    }
}