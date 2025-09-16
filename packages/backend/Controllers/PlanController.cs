using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SingleClin.API.Services;
using SingleClin.API.DTOs.Plan;
using SingleClin.API.DTOs.Common;
using Swashbuckle.AspNetCore.Annotations;
using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.Controllers;

/// <summary>
/// Controller for managing subscription plans (Admin Only)
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "RequireAdministratorRole")]
[SwaggerTag("Plan management endpoints for administrators")]
public class PlanController : ControllerBase
{
    private readonly IPlanService _planService;
    private readonly ILogger<PlanController> _logger;

    public PlanController(IPlanService planService, ILogger<PlanController> logger)
    {
        _planService = planService;
        _logger = logger;
    }

    /// <summary>
    /// Get all plans with pagination and filtering
    /// </summary>
    /// <param name="filter">Filter criteria including pagination, search, price range, credits range, featured status, and sorting</param>
    /// <returns>Paginated list of plans</returns>
    /// <response code="200">Returns the paginated list of plans</response>
    /// <response code="400">Invalid filter parameters</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    /// <example>
    /// GET /api/plan?pageNumber=1&amp;pageSize=10&amp;isActive=true&amp;searchTerm=premium&amp;minPrice=50&amp;maxPrice=200&amp;isFeatured=true&amp;sortBy=price&amp;sortDirection=desc
    /// </example>
    [HttpGet]
    [SwaggerOperation(
        Summary = "Get all plans with advanced filtering",
        Description = @"Retrieve all plans with comprehensive filtering, pagination, and sorting options. Admin role required.
        
**Available sort fields:** name, price, credits, validitydays, createdat, updatedat, isfeatured, isactive, displayorder
        
**Filter examples:**
- Get active plans: `?isActive=true`
- Search by name: `?searchTerm=premium`
- Price range: `?minPrice=50&maxPrice=200`
- Featured plans: `?isFeatured=true`
- Sort by price desc: `?sortBy=price&sortDirection=desc`",
        OperationId = "GetPlans"
    )]
    [SwaggerResponse(200, "Success", typeof(PagedResultDto<PlanResponseDto>))]
    [SwaggerResponse(400, "Bad Request - Invalid filter parameters")]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    public async Task<ActionResult<PagedResultDto<PlanResponseDto>>> GetAll([FromQuery] PlanFilterDto filter)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _planService.GetAllAsync(filter);

