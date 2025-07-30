using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using SingleClin.API.DTOs.Notification;
using Microsoft.Extensions.Options;
using System.Text.Json;

namespace SingleClin.API.Services
{
    public class FcmProvider : IPushNotificationProvider
    {
        private readonly FcmOptions _options;
        private readonly ILogger<FcmProvider> _logger;
        private readonly FirebaseMessaging _messaging;

        public NotificationChannel Channel => NotificationChannel.Push;

        public FcmProvider(IOptions<FcmOptions> options, ILogger<FcmProvider> logger)
        {
            _options = options.Value;
            _logger = logger;
            
            if (FirebaseApp.DefaultInstance == null)
            {
                _logger.LogWarning("Firebase app not initialized. FCM provider will not be functional.");
                _messaging = null!;
            }
            else
            {
                _messaging = FirebaseMessaging.DefaultInstance;
            }
        }

        public async Task<NotificationResponse> SendAsync(NotificationRequest request, CancellationToken cancellationToken = default)
        {
            if (request is not PushNotificationRequest pushRequest)
            {
                return NotificationResponse.Failed(
                    "Invalid request type for push notification", 
                    Channel
                );
            }

            return await SendPushAsync(pushRequest, cancellationToken);
        }

        public async Task<NotificationResponse> SendPushAsync(PushNotificationRequest request, CancellationToken cancellationToken = default)
        {
            try
            {
                if (_messaging == null)
                {
                    _logger.LogError("Firebase messaging is not initialized");
                    return NotificationResponse.Failed("Firebase messaging not initialized", Channel);
                }

                var message = BuildMessage(request);
                
                _logger.LogInformation("Sending push notification to device: {DeviceToken}", 
                    MaskDeviceToken(request.DeviceToken));

                var messageId = await _messaging.SendAsync(message, cancellationToken);

                _logger.LogInformation("Push notification sent successfully. MessageId: {MessageId}", messageId);

                var metadata = new Dictionary<string, object>
                {
                    ["deviceToken"] = MaskDeviceToken(request.DeviceToken),
                    ["notificationType"] = request.Type.ToString(),
                    ["priority"] = request.Priority
                };

                return NotificationResponse.Successful(messageId, Channel, metadata);
            }
            catch (FirebaseMessagingException ex)
            {
                _logger.LogError(ex, "Firebase messaging error: {Error}", ex.Message);
                
                // Handle specific Firebase errors  
                var errorMessage = ex.ErrorCode.ToString() switch
                {
                    "InvalidArgument" => "Invalid device token or message format",
                    "Unregistered" => "Device token is no longer valid", 
                    "SenderIdMismatch" => "Invalid sender ID configuration",
                    "QuotaExceeded" => "Message quota exceeded",
                    "Unavailable" => "FCM service temporarily unavailable",
                    _ => $"Firebase messaging error: {ex.Message}"
                };

                return NotificationResponse.Failed(errorMessage, Channel, new Dictionary<string, object>
                {
                    ["errorCode"] = ex.ErrorCode.ToString(),
                    ["deviceToken"] = MaskDeviceToken(request.DeviceToken)
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error sending push notification");
                return NotificationResponse.Failed($"Unexpected error: {ex.Message}", Channel);
            }
        }

        public bool IsHealthy()
        {
            try
            {
                return _messaging != null && FirebaseApp.DefaultInstance != null;
            }
            catch
            {
                return false;
            }
        }

        private Message BuildMessage(PushNotificationRequest request)
        {
            var messageBuilder = new Message()
            {
                Token = request.DeviceToken,
                Notification = new FirebaseAdmin.Messaging.Notification
                {
                    Title = request.Title ?? request.Subject,
                    Body = request.Message,
                    ImageUrl = request.Icon
                },
                Android = new AndroidConfig
                {
                    Priority = request.Priority >= 2 ? Priority.High : Priority.Normal,
                    Notification = new AndroidNotification
                    {
                        Title = request.Title ?? request.Subject,
                        Body = request.Message,
                        Icon = request.Icon,
                        Sound = request.Sound,
                        ClickAction = request.ClickAction
                    }
                },
                Apns = new ApnsConfig
                {
                    Aps = new Aps
                    {
                        Alert = new ApsAlert
                        {
                            Title = request.Title ?? request.Subject,
                            Body = request.Message
                        },
                        Sound = request.Sound,
                        Badge = 1
                    }
                }
            };

            // Add custom data
            if (request.CustomData?.Any() == true || request.Data?.Any() == true)
            {
                var data = new Dictionary<string, string>();
                
                // Add custom data
                if (request.CustomData?.Any() == true)
                {
                    foreach (var item in request.CustomData)
                    {
                        data[item.Key] = item.Value;
                    }
                }
                
                // Add general data (convert to strings)
                if (request.Data?.Any() == true)
                {
                    foreach (var item in request.Data)
                    {
                        data[$"data_{item.Key}"] = JsonSerializer.Serialize(item.Value);
                    }
                }

                messageBuilder.Data = data;
            }

            return messageBuilder;
        }

        private static string MaskDeviceToken(string deviceToken)
        {
            if (string.IsNullOrEmpty(deviceToken) || deviceToken.Length < 10)
                return "***";
            
            return $"{deviceToken[..4]}...{deviceToken[^4..]}";
        }
    }

    public class FcmOptions
    {
        public const string SectionName = "Firebase:CloudMessaging";
        
        public string? ServerKey { get; set; }
        public string? SenderId { get; set; }
        public bool EnableLogging { get; set; } = true;
        public int TimeoutSeconds { get; set; } = 30;
    }
}