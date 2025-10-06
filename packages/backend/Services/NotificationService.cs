using Microsoft.Extensions.Options;
using Microsoft.EntityFrameworkCore;
using SingleClin.API.DTOs.Notification;
using SingleClin.API.DTOs.EmailTemplate;
using SingleClin.API.Data.Models;
using SingleClin.API.Data;
using SingleClin.API.Repositories;
using System.Text.Json;

namespace SingleClin.API.Services
{
    public class NotificationService : INotificationService
    {
        private readonly ILogger<NotificationService> _logger;
        private readonly ApplicationDbContext _context;
        private readonly INotificationRepository _notificationRepository;
        private readonly IPushNotificationProvider _pushProvider;
        private readonly IEmailNotificationProvider _emailProvider;
        private readonly INotificationPreferencesService _preferencesService;
        private readonly NotificationOptions _options;

        public NotificationService(
            ILogger<NotificationService> logger,
            ApplicationDbContext context,
            INotificationRepository notificationRepository,
            IPushNotificationProvider pushProvider,
            IEmailNotificationProvider emailProvider,
            INotificationPreferencesService preferencesService,
            IOptions<NotificationOptions> options)
        {
            _logger = logger;
            _context = context;
            _notificationRepository = notificationRepository;
            _pushProvider = pushProvider;
            _emailProvider = emailProvider;
            _preferencesService = preferencesService;
            _options = options.Value;
        }

        public async Task<NotificationResponse> SendLowBalanceAlertAsync(Guid userId, int currentBalance, string planName, CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("Sending low balance alert to user {UserId}. Balance: {Balance}", userId, currentBalance);

                // Get user preferences to determine if they want low balance notifications
                var userPreferences = await _preferencesService.GetOrCreateUserPreferencesAsync(userId, cancellationToken);

                // Check if user's threshold allows for notification at this balance level
                if (currentBalance > userPreferences.LowBalanceThreshold)
                {
                    _logger.LogInformation("User {UserId} threshold is {Threshold}, current balance {Balance} doesn't qualify for notification",
                        userId, userPreferences.LowBalanceThreshold, currentBalance);
                    return NotificationResponse.Failed("Balance above user threshold", NotificationChannel.Push);
                }

                // Check if user was recently notified for this balance threshold
                var recentNotification = await _notificationRepository.HasRecentNotificationAsync(
                    userId,
                    $"LowBalance_{currentBalance}",
                    60, // 1 hour threshold
                    cancellationToken);

                if (recentNotification)
                {
                    _logger.LogInformation("User {UserId} was recently notified about balance {Balance}. Skipping.", userId, currentBalance);
                    return NotificationResponse.Failed("Recent notification already sent", NotificationChannel.Push);
                }

                // Get user information
                var user = await _context.Users.FindAsync(new object[] { userId }, cancellationToken);
                if (user == null)
                {
                    return NotificationResponse.Failed("User not found", NotificationChannel.Push);
                }

                // Create template data for rendering (plan ID not needed for templates)
                var templateData = LowBalanceTemplateData.Create(
                    userId,
                    user.UserName ?? user.Email ?? "Usuário",
                    currentBalance,
                    planName,
                    Guid.Empty);

                // Determine the best channel for notification
                var channel = await DetermineOptimalChannelAsync(userId, NotificationType.LowBalance, cancellationToken);

                NotificationResponse response;

                // Send via email using template
                if (channel == NotificationChannel.Email)
                {
                    if (_emailProvider is SendGridProvider sendGridProvider)
                    {
                        // Use templated email for better formatting
                        response = await sendGridProvider.SendLowBalanceNotificationAsync(
                            user.Email ?? "unknown@unknown.com",
                            user.UserName ?? "Usuário",
                            templateData,
                            cancellationToken);
                    }
                    else
                    {
                        // Fallback to basic email
                        var subject = $"Saldo Baixo - {currentBalance} crédito{(currentBalance != 1 ? "s" : "")} restante{(currentBalance != 1 ? "s" : "")}";
                        var message = $"Olá {user.UserName}, você tem apenas {currentBalance} crédito{(currentBalance != 1 ? "s" : "")} restante{(currentBalance != 1 ? "s" : "")} no plano {planName}. Renove já para continuar usando os serviços!";

                        var emailRequest = new EmailNotificationRequest
                        {
                            Email = user.Email ?? "unknown@unknown.com",
                            Recipient = user.UserName ?? "Usuário",
                            Subject = subject,
                            Message = message,
                            Type = NotificationType.LowBalance,
                            Priority = currentBalance <= 1 ? 3 : 2
                        };

                        response = await SendEmailNotificationAsync(userId, emailRequest, cancellationToken);
                    }
                }
                else
                {
                    // Send via push notification (fallback to old method)
                    var subject = $"Saldo Baixo - {currentBalance} crédito{(currentBalance != 1 ? "s" : "")} restante{(currentBalance != 1 ? "s" : "")}";
                    var message = $"Você tem apenas {currentBalance} crédito{(currentBalance != 1 ? "s" : "")} restante{(currentBalance != 1 ? "s" : "")} no plano {planName}. Renove já!";

                    var notificationRequest = new NotificationRequest
                    {
                        Recipient = user.Email ?? user.UserName ?? "unknown",
                        Subject = subject,
                        Message = message,
                        Type = NotificationType.LowBalance,
                        Data = new Dictionary<string, object>
                        {
                            ["currentBalance"] = currentBalance,
                            ["planName"] = planName,
                            ["userId"] = userId.ToString(),
                            ["balanceThreshold"] = currentBalance
                        },
                        Priority = currentBalance <= 1 ? 3 : 2
                    };

                    response = await SendNotificationAsync(userId, notificationRequest, cancellationToken);
                }

                // Log the specific low balance notification type for future deduplication
                if (response.Success)
                {
                    // Create a generic notification request for logging purposes
                    var logRequest = new NotificationRequest
                    {
                        Recipient = user.Email ?? user.UserName ?? "unknown",
                        Subject = $"Saldo Baixo - {currentBalance} crédito{(currentBalance != 1 ? "s" : "")} restante{(currentBalance != 1 ? "s" : "")}",
                        Message = $"Você tem apenas {currentBalance} crédito{(currentBalance != 1 ? "s" : "")} restante{(currentBalance != 1 ? "s" : "")} no plano {planName}. Renove já!",
                        Type = NotificationType.LowBalance,
                        Priority = currentBalance <= 1 ? 3 : 2
                    };

                    var specificLog = NotificationLog.FromRequest(logRequest, userId, response);
                    specificLog.Type = $"LowBalance_{currentBalance}"; // Override type for specific threshold tracking
                    await _notificationRepository.AddNotificationLogAsync(specificLog, cancellationToken);
                }

                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending low balance alert to user {UserId}", userId);
                return NotificationResponse.Failed($"Error sending low balance alert: {ex.Message}", NotificationChannel.Push);
            }
        }

