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

    public string Channel => "email";

    public bool IsAvailable => true; // Always available for testing

    public Task<NotificationResponse> SendNotificationAsync(
        EmailNotificationRequest request,
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("MOCK EMAIL: Would send email to {ToEmail} with subject '{Subject}'",
            request.ToEmail, request.Subject);

        _logger.LogDebug("MOCK EMAIL Content: {Content}", request.Content);

        // Simulate successful email sending
        return Task.FromResult(NotificationResponse.Success($"Mock email sent to {request.ToEmail}", Channel));
    }
}