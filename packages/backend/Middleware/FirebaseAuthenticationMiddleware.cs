using System.Linq;
using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data.Enums;
using SingleClin.API.Data.Models;
using SingleClin.API.Services;

namespace SingleClin.API.Middleware;

/// <summary>
/// Middleware to validate Firebase tokens and attach the corresponding SingleClin user to the current context.
/// </summary>
public class FirebaseAuthenticationMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<FirebaseAuthenticationMiddleware> _logger;
    private readonly IServiceProvider _serviceProvider;

    public FirebaseAuthenticationMiddleware(
        RequestDelegate next,
        ILogger<FirebaseAuthenticationMiddleware> logger,
        IServiceProvider serviceProvider)
    {
        _next = next;
        _logger = logger;
        _serviceProvider = serviceProvider;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (!context.Request.Headers.TryGetValue("X-Firebase-Token", out var firebaseTokenValue) || string.IsNullOrWhiteSpace(firebaseTokenValue))
        {
            await _next(context);
            return;
        }

        using var scope = _serviceProvider.CreateScope();
        var firebaseAuthService = scope.ServiceProvider.GetRequiredService<IFirebaseAuthService>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var jwtService = scope.ServiceProvider.GetRequiredService<IJwtService>();

        try
        {
            var decodedToken = await firebaseAuthService.VerifyIdTokenAsync(firebaseTokenValue!);
            if (decodedToken == null)
            {
                _logger.LogWarning("Invalid Firebase token provided in X-Firebase-Token header");
                await _next(context);
                return;
            }

            if (!decodedToken.Claims.TryGetValue("email", out var emailClaim) || string.IsNullOrWhiteSpace(emailClaim?.ToString()))
            {
                _logger.LogWarning("Firebase token does not contain an email claim. UID: {Uid}", decodedToken.Uid);
                await _next(context);
                return;
            }

            var email = emailClaim!.ToString()!;

            var user = await FindOrCreateUserAsync(userManager, firebaseAuthService, decodedToken.Uid, email);

            if (user == null)
            {
                _logger.LogWarning("Failed to provision ApplicationUser for Firebase UID {Uid}", decodedToken.Uid);
                await _next(context);
                return;
            }

            // Generate an access token for downstream components (stateless, no refresh token is created).
            var accessToken = jwtService.GenerateAccessToken(user);
            context.Request.Headers["Authorization"] = $"Bearer {accessToken}";

            // Populate HttpContext.User with the application claims so controllers can rely on the standard pipeline.
            context.User = BuildClaimsPrincipal(user);

            _logger.LogDebug("Firebase token authenticated for user {UserId} ({Email})", user.Id, user.Email);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing Firebase token from header");
        }

        await _next(context);
    }

    private static ClaimsPrincipal BuildClaimsPrincipal(ApplicationUser user)
    {
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email ?? string.Empty),
            new Claim(ClaimTypes.Name, user.FullName),
            new Claim(ClaimTypes.Role, user.Role.ToString()),
            new Claim("role", user.Role.ToString()),
            new Claim("firebase_uid", user.FirebaseUid ?? string.Empty)
        };

        if (user.ClinicId.HasValue)
        {
            claims.Add(new Claim("clinicId", user.ClinicId.Value.ToString()));
        }

        var identity = new ClaimsIdentity(claims, authenticationType: "Firebase");
        return new ClaimsPrincipal(identity);
    }

    private async Task<ApplicationUser?> FindOrCreateUserAsync(
        UserManager<ApplicationUser> userManager,
        IFirebaseAuthService firebaseAuthService,
        string firebaseUid,
        string email)
    {
        var user = await userManager.Users
            .FirstOrDefaultAsync(u => u.FirebaseUid == firebaseUid || u.Email == email);

        if (user == null)
        {
            var firebaseUser = await firebaseAuthService.GetUserAsync(firebaseUid);

            user = new ApplicationUser
            {
                UserName = email,
                Email = email,
                FullName = firebaseUser?.DisplayName ?? email.Split('@')[0],
                Role = UserRole.Patient,
                EmailConfirmed = firebaseUser?.EmailVerified ?? false,
                CreatedAt = DateTime.UtcNow,
                LastLoginAt = DateTime.UtcNow,
                IsActive = true,
                FirebaseUid = firebaseUid
            };

            var createResult = await userManager.CreateAsync(user);
            if (!createResult.Succeeded)
            {
                var errors = string.Join(", ", createResult.Errors.Select(e => e.Description));
                _logger.LogError("Failed to create ApplicationUser for Firebase UID {Uid}: {Errors}", firebaseUid, errors);
                return null;
            }

            await userManager.AddClaimAsync(user, new Claim(ClaimTypes.Role, user.Role.ToString()));
            await userManager.AddClaimAsync(user, new Claim("role", user.Role.ToString()));
            _logger.LogInformation("Provisioned new ApplicationUser {UserId} for Firebase UID {Uid}", user.Id, firebaseUid);
        }
        else
        {
            var needsUpdate = false;

            if (string.IsNullOrEmpty(user.FirebaseUid) || !string.Equals(user.FirebaseUid, firebaseUid, StringComparison.Ordinal))
            {
                user.FirebaseUid = firebaseUid;
                needsUpdate = true;
            }

            if (!user.EmailConfirmed)
            {
                var firebaseUser = await firebaseAuthService.GetUserAsync(firebaseUid);
                if (firebaseUser?.EmailVerified == true)
                {
                    user.EmailConfirmed = true;
                    needsUpdate = true;
                }
            }

            user.LastLoginAt = DateTime.UtcNow;
            needsUpdate = true;

            if (needsUpdate)
            {
                var updateResult = await userManager.UpdateAsync(user);
                if (!updateResult.Succeeded)
                {
                    var errors = string.Join(", ", updateResult.Errors.Select(e => e.Description));
                    _logger.LogWarning("Failed to update ApplicationUser {UserId} for Firebase UID {Uid}: {Errors}", user.Id, firebaseUid, errors);
                }
            }
        }

        return user;
    }
}

/// <summary>
/// Extension methods for Firebase authentication middleware
/// </summary>
public static class FirebaseAuthenticationMiddlewareExtensions
{
    /// <summary>
    /// Adds Firebase authentication middleware to the pipeline
    /// </summary>
    public static IApplicationBuilder UseFirebaseAuthentication(this IApplicationBuilder app)
    {
        return app.UseMiddleware<FirebaseAuthenticationMiddleware>();
    }
}
