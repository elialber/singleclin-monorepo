using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Data.Models;

namespace SingleClin.API.Repositories
{
    public class NotificationRepository : INotificationRepository
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<NotificationRepository> _logger;

        public NotificationRepository(ApplicationDbContext context, ILogger<NotificationRepository> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<NotificationLog> AddNotificationLogAsync(NotificationLog log, CancellationToken cancellationToken = default)
        {
            try
            {
                _context.NotificationLogs.Add(log);
                await _context.SaveChangesAsync(cancellationToken);

                _logger.LogInformation("Notification log saved. Id: {LogId}, User: {UserId}, Type: {Type}",
                    log.Id, log.UserId, log.Type);

                return log;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error saving notification log for user {UserId}", log.UserId);
                throw;
            }
        }

        public async Task<NotificationLog?> GetNotificationLogAsync(Guid id, CancellationToken cancellationToken = default)
        {
            try
            {
                return await _context.NotificationLogs
                    .Include(n => n.User)
                    .FirstOrDefaultAsync(n => n.Id == id, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving notification log {LogId}", id);
                throw;
            }
        }

        public async Task<List<NotificationLog>> GetUserNotificationHistoryAsync(Guid userId, int page = 1, int pageSize = 50, CancellationToken cancellationToken = default)
        {
            try
            {
                var skip = (page - 1) * pageSize;

                return await _context.NotificationLogs
                    .Where(n => n.UserId == userId)
                    .OrderByDescending(n => n.SentAt)
                    .Skip(skip)
                    .Take(pageSize)
                    .ToListAsync(cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving notification history for user {UserId}", userId);
                throw;
            }
        }

        public async Task<bool> HasRecentNotificationAsync(Guid userId, string type, int thresholdMinutes = 60, CancellationToken cancellationToken = default)
        {
            try
            {
                var cutoffTime = DateTime.UtcNow.AddMinutes(-thresholdMinutes);

                return await _context.NotificationLogs
                    .AnyAsync(n => n.UserId == userId
                                && n.Type == type
                                && n.IsSuccess
                                && n.SentAt >= cutoffTime, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking recent notifications for user {UserId}, type {Type}", userId, type);
                throw;
            }
        }

        public async Task<NotificationLog> UpdateRetryCountAsync(Guid logId, int retryCount, string? errorMessage = null, CancellationToken cancellationToken = default)
        {
            try
            {
                var log = await _context.NotificationLogs.FindAsync(new object[] { logId }, cancellationToken);
                if (log == null)
                {
                    throw new InvalidOperationException($"Notification log {logId} not found");
                }

                log.RetryCount = retryCount;
                if (!string.IsNullOrEmpty(errorMessage))
                {
                    log.ErrorMessage = errorMessage;
                }

                await _context.SaveChangesAsync(cancellationToken);
                return log;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating retry count for notification log {LogId}", logId);
                throw;
            }
        }

        public async Task<List<NotificationLog>> GetFailedNotificationsAsync(int maxRetries = 3, DateTime? since = null, CancellationToken cancellationToken = default)
        {
            try
            {
                var query = _context.NotificationLogs
                    .Where(n => !n.IsSuccess && (n.RetryCount ?? 0) < maxRetries);

                if (since.HasValue)
                {
                    query = query.Where(n => n.SentAt >= since.Value);
                }

                return await query
                    .OrderBy(n => n.SentAt)
                    .ToListAsync(cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving failed notifications");
                throw;
            }
        }
    }
}