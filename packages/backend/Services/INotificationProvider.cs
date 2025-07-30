using SingleClin.API.DTOs.Notification;

namespace SingleClin.API.Services
{
    public interface INotificationProvider
    {
        Task<NotificationResponse> SendAsync(NotificationRequest request, CancellationToken cancellationToken = default);
        NotificationChannel Channel { get; }
        bool IsHealthy();
    }

    public interface IPushNotificationProvider : INotificationProvider
    {
        Task<NotificationResponse> SendPushAsync(PushNotificationRequest request, CancellationToken cancellationToken = default);
    }

    public interface IEmailNotificationProvider : INotificationProvider
    {
        Task<NotificationResponse> SendEmailAsync(EmailNotificationRequest request, CancellationToken cancellationToken = default);
    }
}