using SingleClin.API.DTOs.NotificationPreferences;
using SingleClin.API.Data.Models;
using SingleClin.API.Repositories;

namespace SingleClin.API.Services
{
    public class NotificationPreferencesService : INotificationPreferencesService
    {
        private readonly IUserNotificationPreferencesRepository _preferencesRepository;
        private readonly ILogger<NotificationPreferencesService> _logger;

        public NotificationPreferencesService(
            IUserNotificationPreferencesRepository preferencesRepository,
            ILogger<NotificationPreferencesService> logger)
        {
            _preferencesRepository = preferencesRepository;
            _logger = logger;
        }

        public async Task<NotificationPreferencesResponseDto> GetUserPreferencesAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("Retrieving notification preferences for user {UserId}", userId);

                var preferences = await _preferencesRepository.GetOrCreateDefaultAsync(userId, cancellationToken);
                
                return MapToResponseDto(preferences);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving notification preferences for user {UserId}", userId);
                throw;
            }
        }

        public async Task<NotificationPreferencesResponseDto> UpdateUserPreferencesAsync(Guid userId, NotificationPreferencesDto preferences, CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("Updating notification preferences for user {UserId}", userId);

                // Validate quiet hours if provided
                if (!string.IsNullOrEmpty(preferences.QuietHoursStart) && !string.IsNullOrEmpty(preferences.QuietHoursEnd))
                {
                    if (!IsValidTimeFormat(preferences.QuietHoursStart) || !IsValidTimeFormat(preferences.QuietHoursEnd))
                    {
                        throw new ArgumentException("Invalid time format for quiet hours. Use HH:MM format.");
                    }
                }

                // Get existing preferences or create new ones
                var existingPreferences = await _preferencesRepository.GetByUserIdAsync(userId, cancellationToken);
                
                UserNotificationPreferences updatedPreferences;
                
                if (existingPreferences == null)
                {
                    // Create new preferences
                    var newPreferences = MapToEntity(preferences, userId);
                    updatedPreferences = await _preferencesRepository.CreateAsync(newPreferences, cancellationToken);
                }
                else
                {
                    // Update existing preferences
                    var preferencesToUpdate = MapToEntity(preferences, userId);
                    preferencesToUpdate.Id = existingPreferences.Id;
                    preferencesToUpdate.CreatedAt = existingPreferences.CreatedAt;
                    
                    updatedPreferences = await _preferencesRepository.UpdateAsync(preferencesToUpdate, cancellationToken);
                }

                _logger.LogInformation("Successfully updated notification preferences for user {UserId}", userId);
                return MapToResponseDto(updatedPreferences);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating notification preferences for user {UserId}", userId);
                throw;
            }
        }

        public async Task<bool> UpdateDeviceTokenAsync(Guid userId, string deviceToken, string platform, CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("Updating device token for user {UserId}, platform: {Platform}", userId, platform);

                var result = await _preferencesRepository.UpdateDeviceTokenAsync(userId, deviceToken, platform, cancellationToken);
                
                if (result)
                {
                    _logger.LogInformation("Successfully updated device token for user {UserId}", userId);
                }
                else
                {
                    _logger.LogWarning("Failed to update device token for user {UserId}", userId);
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating device token for user {UserId}", userId);
                throw;
            }
        }

        public async Task<UserNotificationPreferences> GetOrCreateUserPreferencesAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            try
            {
                return await _preferencesRepository.GetOrCreateDefaultAsync(userId, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting or creating user preferences for user {UserId}", userId);
                throw;
            }
        }

        public async Task<List<UserNotificationPreferences>> GetUsersForLowBalanceNotificationAsync(int currentBalance, CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("Getting users for low balance notification with balance {Balance}", currentBalance);

                // Get users who have low balance threshold >= current balance and have notifications enabled
                var users = await _preferencesRepository.GetUsersWithLowBalanceThresholdAsync(currentBalance, cancellationToken);
                
                _logger.LogInformation("Found {Count} users for low balance notification", users.Count);
                return users;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting users for low balance notification with balance {Balance}", currentBalance);
                throw;
            }
        }

        public async Task<bool> ShouldSendNotificationAsync(Guid userId, string notificationType, bool isPushNotification, CancellationToken cancellationToken = default)
        {
            try
            {
                var preferences = await _preferencesRepository.GetOrCreateDefaultAsync(userId, cancellationToken);
                
                // Check if user wants this type of notification
                var shouldReceive = preferences.ShouldReceiveNotification(notificationType, isPushNotification);
                
                if (!shouldReceive)
                {
                    _logger.LogDebug("User {UserId} has disabled {NotificationType} notifications via {Channel}", 
                        userId, notificationType, isPushNotification ? "push" : "email");
                    return false;
                }

                // Check quiet hours for push notifications
                if (isPushNotification && preferences.IsQuietHour())
                {
                    _logger.LogDebug("User {UserId} is in quiet hours, skipping push notification", userId);
                    return false;
                }

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking if should send notification for user {UserId}", userId);
                // If we can't determine preferences, err on the side of not sending
                return false;
            }
        }

        private static NotificationPreferencesResponseDto MapToResponseDto(UserNotificationPreferences entity)
        {
            return new NotificationPreferencesResponseDto
            {
                UserId = entity.UserId,
                EnablePush = entity.EnablePush,
                EnableEmail = entity.EnableEmail,
                LowBalanceThreshold = entity.LowBalanceThreshold,
                PreferredLanguage = entity.PreferredLanguage,
                EnablePromotional = entity.EnablePromotional,
                EnablePayment = entity.EnablePayment,
                QuietHoursStart = entity.QuietHoursStart,
                QuietHoursEnd = entity.QuietHoursEnd,
                DeviceToken = entity.DeviceToken,
                DevicePlatform = entity.DevicePlatform,
                CreatedAt = entity.CreatedAt,
                UpdatedAt = entity.UpdatedAt
            };
        }

        private static UserNotificationPreferences MapToEntity(NotificationPreferencesDto dto, Guid userId)
        {
            return new UserNotificationPreferences
            {
                UserId = userId,
                EnablePush = dto.EnablePush,
                EnableEmail = dto.EnableEmail,
                LowBalanceThreshold = dto.LowBalanceThreshold,
                PreferredLanguage = dto.PreferredLanguage,
                EnablePromotional = dto.EnablePromotional,
                EnablePayment = dto.EnablePayment,
                QuietHoursStart = dto.QuietHoursStart,
                QuietHoursEnd = dto.QuietHoursEnd,
                DeviceToken = dto.DeviceToken,
                DevicePlatform = dto.DevicePlatform
            };
        }

        private static bool IsValidTimeFormat(string time)
        {
            return TimeSpan.TryParseExact(time, @"hh\:mm", null, out _);
        }
    }
}