            _logger.LogInformation(
                "Retrieved {Count} plans (page {PageNumber} of {TotalPages})",
                result.ItemCount,
                result.PageNumber,
                result.TotalPages
            );

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving plans with filter: {@Filter}", filter);
            return StatusCode(500, new { message = "An error occurred while retrieving plans" });
        }
    }

    /// <summary>
    /// Get active plans (no admin authorization required)
    /// </summary>
    /// <returns>List of active plans</returns>
    /// <response code="200">Returns list of active plans</response>
    [HttpGet("active")]
    [AllowAnonymous]
    [SwaggerOperation(
        Summary = "Get active plans",
        Description = "Retrieve all active plans. No authentication required - used for public plan display.",
        OperationId = "GetActivePlans"
    )]
    [SwaggerResponse(200, "Success", typeof(IEnumerable<PlanResponseDto>))]
    public async Task<ActionResult<IEnumerable<PlanResponseDto>>> GetActive()
    {
        try
        {
            var result = await _planService.GetActiveAsync();

            _logger.LogInformation("Retrieved {Count} active plans", result.Count());

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving active plans");
            return StatusCode(500, new { message = "An error occurred while retrieving active plans" });
        }
    }

    /// <summary>
    /// Get plan by ID
    /// </summary>
    /// <param name="id">Plan ID</param>
    /// <returns>Plan details</returns>
    /// <response code="200">Returns the plan</response>
    /// <response code="400">Invalid plan ID format</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    /// <response code="404">Plan not found</response>
    [HttpGet("{id:guid}")]
    [SwaggerOperation(
        Summary = "Get plan by ID",
        Description = "Retrieve a specific plan by its unique identifier. Admin role required.",
        OperationId = "GetPlanById"
    )]
    [SwaggerResponse(200, "Success", typeof(PlanResponseDto))]
    [SwaggerResponse(400, "Bad Request - Invalid ID format")]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    [SwaggerResponse(404, "Plan not found")]
    public async Task<ActionResult<PlanResponseDto>> GetById([FromRoute] Guid id)
    {
        try
        {
            var plan = await _planService.GetByIdAsync(id);

            if (plan == null)
            {
                _logger.LogWarning("Plan not found: {PlanId}", id);
                return NotFound(new { message = $"Plan with ID {id} not found" });
            }

            _logger.LogInformation("Retrieved plan: {PlanName} (ID: {PlanId})", plan.Name, plan.Id);

            return Ok(plan);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving plan with ID: {PlanId}", id);
            return StatusCode(500, new { message = "An error occurred while retrieving the plan" });
        }
    }

    /// <summary>
    /// Create a new plan
    /// </summary>
    /// <param name="planRequest">Plan creation data with validation rules</param>
    /// <returns>Created plan</returns>
    /// <response code="201">Plan created successfully</response>
    /// <response code="400">Invalid plan data or validation errors</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    /// <response code="409">Plan name already exists</response>
    /// <example>
    /// POST /api/plan
    /// {
    ///   "name": "Premium Plan",
    ///   "description": "Premium subscription with enhanced features",
    ///   "credits": 1000,
    ///   "price": 99.99,
    ///   "originalPrice": 149.99,
    ///   "validityDays": 365,
    ///   "isActive": true,
    ///   "displayOrder": 1,
    ///   "isFeatured": true
    /// }
    /// </example>
    [HttpPost]
    [SwaggerOperation(
        Summary = "Create a new subscription plan",
        Description = @"Create a new subscription plan with comprehensive validation. Admin role required.
        
**Validation Rules:**
- Name: Required, 1-100 characters, alphanumeric with spaces/hyphens/dots only
- Description: Optional, max 500 characters  
- Credits: Required, 1-10,000
- Price: Required, ≥0, max 2 decimal places, ≤999,999.99
- OriginalPrice: Optional, if provided must be > price
- ValidityDays: Required, 1-3650 days (max 10 years)
- DisplayOrder: Optional, 0-999
- Featured plans must have price > 0
- Inactive plans cannot be featured",
        OperationId = "CreatePlan"
    )]
    [SwaggerResponse(201, "Plan created successfully", typeof(PlanResponseDto))]
    [SwaggerResponse(400, "Bad Request - Validation errors")]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    [SwaggerResponse(409, "Conflict - Plan name already exists")]
    public async Task<ActionResult<PlanResponseDto>> Create([FromBody] PlanRequestDto planRequest)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var createdPlan = await _planService.CreateAsync(planRequest);

            _logger.LogInformation(
                "Plan created successfully: {PlanName} (ID: {PlanId}) by user {UserId}",
                createdPlan.Name,
                createdPlan.Id,
                User.Identity?.Name
            );

            return CreatedAtAction(
                nameof(GetById),
                new { id = createdPlan.Id },
                createdPlan
            );
        }
        catch (InvalidOperationException ex) when (ex.Message.Contains("already exists"))
        {
            _logger.LogWarning("Attempted to create plan with duplicate name: {PlanName}", planRequest.Name);
            return Conflict(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning("Plan creation validation failed: {ValidationErrors}", ex.Message);
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating plan: {@PlanRequest}", planRequest);
            return StatusCode(500, new { message = "An error occurred while creating the plan" });
        }
    }

    /// <summary>
    /// Update an existing plan
    /// </summary>
    /// <param name="id">Plan ID</param>
    /// <param name="planRequest">Updated plan data</param>
    /// <returns>Updated plan</returns>
    /// <response code="200">Plan updated successfully</response>
    /// <response code="400">Invalid plan data or validation errors</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    /// <response code="404">Plan not found</response>
    /// <response code="409">Plan name already exists</response>
    [HttpPut("{id:guid}")]
    [SwaggerOperation(
        Summary = "Update an existing plan",
        Description = "Update a subscription plan. Plan names must be unique. Admin role required.",
        OperationId = "UpdatePlan"
    )]
    [SwaggerResponse(200, "Plan updated successfully", typeof(PlanResponseDto))]
    [SwaggerResponse(400, "Bad Request - Validation errors")]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    [SwaggerResponse(404, "Plan not found")]
    [SwaggerResponse(409, "Conflict - Plan name already exists")]
    public async Task<ActionResult<PlanResponseDto>> Update([FromRoute] Guid id, [FromBody] PlanRequestDto planRequest)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var updatedPlan = await _planService.UpdateAsync(id, planRequest);

            _logger.LogInformation(
                "Plan updated successfully: {PlanName} (ID: {PlanId}) by user {UserId}",
                updatedPlan.Name,
                updatedPlan.Id,
                User.Identity?.Name
            );

            return Ok(updatedPlan);
        }
        catch (InvalidOperationException ex) when (ex.Message.Contains("not found"))
        {
            _logger.LogWarning("Attempted to update non-existent plan: {PlanId}", id);
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex) when (ex.Message.Contains("already exists"))
        {
            _logger.LogWarning("Attempted to update plan with duplicate name: {PlanName}", planRequest.Name);
            return Conflict(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning("Plan update validation failed: {ValidationErrors}", ex.Message);
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating plan {PlanId}: {@PlanRequest}", id, planRequest);
            return StatusCode(500, new { message = "An error occurred while updating the plan" });
        }
    }

    /// <summary>
    /// Delete a plan
    /// </summary>
    /// <param name="id">Plan ID</param>
    /// <returns>Success confirmation</returns>
    /// <response code="204">Plan deleted successfully</response>
    /// <response code="400">Invalid plan ID format</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    /// <response code="404">Plan not found</response>
    [HttpDelete("{id:guid}")]
    [SwaggerOperation(
        Summary = "Delete a plan",
        Description = "Soft delete a subscription plan (sets IsActive to false). Admin role required.",
        OperationId = "DeletePlan"
    )]
    [SwaggerResponse(204, "Plan deleted successfully")]
    [SwaggerResponse(400, "Bad Request - Invalid ID format")]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    [SwaggerResponse(404, "Plan not found")]
    public async Task<IActionResult> Delete([FromRoute] Guid id)
    {
        try
        {
            var deleted = await _planService.DeleteAsync(id);

            if (!deleted)
            {
                _logger.LogWarning("Attempted to delete non-existent plan: {PlanId}", id);
                return NotFound(new { message = $"Plan with ID {id} not found" });
            }

            _logger.LogInformation(
                "Plan deleted successfully: ID {PlanId} by user {UserId}",
                id,
                User.Identity?.Name
            );

            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting plan with ID: {PlanId}", id);
            return StatusCode(500, new { message = "An error occurred while deleting the plan" });
        }
    }

    /// <summary>
    /// Get plan statistics
    /// </summary>
    /// <returns>Plan statistics</returns>
    /// <response code="200">Returns plan statistics</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    [HttpGet("statistics")]
    [SwaggerOperation(
        Summary = "Get plan statistics",
        Description = "Retrieve statistics about plans (active, inactive counts). Admin role required.",
        OperationId = "GetPlanStatistics"
    )]
    [SwaggerResponse(200, "Success", typeof(Dictionary<string, int>))]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    public async Task<ActionResult<Dictionary<string, int>>> GetStatistics()
    {
        try
        {
            var statistics = await _planService.GetStatisticsAsync();

            _logger.LogInformation("Retrieved plan statistics: {@Statistics}", statistics);

            return Ok(statistics);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving plan statistics");
            return StatusCode(500, new { message = "An error occurred while retrieving statistics" });
        }
    }
}