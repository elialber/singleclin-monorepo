using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SingleClin.API.Services;
using SingleClin.API.DTOs.Clinic;
using SingleClin.API.DTOs.Common;
using Swashbuckle.AspNetCore.Annotations;
using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.Controllers;

/// <summary>
/// Controller for managing clinics
/// </summary>
[ApiController]
[Route("api/[controller]")]
[SwaggerTag("Clinic management endpoints")]
public class ClinicController : ControllerBase
{
    private readonly IClinicService _clinicService;
    private readonly IImageUploadService _imageUploadService;
    private readonly ILogger<ClinicController> _logger;

    public ClinicController(
        IClinicService clinicService, 
        IImageUploadService imageUploadService,
        ILogger<ClinicController> logger)
    {
        _clinicService = clinicService;
        _imageUploadService = imageUploadService;
        _logger = logger;
    }

    /// <summary>
    /// Get all clinics with pagination and filtering (Admin Only)
    /// </summary>
    /// <param name="filter">Filter criteria including pagination, search, type, status, and sorting</param>
    /// <returns>Paginated list of clinics</returns>
    /// <response code="200">Returns the paginated list of clinics</response>
    /// <response code="400">Invalid filter parameters</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    /// <example>
    /// GET /api/clinic?pageNumber=1&amp;pageSize=10&amp;isActive=true&amp;searchTerm=clinic&amp;type=Partner&amp;city=São Paulo&amp;sortBy=name&amp;sortDirection=asc
    /// </example>
    [HttpGet]
    [Authorize(Policy = "RequireAdministratorRole")]
    [SwaggerOperation(
        Summary = "Get all clinics with advanced filtering",
        Description = @"Retrieve all clinics with comprehensive filtering, pagination, and sorting options. Admin role required.
        
**Available sort fields:** name, type, createdat, updatedat, isactive, address

**Filter examples:**
- Get active clinics: `?isActive=true`
- Search by name or address: `?searchTerm=clinic`
- Filter by type: `?type=Partner`
- Filter by city: `?city=São Paulo`
- Filter by state: `?state=SP`
- Sort by type desc: `?sortBy=type&sortDirection=desc`",
        OperationId = "GetClinics"
    )]
    [SwaggerResponse(200, "Success", typeof(PagedResultDto<ClinicResponseDto>))]
    [SwaggerResponse(400, "Bad Request - Invalid filter parameters")]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    public async Task<ActionResult<PagedResultDto<ClinicResponseDto>>> GetAll([FromQuery] ClinicFilterDto filter)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _clinicService.GetAllAsync(filter);
            
