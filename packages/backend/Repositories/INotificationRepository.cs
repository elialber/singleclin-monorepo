using SingleClin.API.Data.Models;

namespace SingleClin.API.Repositories
{
    public interface INotificationRepository
    {
        Task<NotificationLog> AddNotificationLogAsync(NotificationLog log, CancellationToken cancellationToken = default);
        Task<NotificationLog?> GetNotificationLogAsync(Guid id, CancellationToken cancellationToken = default);
        Task<List<NotificationLog>> GetUserNotificationHistoryAsync(Guid userId, int page = 1, int pageSize = 50, CancellationToken cancellationToken = default);
        Task<bool> HasRecentNotificationAsync(Guid userId, string type, int thresholdMinutes = 60, CancellationToken cancellationToken = default);
        Task<NotificationLog> UpdateRetryCountAsync(Guid logId, int retryCount, string? errorMessage = null, CancellationToken cancellationToken = default);
        Task<List<NotificationLog>> GetFailedNotificationsAsync(int maxRetries = 3, DateTime? since = null, CancellationToken cancellationToken = default);
    }
}