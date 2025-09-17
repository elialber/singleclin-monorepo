using SingleClin.API.DTOs.Notification;

namespace SingleClin.API.Services;

/// <summary>
/// Mock email provider for development/testing when SendGrid is not configured
/// </summary>
public class MockEmailProvider : IEmailNotificationProvider
{
    private readonly ILogger<MockEmailProvider> _logger;

    public MockEmailProvider(ILogger<MockEmailProvider> logger)
    {
        _logger = logger;
    }

    public NotificationChannel Channel => NotificationChannel.Email;

    public bool IsHealthy() => true; // Always healthy for testing

    public Task<NotificationResponse> SendAsync(NotificationRequest request, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("MOCK NOTIFICATION: Would send {Type} notification", request.GetType().Name);
        _logger.LogDebug("MOCK NOTIFICATION Content: {Content}", request.Content);

        // Simulate successful notification sending
        return Task.FromResult(NotificationResponse.Successful($"Mock notification sent", Channel));
    }

    public Task<NotificationResponse> SendEmailAsync(EmailNotificationRequest request, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("MOCK EMAIL: Would send email to {ToEmail} with subject '{Subject}'",
            request.ToEmail, request.Subject);

        _logger.LogDebug("MOCK EMAIL Content: {Content}", request.Content);

        // Simulate successful email sending
        return Task.FromResult(NotificationResponse.Successful($"Mock email sent to {request.ToEmail}", Channel));
    }
}