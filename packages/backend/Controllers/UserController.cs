using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SingleClin.API.DTOs;
using SingleClin.API.DTOs.Common;
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
}