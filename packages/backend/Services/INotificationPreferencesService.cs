using SingleClin.API.DTOs.NotificationPreferences;
using SingleClin.API.Data.Models;

namespace SingleClin.API.Services
{
    public interface INotificationPreferencesService
    {
        Task<NotificationPreferencesResponseDto> GetUserPreferencesAsync(Guid userId, CancellationToken cancellationToken = default);
        Task<NotificationPreferencesResponseDto> UpdateUserPreferencesAsync(Guid userId, NotificationPreferencesDto preferences, CancellationToken cancellationToken = default);
        Task<bool> UpdateDeviceTokenAsync(Guid userId, string deviceToken, string platform, CancellationToken cancellationToken = default);
        Task<UserNotificationPreferences> GetOrCreateUserPreferencesAsync(Guid userId, CancellationToken cancellationToken = default);
        Task<List<UserNotificationPreferences>> GetUsersForLowBalanceNotificationAsync(int currentBalance, CancellationToken cancellationToken = default);
        Task<bool> ShouldSendNotificationAsync(Guid userId, string notificationType, bool isPushNotification, CancellationToken cancellationToken = default);
    }
}