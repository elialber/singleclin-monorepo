using SingleClin.API.Data.Models;

namespace SingleClin.API.Repositories
{
    public interface IUserNotificationPreferencesRepository
    {
        Task<UserNotificationPreferences?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
        Task<UserNotificationPreferences> CreateAsync(UserNotificationPreferences preferences, CancellationToken cancellationToken = default);
        Task<UserNotificationPreferences> UpdateAsync(UserNotificationPreferences preferences, CancellationToken cancellationToken = default);
        Task<UserNotificationPreferences> GetOrCreateDefaultAsync(Guid userId, CancellationToken cancellationToken = default);
        Task<bool> DeleteAsync(Guid userId, CancellationToken cancellationToken = default);
        Task<List<UserNotificationPreferences>> GetUsersWithLowBalanceThresholdAsync(int balanceThreshold, CancellationToken cancellationToken = default);
        Task<bool> UpdateDeviceTokenAsync(Guid userId, string deviceToken, string platform, CancellationToken cancellationToken = default);
    }
}