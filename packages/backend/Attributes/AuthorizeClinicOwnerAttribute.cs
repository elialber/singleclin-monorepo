using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using SingleClin.API.Data.Enums;

namespace SingleClin.API.Attributes;

/// <summary>
/// Authorization attribute that ensures the user owns or belongs to the clinic being accessed
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class AuthorizeClinicOwnerAttribute : AuthorizeAttribute, IAuthorizationFilter
{
    private readonly string _clinicIdParameterName;
    private readonly bool _allowAdmin;

    /// <summary>
    /// Initializes a new instance of the AuthorizeClinicOwnerAttribute
    /// </summary>
    /// <param name="clinicIdParameterName">The name of the route/query parameter containing the clinic ID</param>
    /// <param name="allowAdmin">Whether to allow administrators to bypass the check</param>
    public AuthorizeClinicOwnerAttribute(string clinicIdParameterName = "clinicId", bool allowAdmin = true)
    {
        _clinicIdParameterName = clinicIdParameterName;
        _allowAdmin = allowAdmin;
    }

    public void OnAuthorization(AuthorizationFilterContext context)
    {
        // Check if user is authenticated
        var user = context.HttpContext.User;
        if (!user.Identity?.IsAuthenticated ?? true)
        {
            context.Result = new UnauthorizedObjectResult(new ProblemDetails
            {
                Title = "Unauthorized",
                Detail = "Authentication required",
                Status = StatusCodes.Status401Unauthorized
            });
            return;
        }

        // Get user's role
        var roleClaim = user.FindFirst("role")?.Value;
        if (!string.IsNullOrEmpty(roleClaim) && Enum.TryParse<UserRole>(roleClaim, out var userRole))
        {
            // Allow administrators if configured
            if (_allowAdmin && userRole == UserRole.Administrator)
            {
                return;
            }

            // Check if user is a clinic user
            if (userRole != UserRole.ClinicOrigin && userRole != UserRole.ClinicPartner)
            {
                context.Result = new ObjectResult(new ProblemDetails
                {
                    Title = "Forbidden",
                    Detail = "This resource is only accessible to clinic users",
                    Status = StatusCodes.Status403Forbidden
                })
                {
                    StatusCode = StatusCodes.Status403Forbidden
                };
                return;
            }
        }

        // Get clinic ID from route or query
        string? requestedClinicId = null;
        
        // Try route values first
        if (context.RouteData.Values.TryGetValue(_clinicIdParameterName, out var routeValue))
        {
            requestedClinicId = routeValue?.ToString();
        }
        // Then try query string
        else if (context.HttpContext.Request.Query.TryGetValue(_clinicIdParameterName, out var queryValue))
        {
            requestedClinicId = queryValue.ToString();
        }

        if (string.IsNullOrEmpty(requestedClinicId) || !Guid.TryParse(requestedClinicId, out var clinicGuid))
        {
            context.Result = new BadRequestObjectResult(new ProblemDetails
            {
                Title = "Bad Request",
                Detail = $"Valid {_clinicIdParameterName} is required",
                Status = StatusCodes.Status400BadRequest
            });
            return;
        }

        // Get user's clinic ID from claims
        var userClinicId = user.FindFirst("clinicId")?.Value;
        if (string.IsNullOrEmpty(userClinicId) || !Guid.TryParse(userClinicId, out var userClinicGuid))
        {
            context.Result = new ObjectResult(new ProblemDetails
            {
                Title = "Forbidden",
                Detail = "User is not associated with any clinic",
                Status = StatusCodes.Status403Forbidden
            })
            {
                StatusCode = StatusCodes.Status403Forbidden
            };
            return;
        }

        // Check if user's clinic matches the requested clinic
        if (userClinicGuid != clinicGuid)
        {
            context.Result = new ObjectResult(new ProblemDetails
            {
                Title = "Forbidden",
                Detail = "You do not have access to this clinic's resources",
                Status = StatusCodes.Status403Forbidden
            })
            {
                StatusCode = StatusCodes.Status403Forbidden
            };
            return;
        }
    }
}

/// <summary>
/// Authorization attribute that allows either admin or clinic owner
/// </summary>
public class AuthorizeAdminOrClinicOwnerAttribute : AuthorizeClinicOwnerAttribute
{
    public AuthorizeAdminOrClinicOwnerAttribute(string clinicIdParameterName = "clinicId") 
        : base(clinicIdParameterName, allowAdmin: true)
    {
    }
}