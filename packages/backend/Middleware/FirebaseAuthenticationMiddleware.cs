using System.Security.Claims;
using SingleClin.API.Services;

namespace SingleClin.API.Middleware;

/// <summary>
/// Middleware to validate Firebase tokens and convert them to internal JWT tokens
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
        // Check if request has Firebase token header
        if (context.Request.Headers.TryGetValue("X-Firebase-Token", out var firebaseToken))
        {
            using var scope = _serviceProvider.CreateScope();
            var firebaseAuthService = scope.ServiceProvider.GetRequiredService<IFirebaseAuthService>();
            var authService = scope.ServiceProvider.GetRequiredService<IAuthService>();

            try
            {
                // Verify Firebase token
                var decodedToken = await firebaseAuthService.VerifyIdTokenAsync(firebaseToken!);
                if (decodedToken != null)
                {
                    // Get email from token
                    var email = decodedToken.Claims.ContainsKey("email") ? decodedToken.Claims["email"]?.ToString() : null;
                    if (!string.IsNullOrEmpty(email))
                    {
                        // Try to login with Firebase token
                        var result = await authService.FirebaseLoginAsync(
                            new DTOs.Auth.FirebaseLoginDto { FirebaseToken = firebaseToken! },
                            context.Connection.RemoteIpAddress?.ToString()
                        );

                        if (result.Success && result.Response != null)
                        {
                            // Add the JWT token to the Authorization header
                            context.Request.Headers["Authorization"] = $"Bearer {result.Response.AccessToken}";
                            _logger.LogInformation("Firebase token validated and converted to JWT for user: {Email}", email);
                        }
                        else
                        {
                            _logger.LogWarning("Failed to convert Firebase token to JWT: {Error}", result.Error);
                        }
                    }
                }
                else
                {
                    _logger.LogWarning("Invalid Firebase token provided");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing Firebase token");
                // Continue without authentication - let the authorization policies handle it
            }
        }

        await _next(context);
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