            _logger.LogInformation(
                "Retrieved {Count} clinics (page {PageNumber} of {TotalPages})", 
                result.ItemCount, 
                result.PageNumber, 
                result.TotalPages
            );

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving clinics with filter: {@Filter}", filter);
            return StatusCode(500, new { message = "An error occurred while retrieving clinics" });
        }
    }

    /// <summary>
    /// Get active clinics (Public endpoint)
    /// </summary>
    /// <returns>List of active clinics</returns>
    /// <response code="200">Returns list of active clinics</response>
    /// <summary>
    /// Get all clinics (Development Only - No Auth)
    /// </summary>
    /// <param name="filter">Filter criteria</param>
    /// <returns>Paginated list of clinics</returns>
    /// <response code="200">Returns the paginated list of clinics</response>
    [HttpGet("dev")]
    [AllowAnonymous]
    [SwaggerOperation(
        Summary = "Get all clinics for development (No Auth Required)",
        Description = "Development endpoint to get all clinics without authentication. Remove in production!",
        OperationId = "GetClinicsForDev"
    )]
    public async Task<ActionResult<PagedResultDto<ClinicResponseDto>>> GetAllForDev([FromQuery] ClinicFilterDto filter)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _clinicService.GetAllAsync(filter);
            
            _logger.LogInformation(
                "[DEV] Retrieved {Count} clinics (page {PageNumber} of {TotalPages})", 
                result.ItemCount, 
                result.PageNumber, 
                result.TotalPages
            );

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[DEV] Error retrieving clinics with filter: {@Filter}", filter);
            return StatusCode(500, new { message = "An error occurred while retrieving clinics" });
        }
    }

    /// <summary>
    /// Debug Token Claims (Development Only)
    /// </summary>
    /// <returns>Current user's claims</returns>
    [HttpGet("debug-token")]
    [Authorize]
    [SwaggerOperation(
        Summary = "Debug Token Claims (DEV ONLY)",
        Description = "Shows all claims in the current JWT token for debugging authorization issues",
        OperationId = "DebugToken"
    )]
    public IActionResult DebugToken()
    {
        var claims = HttpContext.User.Claims.Select(c => new { 
            Type = c.Type, 
            Value = c.Value 
        }).ToList();

        return Ok(new {
            IsAuthenticated = HttpContext.User.Identity.IsAuthenticated,
            AuthenticationType = HttpContext.User.Identity.AuthenticationType,
            Claims = claims,
            Policies = new {
                HasAdminRole = HttpContext.User.HasClaim("role", "Administrator"),
                HasAnyRole = HttpContext.User.Claims.Any(c => c.Type == "role")
            }
        });
    }

    [HttpGet("active")]
    [AllowAnonymous]
    [SwaggerOperation(
        Summary = "Get active clinics",
        Description = "Retrieve all active clinics. No authentication required - used for public clinic display.",
        OperationId = "GetActiveClinics"
    )]
    [SwaggerResponse(200, "Success", typeof(IEnumerable<ClinicResponseDto>))]
    public async Task<ActionResult<IEnumerable<ClinicResponseDto>>> GetActive()
    {
        try
        {
            var clinics = await _clinicService.GetActiveAsync();
            
            _logger.LogInformation("Retrieved {Count} active clinics", clinics.Count());
            
            return Ok(clinics);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving active clinics");
            return StatusCode(500, new { message = "An error occurred while retrieving active clinics" });
        }
    }

    /// <summary>
    /// Get clinic by ID (Admin Only)
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <returns>Clinic details</returns>
    /// <response code="200">Returns the clinic</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    /// <response code="404">Clinic not found</response>
    [HttpGet("{id:guid}")]
    [Authorize(Policy = "RequireAdministratorRole")]
    [SwaggerOperation(
        Summary = "Get clinic by ID",
        Description = "Retrieve a specific clinic by its ID. Admin role required.",
        OperationId = "GetClinicById"
    )]
    [SwaggerResponse(200, "Success", typeof(ClinicResponseDto))]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    [SwaggerResponse(404, "Clinic not found")]
    public async Task<ActionResult<ClinicResponseDto>> GetById([Required] Guid id)
    {
        try
        {
            var clinic = await _clinicService.GetByIdAsync(id);
            
            if (clinic == null)
            {
                _logger.LogWarning("Clinic not found: {ClinicId}", id);
                return NotFound(new { message = $"Clinic with ID {id} not found" });
            }

            _logger.LogInformation("Retrieved clinic: {ClinicName} (ID: {ClinicId})", clinic.Name, clinic.Id);
            
            return Ok(clinic);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving clinic: {ClinicId}", id);
            return StatusCode(500, new { message = "An error occurred while retrieving the clinic" });
        }
    }

    /// <summary>
    /// Create a new clinic (Admin Only)
    /// </summary>
    /// <param name="clinicRequest">Clinic data</param>
    /// <returns>Created clinic</returns>
    /// <response code="201">Clinic created successfully</response>
    /// <response code="400">Invalid clinic data</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    /// <response code="409">Clinic name or CNPJ already exists</response>
    [HttpPost]
    [Authorize(Policy = "RequireAdministratorRole")]
    [SwaggerOperation(
        Summary = "Create a new clinic",
        Description = "Create a new clinic in the system. Admin role required.",
        OperationId = "CreateClinic"
    )]
    [SwaggerResponse(201, "Clinic created successfully", typeof(ClinicResponseDto))]
    [SwaggerResponse(400, "Bad Request - Invalid clinic data")]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    [SwaggerResponse(409, "Conflict - Clinic name or CNPJ already exists")]
    public async Task<ActionResult<ClinicResponseDto>> Create([FromBody] ClinicRequestDto clinicRequest)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var clinic = await _clinicService.CreateAsync(clinicRequest);
            
            _logger.LogInformation("Created new clinic: {ClinicName} (ID: {ClinicId})", clinic.Name, clinic.Id);
            
            return CreatedAtAction(
                nameof(GetById),
                new { id = clinic.Id },
                clinic
            );
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Validation failed while creating clinic: {ClinicName}", clinicRequest.Name);
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating clinic: {ClinicName}", clinicRequest.Name);
            return StatusCode(500, new { message = "An error occurred while creating the clinic" });
        }
    }

    /// <summary>
    /// Update an existing clinic (Admin Only)
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <param name="clinicRequest">Updated clinic data</param>
    /// <returns>Updated clinic</returns>
    /// <response code="200">Clinic updated successfully</response>
    /// <response code="400">Invalid clinic data</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    /// <response code="404">Clinic not found</response>
    /// <response code="409">Clinic name or CNPJ already exists</response>
    [HttpPut("{id:guid}")]
    [Authorize(Policy = "RequireAdministratorRole")]
    [SwaggerOperation(
        Summary = "Update an existing clinic",
        Description = "Update an existing clinic's information. Admin role required.",
        OperationId = "UpdateClinic"
    )]
    [SwaggerResponse(200, "Clinic updated successfully", typeof(ClinicResponseDto))]
    [SwaggerResponse(400, "Bad Request - Invalid clinic data")]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    [SwaggerResponse(404, "Clinic not found")]
    [SwaggerResponse(409, "Conflict - Clinic name or CNPJ already exists")]
    public async Task<ActionResult<ClinicResponseDto>> Update([Required] Guid id, [FromBody] ClinicRequestDto clinicRequest)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var clinic = await _clinicService.UpdateAsync(id, clinicRequest);
            
            _logger.LogInformation("Updated clinic: {ClinicName} (ID: {ClinicId})", clinic.Name, clinic.Id);
            
            return Ok(clinic);
        }
        catch (InvalidOperationException ex) when (ex.Message.Contains("not found"))
        {
            _logger.LogWarning("Clinic not found for update: {ClinicId}", id);
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Validation failed while updating clinic: {ClinicId}", id);
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating clinic: {ClinicId}", id);
            return StatusCode(500, new { message = "An error occurred while updating the clinic" });
        }
    }

    /// <summary>
    /// Delete a clinic (soft delete) (Admin Only)
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <returns>Success status</returns>
    /// <response code="204">Clinic deleted successfully</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    /// <response code="404">Clinic not found</response>
    [HttpDelete("{id:guid}")]
    [Authorize(Policy = "RequireAdministratorRole")]
    [SwaggerOperation(
        Summary = "Delete a clinic (soft delete)",
        Description = "Soft delete a clinic by setting its status to inactive. Admin role required.",
        OperationId = "DeleteClinic"
    )]
    [SwaggerResponse(204, "Clinic deleted successfully")]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    [SwaggerResponse(404, "Clinic not found")]
    public async Task<ActionResult> Delete([Required] Guid id)
    {
        try
        {
            var deleted = await _clinicService.DeleteAsync(id);
            
            if (!deleted)
            {
                _logger.LogWarning("Clinic not found for deletion: {ClinicId}", id);
                return NotFound(new { message = $"Clinic with ID {id} not found" });
            }

            _logger.LogInformation("Deleted clinic: {ClinicId}", id);
            
            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting clinic: {ClinicId}", id);
            return StatusCode(500, new { message = "An error occurred while deleting the clinic" });
        }
    }

    /// <summary>
    /// Toggle clinic active status (Admin Only)
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <returns>Updated clinic with new status</returns>
    /// <response code="200">Clinic status toggled successfully</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    /// <response code="404">Clinic not found</response>
    [HttpPatch("{id:guid}/toggle-status")]
    [Authorize(Policy = "RequireAdministratorRole")]
    [SwaggerOperation(
        Summary = "Toggle clinic active status",
        Description = "Toggle the active status of a clinic (active becomes inactive and vice versa). Admin role required.",
        OperationId = "ToggleClinicStatus"
    )]
    [SwaggerResponse(200, "Clinic status toggled successfully", typeof(ClinicResponseDto))]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    [SwaggerResponse(404, "Clinic not found")]
    public async Task<ActionResult<ClinicResponseDto>> ToggleStatus([Required] Guid id)
    {
        try
        {
            var clinic = await _clinicService.ToggleStatusAsync(id);
            
            _logger.LogInformation("Toggled status for clinic: {ClinicName} (ID: {ClinicId}) - Active: {IsActive}", 
                clinic.Name, clinic.Id, clinic.IsActive);
            
            return Ok(clinic);
        }
        catch (InvalidOperationException ex) when (ex.Message.Contains("not found"))
        {
            _logger.LogWarning("Clinic not found for status toggle: {ClinicId}", id);
            return NotFound(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error toggling clinic status: {ClinicId}", id);
            return StatusCode(500, new { message = "An error occurred while toggling clinic status" });
        }
    }

    /// <summary>
    /// Get clinic statistics (Admin Only)
    /// </summary>
    /// <returns>Clinic statistics</returns>
    /// <response code="200">Returns clinic statistics</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    [HttpGet("statistics")]
    [Authorize(Policy = "RequireAdministratorRole")]
    [SwaggerOperation(
        Summary = "Get clinic statistics",
        Description = "Get statistics about clinics including counts by status and type. Admin role required.",
        OperationId = "GetClinicStatistics"
    )]
    [SwaggerResponse(200, "Success", typeof(Dictionary<string, int>))]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    public async Task<ActionResult<Dictionary<string, int>>> GetStatistics()
    {
        try
        {
            var statistics = await _clinicService.GetStatisticsAsync();
            
            _logger.LogInformation("Retrieved clinic statistics");
            
            return Ok(statistics);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving clinic statistics");
            return StatusCode(500, new { message = "An error occurred while retrieving clinic statistics" });
        }
    }

    /// <summary>
    /// Upload clinic image (Admin Only)
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <param name="image">Image file to upload</param>
    /// <returns>Updated clinic with new image</returns>
    /// <response code="200">Image uploaded successfully</response>
    /// <response code="400">Invalid image file or clinic data</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    /// <response code="404">Clinic not found</response>
    /// <response code="413">File too large</response>
    [HttpPost("{id:guid}/image")]
    [Authorize(Policy = "RequireAdministratorRole")]
    [SwaggerOperation(
        Summary = "Upload clinic image",
        Description = @"Upload an image for a specific clinic. Admin role required.

**Supported formats:** JPEG, PNG, WebP
**Maximum file size:** 5MB
**Automatic processing:** Images are resized to max 1200x800px and optimized for web",
        OperationId = "UploadClinicImage"
    )]
    [SwaggerResponse(200, "Image uploaded successfully", typeof(ClinicResponseDto))]
    [SwaggerResponse(400, "Bad Request - Invalid image file")]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    [SwaggerResponse(404, "Clinic not found")]
    [SwaggerResponse(413, "Payload Too Large - File exceeds size limit")]
    public async Task<ActionResult<ClinicResponseDto>> UploadImage([Required] Guid id, IFormFile image)
    {
        try
        {
            // Validate image file
            if (image == null || image.Length == 0)
            {
                _logger.LogWarning("Image upload attempted with null or empty file for clinic: {ClinicId}", id);
                return BadRequest(new { message = "No image file provided" });
            }

            // Validate image using service
            if (!await _imageUploadService.ValidateImageAsync(image))
            {
                _logger.LogWarning("Invalid image file uploaded for clinic: {ClinicId}, FileName: {FileName}", id, image.FileName);
                return BadRequest(new { message = "Invalid image file. Please ensure it's a valid JPEG, PNG, or WebP image under 5MB." });
            }

            // Upload image via service
            var clinic = await _clinicService.UpdateImageAsync(id, image);
            
            _logger.LogInformation("Successfully uploaded image for clinic: {ClinicName} (ID: {ClinicId})", clinic.Name, clinic.Id);
            
            return Ok(clinic);
        }
        catch (InvalidOperationException ex) when (ex.Message.Contains("not found"))
        {
            _logger.LogWarning("Clinic not found for image upload: {ClinicId}", id);
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Image upload failed for clinic: {ClinicId}", id);
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading image for clinic: {ClinicId}", id);
            return StatusCode(500, new { message = "An error occurred while uploading the image" });
        }
    }

    /// <summary>
    /// Delete clinic image (Admin Only)
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <returns>Updated clinic without image</returns>
    /// <response code="200">Image deleted successfully</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    /// <response code="404">Clinic not found</response>
    [HttpDelete("{id:guid}/image")]
    [Authorize(Policy = "RequireAdministratorRole")]
    [SwaggerOperation(
        Summary = "Delete clinic image",
        Description = "Remove image from a specific clinic. Admin role required.",
        OperationId = "DeleteClinicImage"
    )]
    [SwaggerResponse(200, "Image deleted successfully", typeof(ClinicResponseDto))]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    [SwaggerResponse(404, "Clinic not found")]
    public async Task<ActionResult<ClinicResponseDto>> DeleteImage([Required] Guid id)
    {
        try
        {
            var clinic = await _clinicService.DeleteImageAsync(id);
            
            _logger.LogInformation("Successfully deleted image for clinic: {ClinicName} (ID: {ClinicId})", clinic.Name, clinic.Id);
            
            return Ok(clinic);
        }
        catch (InvalidOperationException ex) when (ex.Message.Contains("not found"))
        {
            _logger.LogWarning("Clinic not found for image deletion: {ClinicId}", id);
            return NotFound(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting image for clinic: {ClinicId}", id);
            return StatusCode(500, new { message = "An error occurred while deleting the image" });
        }
    }
}