using SingleClin.API.DTOs.Notification;
using SingleClin.API.Data.Models;

namespace SingleClin.API.Services
{
    public interface INotificationService
    {
        Task<NotificationResponse> SendLowBalanceAlertAsync(Guid userId, int currentBalance, string planName, CancellationToken cancellationToken = default);
        Task<NotificationResponse> SendEmailNotificationAsync(Guid userId, EmailNotificationRequest request, CancellationToken cancellationToken = default);
        Task<NotificationResponse> SendPushNotificationAsync(Guid userId, PushNotificationRequest request, CancellationToken cancellationToken = default);
        Task<NotificationResponse> SendNotificationAsync(Guid userId, NotificationRequest request, CancellationToken cancellationToken = default);
        Task<List<NotificationLog>> GetUserNotificationHistoryAsync(Guid userId, int page = 1, int pageSize = 50, CancellationToken cancellationToken = default);
        Task<bool> RetryFailedNotificationsAsync(int maxRetries = 3, CancellationToken cancellationToken = default);
        Task<bool> IsWithinQuietHoursAsync(CancellationToken cancellationToken = default);
    }
}