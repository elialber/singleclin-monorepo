using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SingleClin.API.Services;
using SingleClin.API.DTOs.Clinic;
using Swashbuckle.AspNetCore.Annotations;
using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.Controllers;

/// <summary>
/// Controller for managing services
/// </summary>
[ApiController]
[Route("api/[controller]")]
[SwaggerTag("Service management endpoints")]
public class ServicesController : BaseController
{
    public ServicesController()
    {
    }

    /// <summary>
    /// Get all services for a clinic
    /// </summary>
    /// <param name="clinicId">Clinic ID</param>
    /// <returns>List of services for the clinic</returns>
    /// <response code="200">Returns the list of services</response>
    /// <response code="400">Invalid clinic ID</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="404">Clinic not found</response>
    [HttpGet("clinic/{clinicId:guid}")]
    [SwaggerOperation(
        Summary = "Get services by clinic",
        Description = "Retrieves all active services available at a specific clinic"
    )]
    [ProducesResponseType(typeof(IEnumerable<ClinicServiceDto>), 200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(401)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> GetServicesByClinic([Required] Guid clinicId)
    {
        try
        {
            Logger.LogInformation("Getting services for clinic {ClinicId}", clinicId);

            // TODO: Implement service retrieval when IServiceService is created
            Logger.LogWarning("GetServicesByClinic not yet implemented - returning empty list");

            var services = new List<ClinicServiceDto>();
            return OkResponse(services, "Service retrieval not yet implemented");
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error getting services for clinic {ClinicId}", clinicId);
            return InternalServerErrorResponse();
        }
    }

    /// <summary>
    /// Get service details by ID
    /// </summary>
    /// <param name="serviceId">Service ID</param>
    /// <returns>Service details</returns>
    /// <response code="200">Returns the service details</response>
    /// <response code="400">Invalid service ID</response>
    /// <response code="401">Unauthorized</response>
    /// <response code="404">Service not found</response>
    [HttpGet("{serviceId:guid}")]
    [SwaggerOperation(
        Summary = "Get service by ID",
        Description = "Retrieves detailed information about a specific service"
    )]
    [ProducesResponseType(typeof(ClinicServiceDto), 200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(401)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> GetServiceById([Required] Guid serviceId)
    {
        try
        {
            Logger.LogInformation("Getting service {ServiceId}", serviceId);

            // TODO: Implement service retrieval when IServiceService is created
            Logger.LogWarning("GetServiceById not yet implemented - returning not found");

            return NotFoundResponse("Service retrieval not yet implemented");
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error getting service {ServiceId}", serviceId);
            return InternalServerErrorResponse();
        }
    }

    /// <summary>
    /// Search services across all clinics
    /// </summary>
    /// <param name="query">Search query</param>
    /// <param name="category">Service category filter</param>
    /// <param name="clinicId">Clinic ID filter (optional)</param>
    /// <param name="minCreditCost">Minimum credit cost filter</param>
    /// <param name="maxCreditCost">Maximum credit cost filter</param>
    /// <param name="page">Page number (default: 1)</param>
    /// <param name="limit">Items per page (default: 20, max: 100)</param>
    /// <returns>Paginated list of services matching the search criteria</returns>
    /// <response code="200">Returns the paginated list of services</response>
    /// <response code="400">Invalid search parameters</response>
    /// <response code="401">Unauthorized</response>
    [HttpGet("search")]
    [SwaggerOperation(
        Summary = "Search services",
        Description = "Search for services across all clinics with various filters"
    )]
    [ProducesResponseType(typeof(IEnumerable<ClinicServiceDto>), 200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(401)]
    public async Task<IActionResult> SearchServices(
        [FromQuery] string? query = null,
        [FromQuery] string? category = null,
        [FromQuery] Guid? clinicId = null,
        [FromQuery] int? minCreditCost = null,
        [FromQuery] int? maxCreditCost = null,
        [FromQuery, Range(1, int.MaxValue)] int page = 1,
        [FromQuery, Range(1, 100)] int limit = 20)
    {
        try
        {
            Logger.LogInformation("Searching services with query: {Query}, category: {Category}, clinic: {ClinicId}",
                query, category, clinicId);

            // Validate parameters
            if (minCreditCost.HasValue && maxCreditCost.HasValue && minCreditCost > maxCreditCost)
            {
                return BadRequestResponse("Minimum credit cost cannot be greater than maximum credit cost");
            }

            // For now, we'll get all services and filter them
            // In a real implementation, this should be done at the service/repository level for better performance
            var allServices = new List<ClinicServiceDto>();

            if (clinicId.HasValue)
            {
                // Get services for specific clinic
                // TODO: Implement service retrieval when IServiceService is created
                Logger.LogWarning("Service search not yet implemented");
            }
            else
            {
                // This would need to be implemented in the ClinicService to get all services
                // For now, return empty result with a message
                return OkResponse(new List<ClinicServiceDto>(),
                    "Search across all clinics not yet implemented. Please specify a clinicId.");
            }

            // Apply filters
            var filteredServices = allServices.AsEnumerable();

            if (!string.IsNullOrWhiteSpace(query))
            {
                var queryLower = query.ToLower();
                filteredServices = filteredServices.Where(s =>
                    s.Name.ToLower().Contains(queryLower) ||
                    s.Description.ToLower().Contains(queryLower) ||
                    s.Category.ToLower().Contains(queryLower));
            }

            if (!string.IsNullOrWhiteSpace(category))
            {
                filteredServices = filteredServices.Where(s =>
                    s.Category.Equals(category, StringComparison.OrdinalIgnoreCase));
            }

            if (minCreditCost.HasValue)
            {
                filteredServices = filteredServices.Where(s => s.CreditCost >= minCreditCost.Value);
            }

            if (maxCreditCost.HasValue)
            {
                filteredServices = filteredServices.Where(s => s.CreditCost <= maxCreditCost.Value);
            }

            // Apply pagination
            var totalCount = filteredServices.Count();
            var pagedServices = filteredServices
                .Skip((page - 1) * limit)
                .Take(limit)
                .ToList();

            var result = new
            {
                Data = pagedServices,
                Total = totalCount,
                Page = page,
                Limit = limit,
                TotalPages = (int)Math.Ceiling((double)totalCount / limit)
            };

            return OkResponse(result, $"Found {totalCount} services matching criteria");
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error searching services");
            return InternalServerErrorResponse();
        }
    }

    /// <summary>
    /// Get service categories
    /// </summary>
    /// <returns>List of available service categories</returns>
    /// <response code="200">Returns the list of service categories</response>
    /// <response code="401">Unauthorized</response>
    [HttpGet("categories")]
    [SwaggerOperation(
        Summary = "Get service categories",
        Description = "Retrieves all available service categories"
    )]
    [ProducesResponseType(typeof(IEnumerable<string>), 200)]
    [ProducesResponseType(401)]
    public async Task<IActionResult> GetServiceCategories()
    {
        try
        {
            Logger.LogInformation("Getting service categories");

            // For now, return common categories
            // In a real implementation, this should be retrieved from the database
            var categories = new[]
            {
                "Consultation",
                "Diagnostics",
                "Treatment",
                "Therapy",
                "Surgery",
                "Emergency",
                "Preventive",
                "Specialized"
            };

            return OkResponse(categories, "Service categories retrieved successfully");
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error getting service categories");
            return InternalServerErrorResponse();
        }
    }
}