namespace SingleClin.API.DTOs.Notification
{
    public class NotificationResponse
    {
        public bool Success { get; set; }
        
        public string? MessageId { get; set; }
        
        public string? Error { get; set; }
        
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
        
        public NotificationChannel Channel { get; set; }
        
        public Dictionary<string, object>? Metadata { get; set; }
        
        public static NotificationResponse Successful(string messageId, NotificationChannel channel, Dictionary<string, object>? metadata = null)
        {
            return new NotificationResponse
            {
                Success = true,
                MessageId = messageId,
                Channel = channel,
                Metadata = metadata
            };
        }
        
        public static NotificationResponse Failed(string error, NotificationChannel channel, Dictionary<string, object>? metadata = null)
        {
            return new NotificationResponse
            {
                Success = false,
                Error = error,
                Channel = channel,
                Metadata = metadata
            };
        }
    }

    public enum NotificationChannel
    {
        Push = 0,
        Email = 1,
        SMS = 2
    }
}