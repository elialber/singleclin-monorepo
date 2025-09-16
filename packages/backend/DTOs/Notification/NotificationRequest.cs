using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.Notification
{
    public class NotificationRequest
    {
        [Required]
        public string Recipient { get; set; } = string.Empty;

        [Required]
        public string Subject { get; set; } = string.Empty;

        [Required]
        public string Message { get; set; } = string.Empty;

        public NotificationType Type { get; set; } = NotificationType.General;

        public Dictionary<string, object>? Data { get; set; }

        public int Priority { get; set; } = 1; // 1 = Normal, 2 = High, 3 = Critical
    }

    public class PushNotificationRequest : NotificationRequest
    {
        [Required]
        public string DeviceToken { get; set; } = string.Empty;

        public string? Title { get; set; }

        public string? Icon { get; set; }

        public string? Sound { get; set; } = "default";

        public string? ClickAction { get; set; }

        public Dictionary<string, string>? CustomData { get; set; }
    }

    public class EmailNotificationRequest : NotificationRequest
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        public string? HtmlContent { get; set; }

        public string? PlainTextContent { get; set; }

        public string FromEmail { get; set; } = "noreply@singleclin.com";

        public string FromName { get; set; } = "SingleClin";

        public List<string>? Attachments { get; set; }

        public Dictionary<string, string>? TemplateData { get; set; }
    }

    public enum NotificationType
    {
        General = 0,
        LowBalance = 1,
        Payment = 2,
        SystemAlert = 3,
        Marketing = 4
    }
}