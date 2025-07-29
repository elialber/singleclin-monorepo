using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;
using SingleClin.API.Data.Models;
using SingleClin.API.Data.Enums;
using SingleClin.API.Data;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace SingleClin.API.Services;

/// <summary>
/// Service for transforming and adding claims dynamically during authentication
/// </summary>
public class ClaimsTransformationService : IClaimsTransformation
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ApplicationDbContext _context;
    private readonly ILogger<ClaimsTransformationService> _logger;

    public ClaimsTransformationService(
        UserManager<ApplicationUser> userManager,
        ApplicationDbContext context,
        ILogger<ClaimsTransformationService> logger)
    {
        _userManager = userManager;
        _context = context;
        _logger = logger;
    }

    public async Task<ClaimsPrincipal> TransformAsync(ClaimsPrincipal principal)
    {
        if (principal.Identity?.IsAuthenticated != true)
        {
            return principal;
        }

        var identity = (ClaimsIdentity)principal.Identity;
        var userId = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
        {
            return principal;
        }

        try
        {
            // Get user with clinic information
            var user = await _context.Users
                .Include(u => u.Clinic)
                .FirstOrDefaultAsync(u => u.Id == userGuid);

            if (user == null)
            {
                return principal;
            }

            // Add role claim if not present
            if (!principal.HasClaim(c => c.Type == "role" && c.Value == user.Role.ToString()))
            {
                identity.AddClaim(new Claim("role", user.Role.ToString()));
            }

            // Add clinic-related claims for clinic users
            if ((user.Role == UserRole.ClinicOrigin || user.Role == UserRole.ClinicPartner) && user.ClinicId.HasValue)
            {
                // Add clinic ID claim
                if (!principal.HasClaim(c => c.Type == "clinicId" && c.Value == user.ClinicId.Value.ToString()))
                {
                    identity.AddClaim(new Claim("clinicId", user.ClinicId.Value.ToString()));
                }

                // Add clinic type claim
                if (user.Clinic != null && !principal.HasClaim(c => c.Type == "clinicType" && c.Value == user.Clinic.Type.ToString()))
                {
                    identity.AddClaim(new Claim("clinicType", user.Clinic.Type.ToString()));
                }

                // Add clinic-specific permissions
                var clinicPermissions = GetClinicPermissions(user.Role, user.Clinic?.Type);
                if (clinicPermissions.Any() && !principal.HasClaim(c => c.Type == "permissions"))
                {
                    identity.AddClaim(new Claim("permissions", string.Join(",", clinicPermissions)));
                }
            }

            // Add admin permissions for administrators
            if (user.Role == UserRole.Administrator)
            {
                var adminPermissions = GetAdminPermissions();
                if (!principal.HasClaim(c => c.Type == "permissions"))
                {
                    identity.AddClaim(new Claim("permissions", string.Join(",", adminPermissions)));
                }
            }

            // Add patient permissions for patients
            if (user.Role == UserRole.Patient)
            {
                var patientPermissions = GetPatientPermissions();
                if (!principal.HasClaim(c => c.Type == "permissions"))
                {
                    identity.AddClaim(new Claim("permissions", string.Join(",", patientPermissions)));
                }
            }

            // Add user status claims
            identity.AddClaim(new Claim("isActive", user.IsActive.ToString()));
            identity.AddClaim(new Claim("emailConfirmed", user.EmailConfirmed.ToString()));

            _logger.LogDebug("Claims transformation completed for user: {UserId}, Role: {Role}", userId, user.Role);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during claims transformation for user: {UserId}", userId);
        }

        return principal;
    }

    private static string[] GetAdminPermissions()
    {
        return new[]
        {
            // User management
            "users.read", "users.write", "users.delete", "users.manage",
            
            // Clinic management
            "clinics.read", "clinics.write", "clinics.delete", "clinics.manage",
            
            // Patient management
            "patients.read", "patients.write", "patients.delete",
            
            // System administration
            "system.configure", "system.monitor", "system.backup", "system.logs",
            
            // Credits and transactions
            "credits.read", "credits.write", "credits.manage",
            "transactions.read", "transactions.write",
            
            // Reports and analytics
            "reports.read", "reports.generate", "analytics.read"
        };
    }

    private static string[] GetClinicPermissions(UserRole role, Data.Models.Enums.ClinicType? clinicType)
    {
        var basePermissions = new List<string>
        {
            // Basic clinic permissions
            "clinic.profile.read", "clinic.profile.write",
            "qr.validate", "patients.read"
        };

        if (role == UserRole.ClinicOrigin && clinicType == Data.Models.Enums.ClinicType.Origin)
        {
            // Origin clinics can provide services
            basePermissions.AddRange(new[]
            {
                "services.read", "services.write", "services.provide",
                "qr.generate", "credits.manage", "transactions.read"
            });
        }
        else if (role == UserRole.ClinicPartner && clinicType == Data.Models.Enums.ClinicType.Partner)
        {
            // Partner clinics have limited permissions
            basePermissions.AddRange(new[]
            {
                "services.read", "qr.validate", "patients.validate"
            });
        }

        return basePermissions.ToArray();
    }

    private static string[] GetPatientPermissions()
    {
        return new[]
        {
            // Patient basic permissions
            "profile.read", "profile.write",
            "credits.read", "credits.use",
            "qr.generate", "qr.view",
            "transactions.read", "services.book"
        };
    }
}