using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SingleClin.API.DTOs;
using SingleClin.API.DTOs.Common;
using SingleClin.API.DTOs.Plan;
using SingleClin.API.DTOs.User;
using SingleClin.API.Services;

namespace SingleClin.API.Controllers;

[ApiController]
[Route("api/[controller]s")]
[Authorize]
public class UserController : BaseController
{
    private readonly IUserService _userService;
    private readonly ILogger<UserController> _logger;

    public UserController(
        IUserService userService,
        ILogger<UserController> logger)
    {
        _userService = userService;
        _logger = logger;
    }

    /// <summary>
    /// Get paginated list of users with filtering and sorting
    /// </summary>
    [HttpGet]
    [Authorize(Roles = "Administrator,ClinicOrigin,ClinicPartner")]
    public async Task<ActionResult<UserListResponseDto>> GetUsers(
        [FromQuery] UserFilterDto filter)
    {
        try
        {
            var result = await _userService.GetUsersAsync(filter);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting users");
            return StatusCode(500, new { message = "An error occurred while retrieving users" });
        }
    }

    /// <summary>
    /// Get user by ID
    /// </summary>
    [HttpGet("{id}")]
    [Authorize(Roles = "Administrator,ClinicOrigin,ClinicPartner")]
    public async Task<ActionResult<ResponseWrapper<UserResponseDto>>> GetUser(Guid id)
    {
        try
        {
            var user = await _userService.GetUserByIdAsync(id);
            if (user == null)
            {
                return NotFound(new { message = "User not found" });
            }

            // Check if user can access this user's data
            var currentUserId = Guid.Parse(CurrentUserId ?? throw new UnauthorizedAccessException());
            var isAdmin = User.IsInRole("Administrator");

            if (!await _userService.CanAccessUserAsync(id, currentUserId, isAdmin))
            {
                return Forbid();
            }

            return Ok(new ResponseWrapper<UserResponseDto>
            {
                Data = user,
                Success = true
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting user {UserId}", id);
            return StatusCode(500, new { message = "An error occurred while retrieving the user" });
        }
    }

    /// <summary>
    /// Create new user
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "Administrator,ClinicOrigin")]
    public async Task<ActionResult<ResponseWrapper<UserResponseDto>>> CreateUser(
        [FromBody] CreateUserDto dto)
    {
        try
        {
            // Validate clinic access if clinic ID is provided
            if (dto.ClinicId.HasValue)
            {
                var currentUserId = Guid.Parse(CurrentUserId ?? throw new UnauthorizedAccessException());
                var isAdmin = User.IsInRole("Administrator");

                if (!await _userService.CanAccessClinicAsync(dto.ClinicId.Value, currentUserId, isAdmin))
                {
                    return Forbid();
                }
            }

            var result = await _userService.CreateUserAsync(dto);

            if (!result.Success)
            {
                return BadRequest(new
                {
                    message = "Failed to create user",
                    errors = result.Errors
                });
            }

            // Send confirmation email after successful user creation
            try
            {
                await _userService.SendUserConfirmationEmailAsync(Guid.Parse(result.User!.Id), dto.Password!);
                _logger.LogInformation("Confirmation email sent to user {UserId}", result.User.Id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send confirmation email to user {UserId}", result.User.Id);
                // Don't fail the user creation if email fails - user is already created
            }

            return CreatedAtAction(
                nameof(GetUser),
                new { id = result.User!.Id },
                new ResponseWrapper<UserResponseDto>
                {
                    Data = result.User,
                    Success = true
                });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating user");
            return StatusCode(500, new { message = "An error occurred while creating the user" });
        }
    }

    /// <summary>
    /// Update user
    /// </summary>
    [HttpPut("{id}")]
    [Authorize(Roles = "Administrator,ClinicOrigin,ClinicPartner")]
    public async Task<ActionResult<ResponseWrapper<UserResponseDto>>> UpdateUser(
        Guid id,
        [FromBody] UpdateUserDto dto)
    {
        try
        {
            var currentUserId = Guid.Parse(CurrentUserId ?? throw new UnauthorizedAccessException());
            var isAdmin = User.IsInRole("Administrator");

            if (!await _userService.CanAccessUserAsync(id, currentUserId, isAdmin))
            {
                return Forbid();
            }

            // Only administrators can change roles
            if (!string.IsNullOrWhiteSpace(dto.Role) && !isAdmin)
            {
                dto.Role = null;
            }

            // Validate clinic access if clinic ID is provided
            if (dto.ClinicId.HasValue && !await _userService.CanAccessClinicAsync(dto.ClinicId.Value, currentUserId, isAdmin))
            {
                return Forbid();
            }

            var result = await _userService.UpdateUserAsync(id, dto);

            if (!result.Success)
            {
                if (result.Errors.Any(e => e.Contains("not found", StringComparison.OrdinalIgnoreCase)))
                {
                    return NotFound(new { message = "User not found" });
                }

                return BadRequest(new
                {
                    message = "Failed to update user",
                    errors = result.Errors
                });
            }

            return Ok(new ResponseWrapper<UserResponseDto>
            {
                Data = result.User,
                Success = true
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating user");
            return StatusCode(500, new { message = "An error occurred while updating the user" });
        }
    }

    /// <summary>
    /// Delete user
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize(Roles = "Administrator")]
    public async Task<IActionResult> DeleteUser(Guid id)
    {
        try
        {
            var result = await _userService.DeleteUserAsync(id);

            if (!result.Success)
            {
                if (result.Errors.Any(e => e.Contains("not found", StringComparison.OrdinalIgnoreCase)))
                {
                    return NotFound(new { message = "User not found" });
                }

                return BadRequest(new
                {
                    message = "Failed to delete user",
                    errors = result.Errors
                });
            }

            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting user");
            return StatusCode(500, new { message = "An error occurred while deleting the user" });
        }
    }

    /// <summary>
    /// Reset user password
    /// </summary>
    [HttpPost("{id}/reset-password")]
    [Authorize(Roles = "Administrator,ClinicOrigin")]
    public async Task<IActionResult> ResetPassword(Guid id)
    {
        try
        {
            var currentUserId = Guid.Parse(CurrentUserId ?? throw new UnauthorizedAccessException());
            var isAdmin = User.IsInRole("Administrator");

            if (!await _userService.CanAccessUserAsync(id, currentUserId, isAdmin))
            {
                return Forbid();
            }

            var result = await _userService.SendPasswordResetEmailAsync(id);

            if (!result.Success)
            {
                if (result.Message.Contains("not found", StringComparison.OrdinalIgnoreCase))
                {
                    return NotFound(new { message = result.Message });
                }

                return BadRequest(new { message = result.Message });
            }

            return Ok(new { message = result.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error resetting password");
            return StatusCode(500, new { message = "An error occurred while resetting the password" });
        }
    }

    /// <summary>
    /// Toggle user active status
    /// </summary>
    [HttpPatch("{id}/status")]
    [Authorize(Roles = "Administrator,ClinicOrigin")]
    public async Task<ActionResult<ResponseWrapper<UserResponseDto>>> ToggleStatus(
        Guid id,
        [FromBody] ToggleStatusDto dto)
    {
        try
        {
            var currentUserId = Guid.Parse(CurrentUserId ?? throw new UnauthorizedAccessException());
            var isAdmin = User.IsInRole("Administrator");

            if (!await _userService.CanAccessUserAsync(id, currentUserId, isAdmin))
            {
                return Forbid();
            }

            var result = await _userService.ToggleUserStatusAsync(id, dto.IsActive);

            if (!result.Success)
            {
                if (result.Errors.Any(e => e.Contains("not found", StringComparison.OrdinalIgnoreCase)))
                {
                    return NotFound(new { message = "User not found" });
                }

                return BadRequest(new
                {
                    message = "Failed to update user status",
                    errors = result.Errors
                });
            }

            return Ok(new ResponseWrapper<UserResponseDto>
            {
                Data = result.User,
                Success = true
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error toggling user status");
            return StatusCode(500, new { message = "An error occurred while updating user status" });
        }
    }

    /// <summary>
    /// Purchase a plan for a user
    /// </summary>
    [HttpPost("{id}/purchase-plan")]
    [Authorize(Roles = "Administrator,Patient")]
    public async Task<ActionResult<ResponseWrapper<UserPlanResponseDto>>> PurchasePlan(
        Guid id,
        [FromBody] PurchasePlanDto purchaseDto)
    {
        try
        {
            var currentUserId = Guid.Parse(CurrentUserId ?? throw new UnauthorizedAccessException());
            var isAdmin = User.IsInRole("Administrator");

            // Users can only purchase plans for themselves, admins can purchase for anyone
            if (!isAdmin && currentUserId != id)
            {
                return Forbid();
            }

            var result = await _userService.PurchasePlanAsync(id, purchaseDto);

            if (!result.Success)
            {
                return BadRequest(new ResponseWrapper<UserPlanResponseDto>
                {
                    Success = false,
                    Message = "Failed to purchase plan",
                    Errors = result.Errors.ToList()
                });
            }

            return Ok(new ResponseWrapper<UserPlanResponseDto>
            {
                Data = result.UserPlan,
                Success = true,
                Message = "Plan purchased successfully"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error purchasing plan for user {UserId}", id);
            return StatusCode(500, new { message = "An error occurred while purchasing the plan" });
        }
    }

    /// <summary>
    /// Get user's active plans
    /// </summary>
    [HttpGet("{id}/plans")]
    [Authorize(Roles = "Administrator,Patient")]
    public async Task<ActionResult<ResponseWrapper<IEnumerable<UserPlanResponseDto>>>> GetUserPlans(Guid id)
    {
        try
        {
            var currentUserId = Guid.Parse(CurrentUserId ?? throw new UnauthorizedAccessException());
            var isAdmin = User.IsInRole("Administrator");

            // Users can only view their own plans, admins can view anyone's
            if (!isAdmin && currentUserId != id)
            {
                return Forbid();
            }

            var userPlans = await _userService.GetUserPlansAsync(id);

            return Ok(new ResponseWrapper<IEnumerable<UserPlanResponseDto>>
            {
                Data = userPlans,
                Success = true,
                Message = $"Found {userPlans.Count()} active plans"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting plans for user {UserId}", id);
            return StatusCode(500, new { message = "An error occurred while retrieving user plans" });
        }
    }

    /// <summary>
    /// Get specific user plan by ID
    /// </summary>
    [HttpGet("{id}/plans/{planId}")]
    [Authorize(Roles = "Administrator,Patient")]
    public async Task<ActionResult<ResponseWrapper<UserPlanResponseDto>>> GetUserPlan(Guid id, Guid planId)
    {
        try
        {
            var currentUserId = Guid.Parse(CurrentUserId ?? throw new UnauthorizedAccessException());
            var isAdmin = User.IsInRole("Administrator");

            // Users can only view their own plans, admins can view anyone's
            if (!isAdmin && currentUserId != id)
            {
                return Forbid();
            }

            var userPlan = await _userService.GetUserPlanAsync(id, planId);

            if (userPlan == null)
            {
                return NotFound(new ResponseWrapper<UserPlanResponseDto>
                {
                    Success = false,
                    Message = "User plan not found"
                });
            }

            return Ok(new ResponseWrapper<UserPlanResponseDto>
            {
                Data = userPlan,
                Success = true
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting plan {PlanId} for user {UserId}", planId, id);
            return StatusCode(500, new { message = "An error occurred while retrieving the user plan" });
        }
    }

    /// <summary>
    /// Get user's total available credits
    /// </summary>
    [HttpGet("{id}/credits")]
    [AllowAnonymous] // Allow anonymous access for mobile app
    public async Task<ActionResult<object>> GetUserCredits(string id)
    {
        try
        {
            _logger.LogInformation("Getting credits for user: {UserId}", id);

            // For Firebase UIDs (like ATp3HykPuYMosiLapAKP6QEsB622), return mock credits for now
            // In production, this would need to map Firebase UID to internal User ID
            if (!Guid.TryParse(id, out var userId))
            {
                _logger.LogInformation("Non-GUID user ID detected (likely Firebase UID): {UserId}", id);
                // Return mock credits for Firebase users
                return Ok(new { credits = 100 });
            }

            var userPlans = await _userService.GetUserPlansAsync(userId);
            var totalCredits = userPlans.Sum(up => up.CreditsRemaining);

            _logger.LogInformation("Found {TotalCredits} credits for user {UserId}", totalCredits, id);

            return Ok(new { credits = totalCredits });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting credits for user {UserId}", id);
            return StatusCode(500, new { message = "An error occurred while retrieving user credits" });
        }
    }

    /// <summary>
    /// Consume credits for a service (mock endpoint for testing)
    /// </summary>
    [HttpPost("{id}/credits/consume")]
    [AllowAnonymous] // Allow anonymous access for mobile app  
    public async Task<ActionResult<object>> ConsumeCredits(string id, [FromBody] ConsumeCreditsRequest request)
    {
        try
        {
            _logger.LogInformation("Consuming {Amount} credits for user {UserId} for service {ServiceId}",
                request.Amount, id, request.ServiceId);

            // For now, just return success - this would need proper implementation
            // with transaction creation and credit deduction

            return Ok(new { success = true, message = "Credits consumed successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error consuming credits for user {UserId}", id);
            return StatusCode(500, new { message = "An error occurred while consuming credits" });
        }
    }

    /// <summary>
    /// Cancel/Remove a user's plan
    /// </summary>
    [HttpDelete("{id}/plans/{userPlanId}")]
    [Authorize(Roles = "Administrator")]
    public async Task<ActionResult<ResponseWrapper<object>>> CancelUserPlan(Guid id, Guid userPlanId, [FromBody] CancelPlanRequest? request = null)
    {
        try
        {
            var result = await _userService.CancelUserPlanAsync(id, userPlanId, request?.Reason);

            if (!result.Success)
            {
                if (result.Errors.Any(e => e.Contains("not found")))
                {
                    return NotFound(new { message = "User plan not found" });
                }

                return BadRequest(new
                {
                    message = "Failed to cancel user plan",
                    errors = result.Errors
                });
            }

            return Ok(new ResponseWrapper<object>
            {
                Success = true,
                Message = "User plan cancelled successfully"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error cancelling plan {UserPlanId} for user {UserId}", userPlanId, id);
            return StatusCode(500, new { message = "An error occurred while cancelling the user plan" });
        }
    }
}

/// <summary>
/// Request model for cancelling a user plan
/// </summary>
public class CancelPlanRequest
{
    /// <summary>
    /// Reason for cancelling the plan
    /// </summary>
    public string? Reason { get; set; }
}

/// <summary>
/// Request model for consuming credits
/// </summary>
public class ConsumeCreditsRequest
{
    /// <summary>
    /// ID of the service being booked
    /// </summary>
    public string ServiceId { get; set; } = string.Empty;

    /// <summary>
    /// Amount of credits to consume
    /// </summary>
    public double Amount { get; set; }
}