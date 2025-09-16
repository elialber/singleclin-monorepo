using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SingleClin.API.DTOs;
using System.Security.Claims;

namespace SingleClin.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public abstract class BaseController : ControllerBase
{
    private ILogger<BaseController>? _logger;
    protected ILogger<BaseController> Logger =>
        _logger ??= HttpContext.RequestServices.GetService<ILogger<BaseController>>()!;

    /// <summary>
    /// Gets the current authenticated user's ID from the JWT token
    /// </summary>
    protected string? CurrentUserId => User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

    /// <summary>
    /// Gets the current authenticated user's email from the JWT token
    /// </summary>
    protected string? CurrentUserEmail => User.FindFirst(ClaimTypes.Email)?.Value;

    /// <summary>
    /// Gets the current authenticated user's role from the JWT token
    /// </summary>
    protected string? CurrentUserRole => User.FindFirst(ClaimTypes.Role)?.Value;

    /// <summary>
    /// Gets the current authenticated user's clinic ID from the JWT token (if applicable)
    /// </summary>
    protected string? CurrentUserClinicId => User.FindFirst("clinicId")?.Value;

    /// <summary>
    /// Checks if the current user has a specific role
    /// </summary>
    protected bool IsInRole(string role) => User.IsInRole(role);

    /// <summary>
    /// Checks if the current user is an admin
    /// </summary>
    protected bool IsAdmin => IsInRole("Admin");

    /// <summary>
    /// Checks if the current user is a clinic user (any type)
    /// </summary>
    protected bool IsClinicUser => IsInRole("Clinic") || IsInRole("ClinicOrigin") || IsInRole("ClinicPartner");

    /// <summary>
    /// Checks if the current user is a patient
    /// </summary>
    protected bool IsPatient => IsInRole("Patient");

    // Response helper methods

    /// <summary>
    /// Returns a successful response with data
    /// </summary>
    protected IActionResult OkResponse<T>(T data, string? message = null)
    {
        var response = ResponseWrapper<T>.SuccessResponse(data, message);
        return Ok(response);
    }

    /// <summary>
    /// Returns a successful response without data
    /// </summary>
    protected IActionResult OkResponse(string? message = null)
    {
        var response = ResponseWrapper.SuccessResponse(message);
        return Ok(response);
    }

    /// <summary>
    /// Returns a created response with data
    /// </summary>
    protected IActionResult CreatedResponse<T>(T data, string? message = null, string? location = null)
    {
        var response = ResponseWrapper<T>.SuccessResponse(data, message, 201);
        if (!string.IsNullOrEmpty(location))
        {
            return Created(location, response);
        }
        return StatusCode(201, response);
    }

    /// <summary>
    /// Returns a bad request response
    /// </summary>
    protected IActionResult BadRequestResponse(string message, List<string>? errors = null)
    {
        var response = ResponseWrapper.ErrorResponse(message, 400, errors);
        return BadRequest(response);
    }

    /// <summary>
    /// Returns a validation error response
    /// </summary>
    protected IActionResult ValidationErrorResponse(List<string> errors, string message = "Validation failed")
    {
        var response = ResponseWrapper.ValidationErrorResponse(errors, message);
        return UnprocessableEntity(response);
    }

    /// <summary>
    /// Returns a validation error response from ModelState
    /// </summary>
    protected IActionResult ValidationErrorResponse()
    {
        var errors = ModelState
            .Where(x => x.Value?.Errors.Count > 0)
            .SelectMany(x => x.Value!.Errors.Select(e => $"{x.Key}: {e.ErrorMessage}"))
            .ToList();

        return ValidationErrorResponse(errors);
    }

    /// <summary>
    /// Returns an unauthorized response
    /// </summary>
    protected IActionResult UnauthorizedResponse(string message = "Unauthorized access")
    {
        var response = ResponseWrapper.UnauthorizedResponse(message);
        return Unauthorized(response);
    }

    /// <summary>
    /// Returns a forbidden response
    /// </summary>
    protected IActionResult ForbiddenResponse(string message = "Access forbidden")
    {
        var response = ResponseWrapper.ForbiddenResponse(message);
        return StatusCode(403, response);
    }

    /// <summary>
    /// Returns a not found response
    /// </summary>
    protected IActionResult NotFoundResponse(string message = "Resource not found")
    {
        var response = ResponseWrapper.NotFoundResponse(message);
        return NotFound(response);
    }

    /// <summary>
    /// Returns a conflict response
    /// </summary>
    protected IActionResult ConflictResponse(string message, List<string>? errors = null)
    {
        var response = ResponseWrapper.ErrorResponse(message, 409, errors);
        return Conflict(response);
    }

    /// <summary>
    /// Returns an internal server error response
    /// </summary>
    protected IActionResult InternalServerErrorResponse(string message = "An error occurred while processing your request")
    {
        var response = ResponseWrapper.ErrorResponse(message, 500);
        Logger.LogError(message);
        return StatusCode(500, response);
    }

    /// <summary>
    /// Returns a custom status code response
    /// </summary>
    protected IActionResult CustomResponse<T>(int statusCode, T data, string? message = null)
    {
        var response = ResponseWrapper<T>.SuccessResponse(data, message, statusCode);
        return StatusCode(statusCode, response);
    }

    /// <summary>
    /// Returns a custom error response
    /// </summary>
    protected IActionResult CustomErrorResponse(int statusCode, string message, List<string>? errors = null)
    {
        var response = ResponseWrapper.ErrorResponse(message, statusCode, errors);
        return StatusCode(statusCode, response);
    }

    /// <summary>
    /// Gets the user role from claims
    /// </summary>
    protected string? GetUserRole()
    {
        return User.FindFirst("role")?.Value ?? User.FindFirst(ClaimTypes.Role)?.Value;
    }

    /// <summary>
    /// Gets model state errors as a list of strings
    /// </summary>
    protected List<string> GetModelStateErrors()
    {
        return ModelState
            .Where(x => x.Value?.Errors.Count > 0)
            .SelectMany(x => x.Value!.Errors.Select(e => $"{x.Key}: {e.ErrorMessage}"))
            .ToList();
    }

    /// <summary>
    /// Gets the user's clinic ID as a Guid
    /// </summary>
    protected Guid? GetUserClinicId()
    {
        var clinicIdString = User.FindFirst("clinicId")?.Value;
        if (Guid.TryParse(clinicIdString, out var clinicId))
        {
            return clinicId;
        }
        return null;
    }
}