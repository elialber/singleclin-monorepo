using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;
using SingleClin.API.DTOs;

namespace SingleClin.API.Controllers;

/// <summary>
/// Test controller to demonstrate BaseController and ResponseWrapper functionality
/// </summary>
[ApiController]
[Route("api/[controller]")]
[SwaggerTag("Test endpoints for demonstrating API response patterns")]
public class TestResponseController : BaseController
{
    /// <summary>
    /// Test successful response with data
    /// </summary>
    /// <response code="200">Returns the test data wrapped in a successful response</response>
    [HttpGet("success-with-data")]
    [AllowAnonymous]
    [SwaggerOperation(
        Summary = "Get test data with success response",
        Description = "Returns a test object wrapped in ResponseWrapper with success status",
        OperationId = "GetTestDataSuccess"
    )]
    [SwaggerResponse(200, "Success", typeof(ResponseWrapper<object>))]
    public IActionResult GetSuccessWithData()
    {
        var data = new
        {
            id = 1,
            name = "Test Item",
            description = "This is a test item"
        };

        return OkResponse(data, "Data retrieved successfully");
    }

    /// <summary>
    /// Test successful response without data
    /// </summary>
    [HttpGet("success-no-data")]
    [AllowAnonymous]
    public IActionResult GetSuccessNoData()
    {
        return OkResponse("Operation completed successfully");
    }

    /// <summary>
    /// Test created response
    /// </summary>
    /// <param name="request">The item creation request</param>
    /// <response code="201">Returns the created item</response>
    /// <response code="422">If the request validation fails</response>
    [HttpPost("create")]
    [AllowAnonymous]
    [SwaggerOperation(
        Summary = "Create a test item",
        Description = "Creates a new test item and returns it with a 201 Created status",
        OperationId = "CreateTestItem"
    )]
    [SwaggerResponse(201, "Created successfully", typeof(ResponseWrapper<object>))]
    [SwaggerResponse(422, "Validation failed", typeof(ResponseWrapper))]
    public IActionResult CreateItem([FromBody] CreateItemRequest request)
    {
        if (!ModelState.IsValid)
        {
            return ValidationErrorResponse();
        }

        var createdItem = new
        {
            id = 123,
            name = request.Name,
            createdAt = DateTime.UtcNow
        };

        return CreatedResponse(createdItem, "Item created successfully", $"/api/testresponse/{createdItem.id}");
    }

    /// <summary>
    /// Test validation error response
    /// </summary>
    [HttpPost("validation-error")]
    [AllowAnonymous]
    public IActionResult TestValidationError()
    {
        var errors = new List<string>
        {
            "Name is required",
            "Email format is invalid",
            "Age must be between 18 and 100"
        };

        return ValidationErrorResponse(errors);
    }

    /// <summary>
    /// Test not found response
    /// </summary>
    [HttpGet("not-found/{id}")]
    [AllowAnonymous]
    public IActionResult GetNotFound(int id)
    {
        return NotFoundResponse($"Item with ID {id} was not found");
    }

    /// <summary>
    /// Test unauthorized response (requires authentication)
    /// </summary>
    [HttpGet("user-info")]
    public IActionResult GetUserInfo()
    {
        if (string.IsNullOrEmpty(CurrentUserId))
        {
            return UnauthorizedResponse("User is not authenticated");
        }

        var userInfo = new
        {
            userId = CurrentUserId,
            email = CurrentUserEmail,
            role = CurrentUserRole,
            clinicId = CurrentUserClinicId,
            isAdmin = IsAdmin,
            isClinicUser = IsClinicUser,
            isPatient = IsPatient
        };

        return OkResponse(userInfo, "User information retrieved successfully");
    }

    /// <summary>
    /// Test forbidden response
    /// </summary>
    [HttpPost("admin-only")]
    public IActionResult AdminOnlyAction()
    {
        if (!IsAdmin)
        {
            return ForbiddenResponse("This action requires admin privileges");
        }

        return OkResponse("Admin action completed successfully");
    }

    /// <summary>
    /// Test exception handling
    /// </summary>
    [HttpGet("throw-exception")]
    [AllowAnonymous]
    public IActionResult ThrowException()
    {
        throw new InvalidOperationException("This is a test exception to demonstrate global error handling");
    }

    /// <summary>
    /// Test conflict response
    /// </summary>
    [HttpPost("conflict")]
    [AllowAnonymous]
    public IActionResult TestConflict()
    {
        return ConflictResponse("A resource with this name already exists", 
            new List<string> { "Duplicate name detected" });
    }
}

/// <summary>
/// Request model for creating a test item
/// </summary>
public class CreateItemRequest
{
    /// <summary>
    /// The name of the item (required)
    /// </summary>
    /// <example>Test Item 1</example>
    [SwaggerSchema("The name of the item", Nullable = false)]
    public string Name { get; set; } = string.Empty;
    
    /// <summary>
    /// Optional description of the item
    /// </summary>
    /// <example>This is a test item description</example>
    [SwaggerSchema("Optional description of the item", Nullable = true)]
    public string? Description { get; set; }
}