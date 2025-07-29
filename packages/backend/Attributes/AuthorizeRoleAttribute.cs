using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using SingleClin.API.Data.Enums;
using System.Security.Claims;

namespace SingleClin.API.Attributes;

/// <summary>
/// Custom authorization attribute for role-based access control
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = true)]
public class AuthorizeRoleAttribute : AuthorizeAttribute, IAuthorizationFilter
{
    private readonly UserRole[] _roles;

    /// <summary>
    /// Initializes a new instance of the AuthorizeRoleAttribute
    /// </summary>
    /// <param name="roles">Allowed roles</param>
    public AuthorizeRoleAttribute(params UserRole[] roles)
    {
        _roles = roles;
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

        // Get user's role from claims
        var roleClaim = user.FindFirst("role")?.Value;
        if (string.IsNullOrEmpty(roleClaim))
        {
            context.Result = new ForbidResult();
            return;
        }

        // Try to parse the role
        if (!Enum.TryParse<UserRole>(roleClaim, out var userRole))
        {
            context.Result = new ForbidResult();
            return;
        }

        // Check if user's role is in the allowed roles
        if (!_roles.Contains(userRole))
        {
            context.Result = new ObjectResult(new ProblemDetails
            {
                Title = "Forbidden",
                Detail = $"This resource requires one of the following roles: {string.Join(", ", _roles)}",
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
/// Authorize attribute for Administrator role
/// </summary>
public class AuthorizeAdminAttribute : AuthorizeRoleAttribute
{
    public AuthorizeAdminAttribute() : base(UserRole.Administrator) { }
}

/// <summary>
/// Authorize attribute for Clinic roles (Origin and Partner)
/// </summary>
public class AuthorizeClinicAttribute : AuthorizeRoleAttribute
{
    public AuthorizeClinicAttribute() : base(UserRole.ClinicOrigin, UserRole.ClinicPartner) { }
}

/// <summary>
/// Authorize attribute for Patient role
/// </summary>
public class AuthorizePatientAttribute : AuthorizeRoleAttribute
{
    public AuthorizePatientAttribute() : base(UserRole.Patient) { }
}

/// <summary>
/// Authorize attribute for any authenticated user
/// </summary>
public class AuthorizeAnyRoleAttribute : AuthorizeAttribute
{
    public AuthorizeAnyRoleAttribute()
    {
        AuthenticationSchemes = "Bearer";
    }
}