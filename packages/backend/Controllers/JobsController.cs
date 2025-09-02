using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SingleClin.API.DTOs;
using SingleClin.API.Jobs;
using Hangfire;

namespace SingleClin.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Policy = "RequireAdministratorRole")]
    public class JobsController : ControllerBase
    {
        private readonly ILogger<JobsController> _logger;
        private readonly BalanceCheckJob _balanceCheckJob;
        private readonly IBackgroundJobClient _backgroundJobClient;
        private readonly IRecurringJobManager _recurringJobManager;

        public JobsController(
            ILogger<JobsController> logger,
            BalanceCheckJob balanceCheckJob,
            IBackgroundJobClient backgroundJobClient,
            IRecurringJobManager recurringJobManager)
        {
            _logger = logger;
            _balanceCheckJob = balanceCheckJob;
            _backgroundJobClient = backgroundJobClient;
            _recurringJobManager = recurringJobManager;
        }

        /// <summary>
        /// Manually trigger balance check job (Admin only)
        /// </summary>
        /// <returns>Job execution result</returns>
        [HttpPost("balance-check/trigger")]
        public ActionResult<ResponseWrapper<object>> TriggerBalanceCheckJob()
        {
            try
            {
                _logger.LogInformation("Admin manually triggering balance check job");

                // Execute job immediately in background
                var jobId = _backgroundJobClient.Enqueue<BalanceCheckJob>("notifications", job => job.ExecuteAsync());

                return Ok(ResponseWrapper<object>.SuccessResponse(
                    new { jobId, status = "queued", message = "Balance check job queued for execution" },
                    "Balance check job has been queued successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error triggering balance check job");
                return StatusCode(500, ResponseWrapper<object>.ErrorResponse(
                    "Failed to trigger balance check job", 500));
            }
        }

        /// <summary>
        /// Execute balance check job synchronously for testing (Admin only)
        /// </summary>
        /// <returns>Job execution result with statistics</returns>
        [HttpPost("balance-check/execute")]
        public async Task<ActionResult<ResponseWrapper<object>>> ExecuteBalanceCheckJob()
        {
            try
            {
                _logger.LogInformation("Admin executing balance check job synchronously");

                var startTime = DateTime.UtcNow;
                
                // Execute job synchronously
                await _balanceCheckJob.ExecuteAsync();
                
                var endTime = DateTime.UtcNow;
                var duration = endTime - startTime;

                // Get job statistics
                var stats = await _balanceCheckJob.GetStatsAsync();

                var result = new
                {
                    executedAt = startTime,
                    duration = duration.TotalSeconds,
                    statistics = stats
                };

                return Ok(ResponseWrapper<object>.SuccessResponse(
                    result, "Balance check job executed successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error executing balance check job");
                return StatusCode(500, ResponseWrapper<object>.ErrorResponse(
                    $"Failed to execute balance check job: {ex.Message}", 500));
            }
        }

        /// <summary>
        /// Get balance check job statistics (Admin only)
        /// </summary>
        /// <returns>Job statistics</returns>
        [HttpGet("balance-check/stats")]
        public async Task<ActionResult<ResponseWrapper<BalanceCheckJobStats>>> GetBalanceCheckJobStats()
        {
            try
            {
                _logger.LogInformation("Getting balance check job statistics");

                var stats = await _balanceCheckJob.GetStatsAsync();

                return Ok(ResponseWrapper<BalanceCheckJobStats>.SuccessResponse(
                    stats, "Balance check job statistics retrieved successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting balance check job statistics");
                return StatusCode(500, ResponseWrapper<BalanceCheckJobStats>.ErrorResponse(
                    "Failed to retrieve job statistics", 500));
            }
        }

        /// <summary>
        /// Update balance check job schedule (Admin only)
        /// </summary>
        /// <param name="cronExpression">New cron expression for job scheduling</param>
        /// <returns>Update result</returns>
        [HttpPut("balance-check/schedule")]
        public ActionResult<ResponseWrapper<object>> UpdateBalanceCheckJobSchedule([FromBody] string cronExpression)
        {
            try
            {
                _logger.LogInformation("Admin updating balance check job schedule to: {CronExpression}", cronExpression);

                // Validate cron expression (basic validation)
                if (string.IsNullOrWhiteSpace(cronExpression))
                {
                    return BadRequest(ResponseWrapper<object>.ErrorResponse(
                        "Cron expression cannot be empty", 400));
                }

                // Update recurring job schedule
                _recurringJobManager.AddOrUpdate<BalanceCheckJob>(
                    "balance-check-job",
                    job => job.ExecuteAsync(),
                    cronExpression,
                    TimeZoneInfo.Local);

                return Ok(ResponseWrapper<object>.SuccessResponse(
                    new { cronExpression, updatedAt = DateTime.UtcNow },
                    "Balance check job schedule updated successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating balance check job schedule");
                return StatusCode(500, ResponseWrapper<object>.ErrorResponse(
                    $"Failed to update job schedule: {ex.Message}", 500));
            }
        }

        /// <summary>
        /// Disable balance check job (Admin only)
        /// </summary>
        /// <returns>Disable result</returns>
        [HttpDelete("balance-check/disable")]
        public ActionResult<ResponseWrapper<object>> DisableBalanceCheckJob()
        {
            try
            {
                _logger.LogInformation("Admin disabling balance check job");

                // Remove recurring job
                _recurringJobManager.RemoveIfExists("balance-check-job");

                return Ok(ResponseWrapper<object>.SuccessResponse(
                    new { disabledAt = DateTime.UtcNow },
                    "Balance check job has been disabled"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error disabling balance check job");
                return StatusCode(500, ResponseWrapper<object>.ErrorResponse(
                    $"Failed to disable job: {ex.Message}", 500));
            }
        }

        /// <summary>
        /// Re-enable balance check job with default schedule (Admin only)
        /// </summary>
        /// <returns>Enable result</returns>
        [HttpPost("balance-check/enable")]
        public ActionResult<ResponseWrapper<object>> EnableBalanceCheckJob()
        {
            try
            {
                _logger.LogInformation("Admin enabling balance check job with default schedule");

                // Add recurring job with default schedule (every 4 hours)
                _recurringJobManager.AddOrUpdate<BalanceCheckJob>(
                    "balance-check-job",
                    job => job.ExecuteAsync(),
                    "0 */4 * * *", // Every 4 hours at minute 0
                    TimeZoneInfo.Local);

                return Ok(ResponseWrapper<object>.SuccessResponse(
                    new { cronExpression = "0 */4 * * *", enabledAt = DateTime.UtcNow },
                    "Balance check job has been enabled with default schedule"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error enabling balance check job");
                return StatusCode(500, ResponseWrapper<object>.ErrorResponse(
                    $"Failed to enable job: {ex.Message}", 500));
            }
        }
    }
}