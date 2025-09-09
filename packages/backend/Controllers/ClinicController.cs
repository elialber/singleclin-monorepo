using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SingleClin.API.Services;
using SingleClin.API.DTOs.Clinic;
using SingleClin.API.DTOs.Common;
using SingleClin.API.DTOs.Auth;
using Swashbuckle.AspNetCore.Annotations;
using System.ComponentModel.DataAnnotations;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.AspNetCore.Identity;
using SingleClin.API.Data.Models;

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
    private readonly IConfiguration _configuration;

    public ClinicController(
        IClinicService clinicService, 
        IImageUploadService imageUploadService,
        ILogger<ClinicController> logger,
        IConfiguration configuration)
    {
        _clinicService = clinicService;
        _imageUploadService = imageUploadService;
        _logger = logger;
        _configuration = configuration;
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
    [AllowAnonymous]
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
    /// Generate Real User Token (Development Only)
    /// </summary>
    [HttpPost("generate-real-token")]
    [AllowAnonymous]
    public async Task<IActionResult> GenerateRealToken(
        [FromBody] LoginDto request,
        [FromServices] UserManager<ApplicationUser> userManager,
        [FromServices] IJwtService jwtService)
    {
        try
        {
            var user = await userManager.FindByEmailAsync(request.Email);
            if (user == null)
            {
                return BadRequest(new { message = "User not found" });
            }

            var passwordCheck = await userManager.CheckPasswordAsync(user, request.Password);
            if (!passwordCheck)
            {
                return BadRequest(new { message = "Invalid password" });
            }

            var token = jwtService.GenerateAccessToken(user);
            
            return Ok(new
            {
                token,
                expires = DateTime.UtcNow.AddMinutes(Convert.ToDouble(_configuration["JWT:AccessTokenExpirationInMinutes"] ?? "60")),
                issuer = _configuration["JWT:Issuer"],
                audience = _configuration["JWT:Audience"],
                user = new
                {
                    id = user.Id,
                    email = user.Email,
                    fullName = user.FullName,
                    role = user.Role.ToString()
                },
                usage = "Use this token in Authorization header: Bearer <token>"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating real token for user: {Email}", request.Email);
            return StatusCode(500, new { message = "Error generating token" });
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
                HasAdminRole = HttpContext.User.HasClaim(ClaimTypes.Role, "Administrator") || HttpContext.User.HasClaim("role", "Administrator"),
                HasAnyRole = HttpContext.User.Claims.Any(c => c.Type == ClaimTypes.Role || c.Type == "role"),
                HasAdminRoleStandard = HttpContext.User.HasClaim(ClaimTypes.Role, "Administrator"),
                HasAdminRoleCustom = HttpContext.User.HasClaim("role", "Administrator")
            }
        });
    }


    /// <summary>
    /// Create Identity users only (DEV ONLY)
    /// </summary>
    [HttpPost("create-identity-users")]
    [AllowAnonymous]
    public async Task<IActionResult> CreateIdentityUsers([FromServices] UserManager<ApplicationUser> userManager)
    {
        try
        {
            var results = new List<object>();
            _logger.LogInformation("Creating Identity users...");

            var users = new[]
            {
                new { 
                    Email = "elialberlopes@gmail.com", 
                    Password = "Aguia97003325!", 
                    Role = Data.Enums.UserRole.Administrator, 
                    FullName = "Eli Alber Lopes" 
                },
                new { 
                    Email = "poliveira.psico@gmail.com", 
                    Password = "Aguia97003325!", 
                    Role = Data.Enums.UserRole.Patient, 
                    FullName = "P. Oliveira" 
                }
            };

            foreach (var userInfo in users)
            {
                try
                {
                    _logger.LogInformation("Creating Identity user: {Email}", userInfo.Email);
                    
                    // Check if user already exists and delete
                    var existingUser = await userManager.FindByEmailAsync(userInfo.Email);
                    if (existingUser != null)
                    {
                        var deleteResult = await userManager.DeleteAsync(existingUser);
                        if (deleteResult.Succeeded)
                        {
                            _logger.LogInformation("Deleted existing user: {Email}", userInfo.Email);
                        }
                    }

                    // Create new user
                    var user = new ApplicationUser
                    {
                        UserName = userInfo.Email,
                        Email = userInfo.Email,
                        FullName = userInfo.FullName,
                        Role = userInfo.Role,
                        FirebaseUid = $"temp-uid-{Guid.NewGuid()}", // Temporary until Firebase sync
                        EmailConfirmed = true,
                        IsActive = true,
                        CreatedAt = DateTime.UtcNow
                    };

                    var result = await userManager.CreateAsync(user, userInfo.Password);
                    
                    if (result.Succeeded)
                    {
                        // Add role claims
                        await userManager.AddClaimAsync(user, new Claim("role", userInfo.Role.ToString()));
                        await userManager.AddClaimAsync(user, new Claim(ClaimTypes.Role, userInfo.Role.ToString()));
                        
                        // Add admin permissions if needed
                        if (userInfo.Role == Data.Enums.UserRole.Administrator)
                        {
                            var permissions = new[]
                            {
                                "users.read", "users.write", "users.delete",
                                "clinics.read", "clinics.write", "clinics.delete",
                                "patients.read", "patients.write", "patients.delete",
                                "system.configure", "system.monitor", "system.backup"
                            };
                            
                            await userManager.AddClaimAsync(user, new Claim("permissions", string.Join(",", permissions)));
                        }

                        results.Add(new {
                            Email = userInfo.Email,
                            Role = userInfo.Role.ToString(),
                            UserId = user.Id,
                            Status = "Success"
                        });

                        _logger.LogInformation("Successfully created user: {Email} with ID: {UserId}", userInfo.Email, user.Id);
                    }
                    else
                    {
                        var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                        results.Add(new {
                            Email = userInfo.Email,
                            Role = userInfo.Role.ToString(),
                            UserId = (Guid?)null,
                            Status = $"Failed: {errors}"
                        });
                        _logger.LogError("Failed to create user {Email}: {Errors}", userInfo.Email, errors);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Exception creating user: {Email}", userInfo.Email);
                    results.Add(new {
                        Email = userInfo.Email,
                        Role = userInfo.Role.ToString(),
                        UserId = (Guid?)null,
                        Status = $"Exception: {ex.Message}"
                    });
                }
            }

            return Ok(new {
                Message = "Identity user creation completed",
                Users = results,
                Note = "Firebase users need to be created separately",
                Timestamp = DateTime.UtcNow
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Identity user creation failed");
            return StatusCode(500, new { 
                Message = "Identity user creation failed", 
                Error = ex.Message 
            });
        }
    }

    /// <summary>
    /// Simple test endpoint
    /// </summary>
    [HttpGet("simple-test")]
    [AllowAnonymous]
    public IActionResult SimpleTest()
    {
        return Ok(new { Status = "OK", Message = "Endpoint is working", Timestamp = DateTime.UtcNow });
    }

    /// <summary>
    /// Generate test JWT token (Development Only)
    /// </summary>
    /// <returns>Test JWT token for debugging</returns>
    [HttpGet("generate-test-token")]
    [AllowAnonymous]
    [SwaggerOperation(
        Summary = "Generate Test JWT Token (DEV ONLY)",
        Description = "Generates a test JWT token with basic user claims for testing API endpoints that require authentication",
        OperationId = "GenerateTestToken"
    )]
    public IActionResult GenerateTestToken()
    {
        try
        {
            // This is for development only - create a JWT token with the same key as the system
            var secretKey = _configuration["JWT:SecretKey"] ?? throw new InvalidOperationException("JWT:SecretKey not configured");
            var key = new SymmetricSecurityKey(Encoding.ASCII.GetBytes(secretKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, Guid.NewGuid().ToString()),
                new Claim(ClaimTypes.Email, "test@singleclin.com"),
                new Claim(ClaimTypes.Name, "Test User"),
                new Claim(ClaimTypes.Role, "Administrator"),
                new Claim("role", "Administrator"),
                new Claim("user_id", Guid.NewGuid().ToString()),
                new Claim("firebase_uid", "test-firebase-uid"),
                new Claim("isActive", "True")
            };

            var issuer = _configuration["JWT:Issuer"] ?? "SingleClin";
            var audience = _configuration["JWT:Audience"] ?? "SingleClin.API";

            var token = new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: claims,
                expires: DateTime.Now.AddHours(24),
                signingCredentials: creds
            );

            var tokenString = new JwtSecurityTokenHandler().WriteToken(token);

            return Ok(new
            {
                token = tokenString,
                expires = token.ValidTo,
                issuer = issuer,
                audience = audience,
                usage = "Use this token in Authorization header: Bearer <token>",
                testUrl = $"http://localhost:5010/api/clinic/19d21d7a-01f5-41e1-9d8d-18bcd7911ae7"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating test token");
            return StatusCode(500, new { message = "Error generating test token" });
        }
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
    /// Get clinic by ID
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <returns>Clinic details</returns>
    /// <response code="200">Returns the clinic</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="404">Clinic not found</response>
    [HttpGet("{id:guid}")]
    [Authorize]
    [SwaggerOperation(
        Summary = "Get clinic by ID",
        Description = "Retrieve a specific clinic by its ID.",
        OperationId = "GetClinicById"
    )]
    [SwaggerResponse(200, "Success", typeof(ClinicResponseDto))]
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

    // Multiple Images Management Endpoints

    /// <summary>
    /// Upload multiple images to a clinic (Admin Only)
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <param name="uploadDto">Multiple images upload data</param>
    /// <returns>Upload response with results</returns>
    /// <response code="200">Images uploaded successfully</response>
    /// <response code="400">Invalid image files or clinic data</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    /// <response code="404">Clinic not found</response>
    /// <response code="413">File too large</response>
    [HttpPost("{id:guid}/images")]
    [Authorize(Policy = "RequireAdministratorRole")]
    [SwaggerOperation(
        Summary = "Upload multiple clinic images",
        Description = @"Upload multiple images for a specific clinic. Admin role required.
**Supported formats:** JPEG, PNG, WebP
**Maximum file size:** 5MB per file
**Maximum files:** 10 images
**Automatic processing:** Images are resized and optimized for web",
        OperationId = "UploadClinicImages"
    )]
    [SwaggerResponse(200, "Images uploaded successfully", typeof(MultipleImageUploadResponseDto))]
    [SwaggerResponse(400, "Bad Request - Invalid image files")]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    [SwaggerResponse(404, "Clinic not found")]
    [SwaggerResponse(413, "Payload Too Large - File exceeds size limit")]
    public async Task<ActionResult<MultipleImageUploadResponseDto>> UploadImages(
        [Required] Guid id, 
        [FromForm] MultipleImageUploadDto uploadDto)
    {
        try
        {
            // Validate that images are provided
            if (uploadDto.Images == null || uploadDto.Images.Length == 0)
            {
                _logger.LogWarning("Multiple images upload attempted with no files for clinic: {ClinicId}", id);
                return BadRequest(new { message = "No image files provided" });
            }

            if (uploadDto.Images.Length > 10)
            {
                _logger.LogWarning("Too many images uploaded for clinic: {ClinicId}, Count: {Count}", id, uploadDto.Images.Length);
                return BadRequest(new { message = "Maximum 10 images allowed" });
            }

            // Validate each image file
            foreach (var image in uploadDto.Images)
            {
                if (!await _imageUploadService.ValidateImageAsync(image))
                {
                    _logger.LogWarning("Invalid image file in batch upload for clinic: {ClinicId}, FileName: {FileName}", 
                        id, image.FileName);
                    return BadRequest(new { message = $"Invalid image file: {image.FileName}. Please ensure all files are valid JPEG, PNG, or WebP images under 5MB." });
                }
            }

            // Upload images via service
            var result = await _clinicService.AddImagesAsync(id, uploadDto);
            
            _logger.LogInformation("Uploaded {SuccessCount} images for clinic: {ClinicId}", result.SuccessCount, id);
            
            return Ok(result);
        }
        catch (InvalidOperationException ex) when (ex.Message.Contains("not found"))
        {
            _logger.LogWarning("Clinic not found for images upload: {ClinicId}", id);
            return NotFound(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading images for clinic: {ClinicId}", id);
            return StatusCode(500, new { message = "An error occurred while uploading the images" });
        }
    }

    /// <summary>
    /// Get all images for a clinic
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <returns>List of clinic images</returns>
    /// <response code="200">Images retrieved successfully</response>
    /// <response code="404">Clinic not found</response>
    [HttpGet("{id:guid}/images")]
    [SwaggerOperation(
        Summary = "Get clinic images",
        Description = "Retrieve all images for a specific clinic ordered by display order.",
        OperationId = "GetClinicImages"
    )]
    [SwaggerResponse(200, "Images retrieved successfully", typeof(List<ClinicImageDto>))]
    [SwaggerResponse(404, "Clinic not found")]
    public async Task<ActionResult<List<ClinicImageDto>>> GetImages([Required] Guid id)
    {
        try
        {
            var images = await _clinicService.GetImagesAsync(id);
            return Ok(images);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving images for clinic: {ClinicId}", id);
            return StatusCode(500, new { message = "An error occurred while retrieving the images" });
        }
    }

    /// <summary>
    /// Update image properties (Admin Only)
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <param name="imageId">Image ID</param>
    /// <param name="updateDto">Updated image data</param>
    /// <returns>Updated image</returns>
    /// <response code="200">Image updated successfully</response>
    /// <response code="400">Invalid request data</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    /// <response code="404">Clinic or image not found</response>
    [HttpPut("{id:guid}/images/{imageId:guid}")]
    [Authorize(Policy = "RequireAdministratorRole")]
    [SwaggerOperation(
        Summary = "Update clinic image properties",
        Description = "Update metadata for a specific clinic image (alt text, description, display order, featured status). Admin role required.",
        OperationId = "UpdateClinicImage"
    )]
    [SwaggerResponse(200, "Image updated successfully", typeof(ClinicImageDto))]
    [SwaggerResponse(400, "Bad Request - Invalid data")]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    [SwaggerResponse(404, "Clinic or image not found")]
    public async Task<ActionResult<ClinicImageDto>> UpdateImage(
        [Required] Guid id, 
        [Required] Guid imageId, 
        [FromBody] ClinicImageUpdateDto updateDto)
    {
        try
        {
            var image = await _clinicService.UpdateImageAsync(id, imageId, updateDto);
            
            _logger.LogInformation("Successfully updated image {ImageId} for clinic: {ClinicId}", imageId, id);
            
            return Ok(image);
        }
        catch (InvalidOperationException ex) when (ex.Message.Contains("not found"))
        {
            _logger.LogWarning("Clinic or image not found for update: ClinicId={ClinicId}, ImageId={ImageId}", id, imageId);
            return NotFound(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating image {ImageId} for clinic: {ClinicId}", imageId, id);
            return StatusCode(500, new { message = "An error occurred while updating the image" });
        }
    }

    /// <summary>
    /// Delete a specific image from a clinic (Admin Only)
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <param name="imageId">Image ID</param>
    /// <returns>Success result</returns>
    /// <response code="204">Image deleted successfully</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    /// <response code="404">Clinic or image not found</response>
    [HttpDelete("{id:guid}/images/{imageId:guid}")]
    [Authorize(Policy = "RequireAdministratorRole")]
    [SwaggerOperation(
        Summary = "Delete clinic image",
        Description = "Remove a specific image from a clinic. Admin role required.",
        OperationId = "DeleteClinicImageById"
    )]
    [SwaggerResponse(204, "Image deleted successfully")]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    [SwaggerResponse(404, "Clinic or image not found")]
    public async Task<ActionResult> DeleteImageById([Required] Guid id, [Required] Guid imageId)
    {
        try
        {
            var deleted = await _clinicService.DeleteImageAsync(id, imageId);
            
            if (!deleted)
            {
                _logger.LogWarning("Clinic or image not found for deletion: ClinicId={ClinicId}, ImageId={ImageId}", id, imageId);
                return NotFound(new { message = "Clinic or image not found" });
            }
            
            _logger.LogInformation("Successfully deleted image {ImageId} from clinic: {ClinicId}", imageId, id);
            
            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting image {ImageId} from clinic: {ClinicId}", imageId, id);
            return StatusCode(500, new { message = "An error occurred while deleting the image" });
        }
    }

    /// <summary>
    /// Set featured image for a clinic (Admin Only)
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <param name="imageId">Image ID to set as featured</param>
    /// <returns>Updated image</returns>
    /// <response code="200">Featured image set successfully</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    /// <response code="404">Clinic or image not found</response>
    [HttpPost("{id:guid}/images/{imageId:guid}/set-featured")]
    [Authorize(Policy = "RequireAdministratorRole")]
    [SwaggerOperation(
        Summary = "Set featured clinic image",
        Description = "Set a specific image as the featured/primary image for a clinic. This will clear the featured status from other images. Admin role required.",
        OperationId = "SetFeaturedClinicImage"
    )]
    [SwaggerResponse(200, "Featured image set successfully", typeof(ClinicImageDto))]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    [SwaggerResponse(404, "Clinic or image not found")]
    public async Task<ActionResult<ClinicImageDto>> SetFeaturedImage([Required] Guid id, [Required] Guid imageId)
    {
        try
        {
            var image = await _clinicService.SetFeaturedImageAsync(id, imageId);
            
            _logger.LogInformation("Successfully set featured image {ImageId} for clinic: {ClinicId}", imageId, id);
            
            return Ok(image);
        }
        catch (InvalidOperationException ex) when (ex.Message.Contains("not found"))
        {
            _logger.LogWarning("Clinic or image not found for featured image: ClinicId={ClinicId}, ImageId={ImageId}", id, imageId);
            return NotFound(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error setting featured image {ImageId} for clinic: {ClinicId}", imageId, id);
            return StatusCode(500, new { message = "An error occurred while setting the featured image" });
        }
    }

    /// <summary>
    /// Reorder clinic images (Admin Only)
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <param name="imageOrders">Dictionary of image ID to display order</param>
    /// <returns>List of reordered images</returns>
    /// <response code="200">Images reordered successfully</response>
    /// <response code="400">Invalid request data</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="403">Forbidden - Admin role required</response>
    /// <response code="404">Clinic not found</response>
    [HttpPost("{id:guid}/images/reorder")]
    [Authorize(Policy = "RequireAdministratorRole")]
    [SwaggerOperation(
        Summary = "Reorder clinic images",
        Description = "Change the display order of clinic images. Provide a dictionary mapping image IDs to their new display order. Admin role required.",
        OperationId = "ReorderClinicImages"
    )]
    [SwaggerResponse(200, "Images reordered successfully", typeof(List<ClinicImageDto>))]
    [SwaggerResponse(400, "Bad Request - Invalid data")]
    [SwaggerResponse(401, "Unauthorized")]
    [SwaggerResponse(403, "Forbidden - Admin role required")]
    [SwaggerResponse(404, "Clinic not found")]
    public async Task<ActionResult<List<ClinicImageDto>>> ReorderImages(
        [Required] Guid id, 
        [FromBody] Dictionary<Guid, int> imageOrders)
    {
        try
        {
            if (imageOrders == null || imageOrders.Count == 0)
            {
                return BadRequest(new { message = "Image order data is required" });
            }

            var images = await _clinicService.ReorderImagesAsync(id, imageOrders);
            
            _logger.LogInformation("Successfully reordered {Count} images for clinic: {ClinicId}", imageOrders.Count, id);
            
            return Ok(images);
        }
        catch (InvalidOperationException ex) when (ex.Message.Contains("not found"))
        {
            _logger.LogWarning("Clinic not found for image reordering: {ClinicId}", id);
            return NotFound(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error reordering images for clinic: {ClinicId}", id);
            return StatusCode(500, new { message = "An error occurred while reordering the images" });
        }
    }

    /// <summary>
    /// TEST ENDPOINT: Upload images without authentication (Development Only)
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <param name="uploadDto">Multiple images upload data</param>
    /// <returns>Upload response with results</returns>
    [HttpPost("{id:guid}/images/test")]
    [AllowAnonymous]
    [SwaggerOperation(
        Summary = "TEST: Upload clinic images without auth (DEV ONLY)",
        Description = "Test endpoint to upload images without authentication. REMOVE IN PRODUCTION!",
        OperationId = "TestUploadClinicImages"
    )]
    public async Task<ActionResult<MultipleImageUploadResponseDto>> TestUploadImages(
        [Required] Guid id, 
        [FromForm] MultipleImageUploadDto uploadDto)
    {
        try
        {
            _logger.LogWarning("⚠️  TEST ENDPOINT: Using non-authenticated image upload for clinic {ClinicId}", id);
            
            // Validate that images are provided
            if (uploadDto.Images == null || uploadDto.Images.Length == 0)
            {
                _logger.LogWarning("Multiple images upload attempted with no files for clinic: {ClinicId}", id);
                return BadRequest(new { message = "No image files provided" });
            }

            if (uploadDto.Images.Length > 10)
            {
                _logger.LogWarning("Too many images uploaded for clinic: {ClinicId}, Count: {Count}", id, uploadDto.Images.Length);
                return BadRequest(new { message = "Maximum 10 images allowed" });
            }

            // Validate each image file
            foreach (var image in uploadDto.Images)
            {
                if (!await _imageUploadService.ValidateImageAsync(image))
                {
                    _logger.LogWarning("Invalid image file in batch upload for clinic: {ClinicId}, FileName: {FileName}", 
                        id, image.FileName);
                    return BadRequest(new { message = $"Invalid image file: {image.FileName}. Please ensure all files are valid JPEG, PNG, or WebP images under 5MB." });
                }
            }

            // Upload images via service
            var result = await _clinicService.AddImagesAsync(id, uploadDto);
            
            _logger.LogInformation("✅ TEST: Uploaded {SuccessCount} images for clinic: {ClinicId}", result.SuccessCount, id);
            
            return Ok(result);
        }
        catch (InvalidOperationException ex) when (ex.Message.Contains("not found"))
        {
            _logger.LogWarning("Clinic not found for images upload: {ClinicId}", id);
            return NotFound(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ TEST: Error uploading images for clinic: {ClinicId}", id);
            return StatusCode(500, new { message = "An error occurred while uploading the images" });
        }
    }
}