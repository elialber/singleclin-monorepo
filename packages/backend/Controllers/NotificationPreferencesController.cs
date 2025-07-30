using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SingleClin.API.DTOs.NotificationPreferences;
using SingleClin.API.DTOs;
using SingleClin.API.Services;
using System.Security.Claims;

namespace SingleClin.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class NotificationPreferencesController : ControllerBase
    {
        private readonly INotificationPreferencesService _preferencesService;
        private readonly ILogger<NotificationPreferencesController> _logger;

        public NotificationPreferencesController(
            INotificationPreferencesService preferencesService,
            ILogger<NotificationPreferencesController> logger)
        {
            _preferencesService = preferencesService;
            _logger = logger;
        }

        /// <summary>
        /// Get current user's notification preferences
        /// </summary>
        /// <returns>User's notification preferences</returns>
        [HttpGet]
        public async Task<ActionResult<ResponseWrapper<NotificationPreferencesResponseDto>>> GetPreferences()
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null)
                {
                    return Unauthorized(ResponseWrapper<NotificationPreferencesResponseDto>.UnauthorizedResponse(
                        "User not authenticated"));
                }

                _logger.LogInformation("Getting notification preferences for user {UserId}", userId);

                var preferences = await _preferencesService.GetUserPreferencesAsync(userId.Value);

                return Ok(ResponseWrapper<NotificationPreferencesResponseDto>.SuccessResponse(
                    preferences, "Notification preferences retrieved successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting notification preferences");
                return StatusCode(500, ResponseWrapper<NotificationPreferencesResponseDto>.ErrorResponse(
                    "Internal server error", 500));
            }
        }

        /// <summary>
        /// Get notification preferences for a specific user (Admin only)
        /// </summary>
        /// <param name="userId">User ID</param>
        /// <returns>User's notification preferences</returns>
        [HttpGet("{userId}")]
        [Authorize(Policy = "RequireAdminRole")]
        public async Task<ActionResult<ResponseWrapper<NotificationPreferencesResponseDto>>> GetUserPreferences(Guid userId)
        {
            try
            {
                _logger.LogInformation("Admin getting notification preferences for user {UserId}", userId);

                var preferences = await _preferencesService.GetUserPreferencesAsync(userId);

                return Ok(ResponseWrapper<NotificationPreferencesResponseDto>.SuccessResponse(
                    preferences, "Notification preferences retrieved successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting notification preferences for user {UserId}", userId);
                return StatusCode(500, ResponseWrapper<NotificationPreferencesResponseDto>.ErrorResponse(
                    "Internal server error", 500));
            }
        }

        /// <summary>
        /// Update current user's notification preferences
        /// </summary>
        /// <param name="preferences">Updated notification preferences</param>
        /// <returns>Updated notification preferences</returns>
        [HttpPut]
        public async Task<ActionResult<ResponseWrapper<NotificationPreferencesResponseDto>>> UpdatePreferences(
            [FromBody] NotificationPreferencesDto preferences)
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null)
                {
                    return Unauthorized(ResponseWrapper<NotificationPreferencesResponseDto>.UnauthorizedResponse(
                        "User not authenticated"));
                }

                if (!ModelState.IsValid)
                {
                    var errors = ModelState.Values
                        .SelectMany(v => v.Errors)
                        .Select(e => e.ErrorMessage)
                        .ToList();
                    
                    return BadRequest(ResponseWrapper<NotificationPreferencesResponseDto>.ErrorResponse(
                        $"Validation failed: {string.Join(", ", errors)}", 400));
                }

                _logger.LogInformation("Updating notification preferences for user {UserId}", userId);

                var updatedPreferences = await _preferencesService.UpdateUserPreferencesAsync(userId.Value, preferences);

                return Ok(ResponseWrapper<NotificationPreferencesResponseDto>.SuccessResponse(
                    updatedPreferences, "Notification preferences updated successfully"));
            }
            catch (ArgumentException ex)
            {
                _logger.LogWarning(ex, "Invalid argument when updating notification preferences");
                return BadRequest(ResponseWrapper<NotificationPreferencesResponseDto>.ErrorResponse(
                    ex.Message, 400));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating notification preferences");
                return StatusCode(500, ResponseWrapper<NotificationPreferencesResponseDto>.ErrorResponse(
                    "Internal server error", 500));
            }
        }

        /// <summary>
        /// Update notification preferences for a specific user (Admin only)
        /// </summary>
        /// <param name="userId">User ID</param>
        /// <param name="preferences">Updated notification preferences</param>
        /// <returns>Updated notification preferences</returns>
        [HttpPut("{userId}")]
        [Authorize(Policy = "RequireAdminRole")]
        public async Task<ActionResult<ResponseWrapper<NotificationPreferencesResponseDto>>> UpdateUserPreferences(
            Guid userId, [FromBody] NotificationPreferencesDto preferences)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    var errors = ModelState.Values
                        .SelectMany(v => v.Errors)
                        .Select(e => e.ErrorMessage)
                        .ToList();
                    
                    return BadRequest(ResponseWrapper<NotificationPreferencesResponseDto>.ErrorResponse(
                        $"Validation failed: {string.Join(", ", errors)}", 400));
                }

                _logger.LogInformation("Admin updating notification preferences for user {UserId}", userId);

                var updatedPreferences = await _preferencesService.UpdateUserPreferencesAsync(userId, preferences);

                return Ok(ResponseWrapper<NotificationPreferencesResponseDto>.SuccessResponse(
                    updatedPreferences, "Notification preferences updated successfully"));
            }
            catch (ArgumentException ex)
            {
                _logger.LogWarning(ex, "Invalid argument when updating notification preferences for user {UserId}", userId);
                return BadRequest(ResponseWrapper<NotificationPreferencesResponseDto>.ErrorResponse(
                    ex.Message, 400));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating notification preferences for user {UserId}", userId);
                return StatusCode(500, ResponseWrapper<NotificationPreferencesResponseDto>.ErrorResponse(
                    "Internal server error", 500));
            }
        }

        /// <summary>
        /// Update device token for push notifications
        /// </summary>
        /// <param name="deviceTokenDto">Device token and platform information</param>
        /// <returns>Success confirmation</returns>
        [HttpPost("device-token")]
        public async Task<ActionResult<ResponseWrapper<bool>>> UpdateDeviceToken(
            [FromBody] UpdateDeviceTokenDto deviceTokenDto)
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null)
                {
                    return Unauthorized(ResponseWrapper<bool>.UnauthorizedResponse(
                        "User not authenticated"));
                }

                if (!ModelState.IsValid)
                {
                    var errors = ModelState.Values
                        .SelectMany(v => v.Errors)
                        .Select(e => e.ErrorMessage)
                        .ToList();
                    
                    return BadRequest(ResponseWrapper<bool>.ErrorResponse(
                        $"Validation failed: {string.Join(", ", errors)}", 400));
                }

                _logger.LogInformation("Updating device token for user {UserId}, platform: {Platform}", 
                    userId, deviceTokenDto.DevicePlatform);

                var result = await _preferencesService.UpdateDeviceTokenAsync(
                    userId.Value, deviceTokenDto.DeviceToken, deviceTokenDto.DevicePlatform);

                if (result)
                {
                    return Ok(ResponseWrapper<bool>.SuccessResponse(
                        true, "Device token updated successfully"));
                }
                else
                {
                    return StatusCode(500, ResponseWrapper<bool>.ErrorResponse(
                        "Failed to update device token", 500));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating device token");
                return StatusCode(500, ResponseWrapper<bool>.ErrorResponse(
                    "Internal server error", 500));
            }
        }

        /// <summary>
        /// Update device token for a specific user (Admin only)
        /// </summary>
        /// <param name="userId">User ID</param>
        /// <param name="deviceTokenDto">Device token and platform information</param>
        /// <returns>Success confirmation</returns>
        [HttpPost("{userId}/device-token")]
        [Authorize(Policy = "RequireAdminRole")]
        public async Task<ActionResult<ResponseWrapper<bool>>> UpdateUserDeviceToken(
            Guid userId, [FromBody] UpdateDeviceTokenDto deviceTokenDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    var errors = ModelState.Values
                        .SelectMany(v => v.Errors)
                        .Select(e => e.ErrorMessage)
                        .ToList();
                    
                    return BadRequest(ResponseWrapper<bool>.ErrorResponse(
                        $"Validation failed: {string.Join(", ", errors)}", 400));
                }

                _logger.LogInformation("Admin updating device token for user {UserId}, platform: {Platform}", 
                    userId, deviceTokenDto.DevicePlatform);

                var result = await _preferencesService.UpdateDeviceTokenAsync(
                    userId, deviceTokenDto.DeviceToken, deviceTokenDto.DevicePlatform);

                if (result)
                {
                    return Ok(ResponseWrapper<bool>.SuccessResponse(
                        true, "Device token updated successfully"));
                }
                else
                {
                    return StatusCode(500, ResponseWrapper<bool>.ErrorResponse(
                        "Failed to update device token", 500));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating device token for user {UserId}", userId);
                return StatusCode(500, ResponseWrapper<bool>.ErrorResponse(
                    "Internal server error", 500));
            }
        }

        private Guid? GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (Guid.TryParse(userIdClaim, out var userId))
            {
                return userId;
            }
            return null;
        }
    }
}