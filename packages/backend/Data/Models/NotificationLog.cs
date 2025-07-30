using SingleClin.API.DTOs.Notification;
using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.Data.Models
{
    public class NotificationLog
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public Guid UserId { get; set; }

        [Required]
        [MaxLength(50)]
        public string Type { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string Channel { get; set; } = string.Empty;

        [Required]
        [MaxLength(200)]
        public string Subject { get; set; } = string.Empty;

        [Required]
        [MaxLength(1000)]
        public string Message { get; set; } = string.Empty;

        [Required]
        [MaxLength(200)]
        public string Recipient { get; set; } = string.Empty;

        public bool IsSuccess { get; set; }

        [MaxLength(500)]
        public string? ErrorMessage { get; set; }

        [MaxLength(100)]
        public string? ExternalMessageId { get; set; }

        public Dictionary<string, object>? Metadata { get; set; }

        public DateTime SentAt { get; set; } = DateTime.UtcNow;

        public int? RetryCount { get; set; } = 0;

        // Navigation properties
        public virtual ApplicationUser User { get; set; } = null!;

        // Factory methods
        public static NotificationLog FromRequest(NotificationRequest request, Guid userId, NotificationResponse response)
        {
            return new NotificationLog
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Type = request.Type.ToString(),
                Channel = response.Channel.ToString(),
                Subject = request.Subject,
                Message = request.Message,
                Recipient = request.Recipient,
                IsSuccess = response.Success,
                ErrorMessage = response.Error,
                ExternalMessageId = response.MessageId,
                Metadata = response.Metadata,
                SentAt = DateTime.UtcNow,
                RetryCount = 0
            };
        }
    }
}