        public async Task<NotificationResponse> SendEmailNotificationAsync(Guid userId, EmailNotificationRequest request, CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("Sending email notification to user {UserId}", userId);

                var response = await _emailProvider.SendAsync(request, cancellationToken);

                // Log the notification
                var log = NotificationLog.FromRequest(request, userId, response);
                await _notificationRepository.AddNotificationLogAsync(log, cancellationToken);

                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending email notification to user {UserId}", userId);
                return NotificationResponse.Failed($"Error sending email: {ex.Message}", NotificationChannel.Email);
            }
        }

        public async Task<NotificationResponse> SendPushNotificationAsync(Guid userId, PushNotificationRequest request, CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("Sending push notification to user {UserId}", userId);

                // Check quiet hours for push notifications
                if (await IsWithinQuietHoursAsync(cancellationToken))
                {
                    _logger.LogInformation("Skipping push notification due to quiet hours for user {UserId}", userId);
                    return NotificationResponse.Failed("Notification skipped due to quiet hours", NotificationChannel.Push);
                }

                var response = await _pushProvider.SendAsync(request, cancellationToken);

                // Log the notification
                var log = NotificationLog.FromRequest(request, userId, response);
                await _notificationRepository.AddNotificationLogAsync(log, cancellationToken);

                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending push notification to user {UserId}", userId);
                return NotificationResponse.Failed($"Error sending push notification: {ex.Message}", NotificationChannel.Push);
            }
        }

        public async Task<NotificationResponse> SendNotificationAsync(Guid userId, NotificationRequest request, CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("Sending notification to user {UserId}, Type: {Type}", userId, request.Type);

                // Determine best channel for notification based on user preferences and notification type
                var channel = await DetermineOptimalChannelAsync(userId, request.Type, cancellationToken);

                NotificationResponse response;

                switch (channel)
                {
                    case NotificationChannel.Push:
                        // Get user device token from preferences
                        var userPreferences = await _preferencesService.GetOrCreateUserPreferencesAsync(userId, cancellationToken);
                        if (string.IsNullOrEmpty(userPreferences.DeviceToken))
                        {
                            _logger.LogWarning("No device token found for user {UserId}, cannot send push notification", userId);
                            return NotificationResponse.Failed("No device token available for push notification", NotificationChannel.Push);
                        }

                        // Convert to push notification request
                        var pushRequest = new PushNotificationRequest
                        {
                            DeviceToken = userPreferences.DeviceToken,
                            Title = request.Subject,
                            Message = request.Message,
                            Type = request.Type,
                            Priority = request.Priority,
                            Data = request.Data,
                            CustomData = new Dictionary<string, string>()
                        };

                        // Add custom data as strings
                        if (request.Data?.Any() == true)
                        {
                            foreach (var item in request.Data)
                            {
                                pushRequest.CustomData[item.Key] = JsonSerializer.Serialize(item.Value);
                            }
                        }

                        response = await SendPushNotificationAsync(userId, pushRequest, cancellationToken);
                        break;

                    case NotificationChannel.Email:
                        // Convert to email notification request
                        var emailRequest = new EmailNotificationRequest
                        {
                            Email = request.Recipient,
                            Recipient = request.Recipient,
                            Subject = request.Subject,
                            Message = request.Message,
                            Type = request.Type,
                            Priority = request.Priority,
                            Data = request.Data
                        };

                        response = await SendEmailNotificationAsync(userId, emailRequest, cancellationToken);
                        break;

                    default:
                        response = NotificationResponse.Failed("No suitable notification channel available", NotificationChannel.Push);
                        break;
                }

                // Implement retry logic for failed notifications
                if (!response.Success && _options.DefaultRetryAttempts > 0)
                {
                    _logger.LogWarning("Notification failed, will be retried. User: {UserId}, Error: {Error}", userId, response.Error);
                    // The retry will be handled by a background service
                }

                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending notification to user {UserId}", userId);
                return NotificationResponse.Failed($"Error sending notification: {ex.Message}", NotificationChannel.Push);
            }
        }

        public async Task<List<NotificationLog>> GetUserNotificationHistoryAsync(Guid userId, int page = 1, int pageSize = 50, CancellationToken cancellationToken = default)
        {
            try
            {
                return await _notificationRepository.GetUserNotificationHistoryAsync(userId, page, pageSize, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving notification history for user {UserId}", userId);
                throw;
            }
        }

        public async Task<bool> RetryFailedNotificationsAsync(int maxRetries = 3, CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("Starting retry of failed notifications");

                var failedNotifications = await _notificationRepository.GetFailedNotificationsAsync(maxRetries, DateTime.UtcNow.AddHours(-24), cancellationToken);

                if (!failedNotifications.Any())
                {
                    _logger.LogInformation("No failed notifications to retry");
                    return true;
                }

                var successCount = 0;

                foreach (var failedLog in failedNotifications)
                {
                    try
                    {
                        // Recreate the original request from the log
                        var request = new NotificationRequest
                        {
                            Recipient = failedLog.Recipient,
                            Subject = failedLog.Subject,
                            Message = failedLog.Message,
                            Type = Enum.Parse<NotificationType>(failedLog.Type),
                            Data = failedLog.Metadata
                        };

                        // Retry the notification
                        var retryResponse = await SendNotificationAsync(failedLog.UserId, request, cancellationToken);

                        // Update retry count
                        var newRetryCount = (failedLog.RetryCount ?? 0) + 1;
                        await _notificationRepository.UpdateRetryCountAsync(
                            failedLog.Id,
                            newRetryCount,
                            retryResponse.Success ? null : retryResponse.Error,
                            cancellationToken);

                        if (retryResponse.Success)
                        {
                            successCount++;
                            _logger.LogInformation("Successfully retried notification {LogId} for user {UserId}", failedLog.Id, failedLog.UserId);
                        }
                        else
                        {
                            _logger.LogWarning("Retry failed for notification {LogId} for user {UserId}. Attempt: {RetryCount}", failedLog.Id, failedLog.UserId, newRetryCount);
                        }

                        // Add delay between retries to avoid overwhelming external services
                        await Task.Delay(TimeSpan.FromSeconds(_options.RetryDelaySeconds), cancellationToken);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error retrying notification {LogId}", failedLog.Id);
                    }
                }

                _logger.LogInformation("Retry completed. {SuccessCount}/{TotalCount} notifications succeeded", successCount, failedNotifications.Count);
                return successCount > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during notification retry process");
                return false;
            }
        }

        public Task<bool> IsWithinQuietHoursAsync(CancellationToken cancellationToken = default)
        {
            try
            {
                var now = DateTime.Now.TimeOfDay;
                var startTime = TimeSpan.Parse(_options.QuietHours.Start);
                var endTime = TimeSpan.Parse(_options.QuietHours.End);

                // Handle quiet hours that span midnight
                if (startTime > endTime)
                {
                    return Task.FromResult(now >= startTime || now <= endTime);
                }
                else
                {
                    return Task.FromResult(now >= startTime && now <= endTime);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking quiet hours, defaulting to false");
                return Task.FromResult(false);
            }
        }

        private async Task<NotificationChannel> DetermineOptimalChannelAsync(Guid userId, NotificationType type, CancellationToken cancellationToken)
        {
            try
            {
                // Get user preferences to determine preferred channel
                var userPreferences = await _preferencesService.GetOrCreateUserPreferencesAsync(userId, cancellationToken);

                switch (type)
                {
                    case NotificationType.LowBalance:
                        // Check user preferences for low balance notifications
                        if (userPreferences.EnablePush && _pushProvider.IsHealthy() && !string.IsNullOrEmpty(userPreferences.DeviceToken))
                        {
                            // Check if it's quiet hours for push notifications
                            if (!userPreferences.IsQuietHour())
                            {
                                return NotificationChannel.Push;
                            }
                        }
                        // Fall back to email if push is not available or it's quiet hours
                        if (userPreferences.EnableEmail)
                        {
                            return NotificationChannel.Email;
                        }
                        break;

                    case NotificationType.Payment:
                        // For payments, prefer email for record-keeping but respect user preferences
                        if (userPreferences.EnablePayment)
                        {
                            if (userPreferences.EnableEmail)
                            {
                                return NotificationChannel.Email;
                            }
                            else if (userPreferences.EnablePush && _pushProvider.IsHealthy() && !string.IsNullOrEmpty(userPreferences.DeviceToken))
                            {
                                return NotificationChannel.Push;
                            }
                        }
                        break;

                    case NotificationType.General:
                    default:
                        // For general notifications, check user preferences
                        if (userPreferences.EnablePush && _pushProvider.IsHealthy() && !string.IsNullOrEmpty(userPreferences.DeviceToken))
                        {
                            if (!userPreferences.IsQuietHour())
                            {
                                return NotificationChannel.Push;
                            }
                        }
                        if (userPreferences.EnableEmail)
                        {
                            return NotificationChannel.Email;
                        }
                        break;
                }

                // If no channel is available based on preferences, fall back to default logic
                _logger.LogWarning("No suitable notification channel found based on user {UserId} preferences, using fallback logic", userId);
                return _pushProvider.IsHealthy() ? NotificationChannel.Push : NotificationChannel.Email;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error determining notification channel for user {UserId}, defaulting to email", userId);
                return NotificationChannel.Email;
            }
        }
    }

    public class NotificationOptions
    {
        public const string SectionName = "Notifications";

        public bool EnablePush { get; set; } = true;
        public bool EnableEmail { get; set; } = true;
        public int DefaultRetryAttempts { get; set; } = 3;
        public int RetryDelaySeconds { get; set; } = 5;
        public QuietHoursOptions QuietHours { get; set; } = new();
        public List<int> LowBalanceThresholds { get; set; } = new() { 3, 2, 1 };
    }

    public class QuietHoursOptions
    {
        public string Start { get; set; } = "22:00";
        public string End { get; set; } = "08:00";
    }
}
