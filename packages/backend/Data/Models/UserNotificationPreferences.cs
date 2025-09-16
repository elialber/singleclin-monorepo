using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.Data.Models
{
    public class UserNotificationPreferences
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public Guid UserId { get; set; }

        /// <summary>
        /// Whether the user wants to receive push notifications
        /// </summary>
        public bool EnablePush { get; set; } = true;

        /// <summary>
        /// Whether the user wants to receive email notifications
        /// </summary>
        public bool EnableEmail { get; set; } = true;

        /// <summary>
        /// Threshold for low balance notifications (in credits remaining)
        /// Valid range: 1-5 credits
        /// </summary>
        [Range(1, 5, ErrorMessage = "Threshold must be between 1 and 5 credits")]
        public int LowBalanceThreshold { get; set; } = 3;

        /// <summary>
        /// Preferred language for notifications (ISO 639-1 code)
        /// </summary>
        [MaxLength(5)]
        public string PreferredLanguage { get; set; } = "pt-BR";

        /// <summary>
        /// Whether to receive promotional notifications
        /// </summary>
        public bool EnablePromotional { get; set; } = true;

        /// <summary>
        /// Whether to receive payment-related notifications
        /// </summary>
        public bool EnablePayment { get; set; } = true;

        /// <summary>
        /// Custom quiet hours start time (24-hour format, e.g., "22:00")
        /// If null, uses system default
        /// </summary>
        [MaxLength(5)]
        public string? QuietHoursStart { get; set; }

        /// <summary>
        /// Custom quiet hours end time (24-hour format, e.g., "08:00")
        /// If null, uses system default
        /// </summary>
        [MaxLength(5)]
        public string? QuietHoursEnd { get; set; }

        /// <summary>
        /// Device token for push notifications (FCM token)
        /// </summary>
        [MaxLength(500)]
        public string? DeviceToken { get; set; }

        /// <summary>
        /// Device platform (iOS, Android, Web)
        /// </summary>
        [MaxLength(20)]
        public string? DevicePlatform { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public virtual ApplicationUser User { get; set; } = null!;

        // Helper methods
        public bool IsQuietHour(DateTime? time = null)
        {
            var checkTime = time ?? DateTime.Now;

            // Use custom quiet hours if set, otherwise return false (let system handle it)
            if (string.IsNullOrEmpty(QuietHoursStart) || string.IsNullOrEmpty(QuietHoursEnd))
                return false;

            try
            {
                var currentTime = checkTime.TimeOfDay;
                var startTime = TimeSpan.Parse(QuietHoursStart);
                var endTime = TimeSpan.Parse(QuietHoursEnd);

                // Handle quiet hours that span midnight
                if (startTime > endTime)
                {
                    return currentTime >= startTime || currentTime <= endTime;
                }
                else
                {
                    return currentTime >= startTime && currentTime <= endTime;
                }
            }
            catch
            {
                return false;
            }
        }

        public bool ShouldReceiveNotification(string notificationType, bool isPushNotification)
        {
            return notificationType.ToLower() switch
            {
                "lowbalance" => isPushNotification ? EnablePush : EnableEmail,
                "payment" => EnablePayment && (isPushNotification ? EnablePush : EnableEmail),
                "promotional" => EnablePromotional && (isPushNotification ? EnablePush : EnableEmail),
                _ => isPushNotification ? EnablePush : EnableEmail
            };
        }

        public static UserNotificationPreferences CreateDefault(Guid userId)
        {
            return new UserNotificationPreferences
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                EnablePush = true,
                EnableEmail = true,
                LowBalanceThreshold = 3,
                PreferredLanguage = "pt-BR",
                EnablePromotional = true,
                EnablePayment = true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
        }
    }
}