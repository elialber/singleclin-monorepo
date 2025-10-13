using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using FirebaseAdmin.Auth;
using Microsoft.IdentityModel.Tokens;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data.Models;
using SingleClin.API.Data.Enums;

namespace SingleClin.API.Middleware;

public class JwtAuthenticationMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IConfiguration _configuration;
    private readonly ILogger<JwtAuthenticationMiddleware> _logger;

    public JwtAuthenticationMiddleware(
        RequestDelegate next,
        IConfiguration configuration,
        ILogger<JwtAuthenticationMiddleware> logger)
    {
        _next = next;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var token = context.Request.Headers["Authorization"]
            .FirstOrDefault()?.Split(" ").Last();

        if (token != null)
        {
            await AttachUserToContext(context, token);
        }

        await _next(context);
    }

    private async Task AttachUserToContext(HttpContext context, string token)
    {
        try
        {
            // First, try to validate as a Firebase token
            var firebaseToken = await ValidateFirebaseToken(token);
            if (firebaseToken != null)
            {
                _logger.LogDebug("Successfully validated Firebase token for user: {Uid}", firebaseToken.Uid);
                // Map Firebase UID/email to our ApplicationUser and emit GUID-based claims
                using var scope = context.RequestServices.CreateScope();
                var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();

                var emailFromToken = firebaseToken.Claims.GetValueOrDefault("email")?.ToString();

                var user = await userManager.Users
                    .FirstOrDefaultAsync(u => u.FirebaseUid == firebaseToken.Uid || (emailFromToken != null && u.Email == emailFromToken));

                if (user == null)
                {
                    user = new ApplicationUser
                    {
                        UserName = emailFromToken ?? firebaseToken.Uid,
                        Email = emailFromToken,
                        FullName = emailFromToken != null ? emailFromToken.Split('@')[0] : firebaseToken.Uid,
                        Role = UserRole.Patient,
                        EmailConfirmed = true,
                        CreatedAt = DateTime.UtcNow,
                        LastLoginAt = DateTime.UtcNow,
                        IsActive = true,
                        FirebaseUid = firebaseToken.Uid
                    };

                    var createResult = await userManager.CreateAsync(user);
                    if (!createResult.Succeeded)
                    {
                        _logger.LogWarning("Failed to create ApplicationUser for Firebase UID {Uid}: {Errors}", firebaseToken.Uid, string.Join(", ", createResult.Errors.Select(e => e.Description)));
                    }
                }
                else
                {
                    // Update last login and ensure Firebase UID is set
                    var needsUpdate = false;
                    if (string.IsNullOrEmpty(user.FirebaseUid))
                    {
                        user.FirebaseUid = firebaseToken.Uid;
                        needsUpdate = true;
                    }
                    user.LastLoginAt = DateTime.UtcNow;
                    needsUpdate = true;
                    if (needsUpdate)
                    {
                        await userManager.UpdateAsync(user);
                    }
                }

                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                    new Claim(ClaimTypes.Email, user.Email ?? string.Empty),
                    new Claim(ClaimTypes.Role, user.Role.ToString()),
                    new Claim("role", user.Role.ToString()),
                    new Claim("firebase_uid", user.FirebaseUid ?? string.Empty)
                };

                if (user.ClinicId.HasValue)
                {
                    claims.Add(new Claim("clinicId", user.ClinicId.Value.ToString()));
                }

                var identity = new ClaimsIdentity(claims, "Firebase");
                context.User = new ClaimsPrincipal(identity);
                return;
            }

            // If not a Firebase token, try to validate as our internal JWT
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.ASCII.GetBytes(_configuration["JWT:SecretKey"] ?? "");

            var principal = tokenHandler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateIssuer = true,
                ValidIssuer = _configuration["JWT:Issuer"],
                ValidateAudience = true,
                ValidAudience = _configuration["JWT:Audience"],
                ClockSkew = TimeSpan.Zero
            }, out SecurityToken validatedToken);

            var jwtToken = (JwtSecurityToken)validatedToken;

            // Log all claims for debugging
            _logger.LogDebug("JWT token claims: {Claims}",
                string.Join(", ", jwtToken.Claims.Select(c => $"{c.Type}={c.Value}")));

            var userIdClaim = jwtToken.Claims.FirstOrDefault(x => x.Type == ClaimTypes.NameIdentifier);

            if (userIdClaim == null)
            {
                // Try alternative claim names as fallback
                userIdClaim = jwtToken.Claims.FirstOrDefault(x => x.Type == "sub") ??
                             jwtToken.Claims.FirstOrDefault(x => x.Type == "user_id") ??
                             jwtToken.Claims.FirstOrDefault(x => x.Type == JwtRegisteredClaimNames.Sub);

                if (userIdClaim != null)
                {
                    _logger.LogInformation("Using fallback claim '{ClaimType}' as NameIdentifier", userIdClaim.Type);
                    // Add the NameIdentifier claim with the fallback value
                    var claimsList = jwtToken.Claims.ToList();
                    claimsList.Add(new Claim(ClaimTypes.NameIdentifier, userIdClaim.Value));
                    var identity = new ClaimsIdentity(claimsList, "Jwt");
                    context.User = new ClaimsPrincipal(identity);
                    return;
                }

                _logger.LogWarning("JWT token does not contain NameIdentifier claim. Available claims: {Claims}",
                    string.Join(", ", jwtToken.Claims.Select(c => c.Type)));
                return;
            }

            _logger.LogDebug("Successfully validated JWT token for user: {UserId}", userIdClaim.Value);

            // Attach user to context on successful jwt validation
            context.User = new ClaimsPrincipal(new ClaimsIdentity(jwtToken.Claims, "Jwt"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error validating token");
            // Do nothing if jwt validation fails
            // User is not attached to context so request won't have access to secure routes
        }
    }

    private async Task<FirebaseToken?> ValidateFirebaseToken(string token)
    {
        try
        {
            _logger.LogDebug("🔥 Attempting Firebase token validation...");
            var decodedToken = await FirebaseAuth.DefaultInstance.VerifyIdTokenAsync(token);
            _logger.LogInformation("✅ Firebase token validated successfully for UID: {Uid}", decodedToken.Uid);
            return decodedToken;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "❌ Firebase token validation failed: {Message}", ex.Message);
            return null;
        }
    }
}