using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Services;
using SingleClin.API.Data.Models;

namespace SingleClin.API.Jobs
{
    /// <summary>
    /// Background job that checks user balances and sends notifications for low balance thresholds
    /// </summary>
    public class BalanceCheckJob
    {
        private readonly ILogger<BalanceCheckJob> _logger;
        private readonly ApplicationDbContext _context;
        private readonly INotificationService _notificationService;
        private readonly INotificationPreferencesService _preferencesService;

        public BalanceCheckJob(
            ILogger<BalanceCheckJob> logger,
            ApplicationDbContext context,
            INotificationService notificationService,
            INotificationPreferencesService preferencesService)
        {
            _logger = logger;
            _context = context;
            _notificationService = notificationService;
            _preferencesService = preferencesService;
        }

        /// <summary>
        /// Executes the balance check job
        /// </summary>
        public async Task ExecuteAsync()
        {
            try
            {
                _logger.LogInformation("Balance check job is temporarily disabled due to database schema issues");
                // TODO: Re-enable after fixing User.ApplicationUserId column mapping issue
                return;

                /*
                _logger.LogInformation("Starting balance check job execution at {Timestamp}", DateTime.UtcNow);

                // Get all active user plans with remaining credits
                var userPlansWithLowBalance = await GetUserPlansWithLowBalanceAsync();

                _logger.LogInformation("Found {Count} user plans with low balance", userPlansWithLowBalance.Count);

                var notificationsSent = 0;
                var notificationsSkipped = 0;

                foreach (var userPlan in userPlansWithLowBalance)
                {
                    try
                    {
                        // Get user preferences to check if they want low balance notifications
                        var userPreferences = await _preferencesService.GetOrCreateUserPreferencesAsync(userPlan.UserId);
                        
                        // Check if user's current balance qualifies for notification based on their threshold
                        if (userPlan.CreditsRemaining > userPreferences.LowBalanceThreshold)
                        {
                            _logger.LogDebug("User {UserId} balance {Balance} is above their threshold {Threshold}. Skipping notification.", 
                                userPlan.UserId, userPlan.CreditsRemaining, userPreferences.LowBalanceThreshold);
                            notificationsSkipped++;
                            continue;
                        }

                        // Check if user was already notified for this specific balance level
                        var wasRecentlyNotified = await WasRecentlyNotifiedAsync(userPlan.UserId, userPlan.CreditsRemaining);
                        if (wasRecentlyNotified)
                        {
                            _logger.LogDebug("User {UserId} was recently notified for balance {Balance}. Skipping.", 
                                userPlan.UserId, userPlan.CreditsRemaining);
                            notificationsSkipped++;
                            continue;
                        }

                        // Get user and plan information for notification
                        var user = await _context.Users.FindAsync(userPlan.UserId);
                        var plan = await _context.Plans.FindAsync(userPlan.PlanId);

                        if (user == null || plan == null)
                        {
                            _logger.LogWarning("User {UserId} or Plan {PlanId} not found. Skipping notification.", 
                                userPlan.UserId, userPlan.PlanId);
                            continue;
                        }

                        // Send low balance notification
                        var notificationResult = await _notificationService.SendLowBalanceAlertAsync(
                            userPlan.UserId, 
                            userPlan.CreditsRemaining, 
                            plan.Name);

                        if (notificationResult.Success)
                        {
                            notificationsSent++;
                            _logger.LogInformation("Successfully sent low balance notification to user {UserId} for {Credits} credits", 
                                userPlan.UserId, userPlan.CreditsRemaining);
                        }
                        else
                        {
                            _logger.LogWarning("Failed to send low balance notification to user {UserId}: {Error}", 
                                userPlan.UserId, notificationResult.Error);
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error processing low balance notification for user {UserId}", userPlan.UserId);
                    }

                    // Add small delay between notifications to avoid overwhelming services
                    await Task.Delay(TimeSpan.FromMilliseconds(100));
                }

                _logger.LogInformation("Balance check job completed. Notifications sent: {Sent}, skipped: {Skipped}", 
                    notificationsSent, notificationsSkipped);
                */
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error executing balance check job");
                throw;
            }
        }

        /// <summary>
        /// Gets user plans with low balance that may qualify for notifications
        /// </summary>
        private async Task<List<UserPlan>> GetUserPlansWithLowBalanceAsync()
        {
            try
            {
                // Get all active user plans with remaining credits <= 5 (maximum threshold)
                var lowBalanceUserPlans = await _context.UserPlans
                    .Where(up => up.CreditsRemaining <= 5 &&
                                up.CreditsRemaining > 0 &&
                                up.IsActive)
                    .Include(up => up.User)
                    .Include(up => up.Plan)
                    .Where(up => up.User != null && up.Plan != null)
                    .ToListAsync();

                return lowBalanceUserPlans;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving user plans with low balance");
                throw;
            }
        }

        /// <summary>
        /// Checks if user was recently notified for a specific balance level to prevent spam
        /// </summary>
        private async Task<bool> WasRecentlyNotifiedAsync(Guid userId, int balanceLevel)
        {
            try
            {
                // Check if there's a recent notification log for this specific balance level
                var cutoffTime = DateTime.UtcNow.AddHours(-4); // Same as job frequency
                var specificNotificationType = $"LowBalance_{balanceLevel}";

                var recentNotification = await _context.NotificationLogs
                    .Where(nl => nl.UserId == userId &&
                                nl.Type == specificNotificationType &&
                                nl.SentAt >= cutoffTime &&
                                nl.IsSuccess)
                    .AnyAsync();

                return recentNotification;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking recent notifications for user {UserId}, balance {Balance}", userId, balanceLevel);
                // If we can't check, err on the side of not sending to avoid spam
                return true;
            }
        }

        /// <summary>
        /// Gets comprehensive statistics about the balance check job execution
        /// </summary>
        public async Task<BalanceCheckJobStats> GetStatsAsync()
        {
            try
            {
                var stats = new BalanceCheckJobStats();

                // Get total active user plans
                stats.TotalActiveUserPlans = await _context.UserPlans
                    .Where(up => up.IsActive && up.CreditsRemaining > 0)
                    .CountAsync();

                // Get user plans by balance level
                for (int balance = 1; balance <= 5; balance++)
                {
                    var count = await _context.UserPlans
                        .Where(up => up.IsActive && up.CreditsRemaining == balance)
                        .CountAsync();

                    stats.UserPlansByBalance[balance] = count;
                }

                // Get notification statistics for the last 24 hours
                var last24Hours = DateTime.UtcNow.AddHours(-24);
                stats.NotificationsSentLast24h = await _context.NotificationLogs
                    .Where(nl => nl.Type.StartsWith("LowBalance_") &&
                                nl.SentAt >= last24Hours &&
                                nl.IsSuccess)
                    .CountAsync();

                stats.NotificationsFailedLast24h = await _context.NotificationLogs
                    .Where(nl => nl.Type.StartsWith("LowBalance_") &&
                                nl.SentAt >= last24Hours &&
                                !nl.IsSuccess)
                    .CountAsync();

                return stats;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving balance check job statistics");
                throw;
            }
        }
    }

    /// <summary>
    /// Statistics for balance check job execution
    /// </summary>
    public class BalanceCheckJobStats
    {
        public int TotalActiveUserPlans { get; set; }
        public Dictionary<int, int> UserPlansByBalance { get; set; } = new();
        public int NotificationsSentLast24h { get; set; }
        public int NotificationsFailedLast24h { get; set; }
        public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;
    }
}