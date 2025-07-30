using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.NotificationPreferences
{
    public class NotificationPreferencesDto
    {
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
        [RegularExpression(@"^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$", ErrorMessage = "Quiet hours start must be in HH:MM format")]
        public string? QuietHoursStart { get; set; }

        /// <summary>
        /// Custom quiet hours end time (24-hour format, e.g., "08:00")
        /// If null, uses system default
        /// </summary>
        [RegularExpression(@"^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$", ErrorMessage = "Quiet hours end must be in HH:MM format")]
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
    }

    public class NotificationPreferencesResponseDto : NotificationPreferencesDto
    {
        /// <summary>
        /// User ID these preferences belong to
        /// </summary>
        public Guid UserId { get; set; }

        /// <summary>
        /// When the preferences were created
        /// </summary>
        public DateTime CreatedAt { get; set; }

        /// <summary>
        /// When the preferences were last updated
        /// </summary>
        public DateTime UpdatedAt { get; set; }
    }

    public class UpdateDeviceTokenDto
    {
        /// <summary>
        /// Device token for push notifications (FCM token)
        /// </summary>
        [Required]
        [MaxLength(500)]
        public string DeviceToken { get; set; } = string.Empty;

        /// <summary>
        /// Device platform (iOS, Android, Web)
        /// </summary>
        [Required]
        [MaxLength(20)]
        public string DevicePlatform { get; set; } = string.Empty;
    }
}