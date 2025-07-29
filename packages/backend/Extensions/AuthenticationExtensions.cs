using System.Text;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

namespace SingleClin.API.Extensions;

public static class AuthenticationExtensions
{
    public static IServiceCollection AddFirebaseAuthentication(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // Initialize Firebase Admin SDK (optional - if not configured, only internal JWT will work)
        var firebaseProjectId = configuration["Firebase:ProjectId"];
        var serviceAccountPath = configuration["Firebase:ServiceAccountPath"];

        if (!string.IsNullOrEmpty(firebaseProjectId))
        {
            try
            {
                // Initialize Firebase only if not already initialized
                if (FirebaseApp.DefaultInstance == null)
                {
                    FirebaseApp.Create(new AppOptions
                    {
                        Credential = string.IsNullOrEmpty(serviceAccountPath) || !File.Exists(serviceAccountPath)
                            ? GoogleCredential.GetApplicationDefault()
                            : GoogleCredential.FromFile(serviceAccountPath),
                        ProjectId = firebaseProjectId
                    });
                }
            }
            catch (Exception ex)
            {
                // Log warning but don't fail the application startup
                var logger = services.BuildServiceProvider().GetService<ILogger<Program>>();
                logger?.LogWarning(ex, "Failed to initialize Firebase Admin SDK. Only internal JWT authentication will be available.");
            }
        }

        // Configure JWT Bearer authentication
        var key = Encoding.ASCII.GetBytes(configuration["JWT:SecretKey"] ?? 
            throw new InvalidOperationException("JWT:SecretKey is not configured"));

        services.AddAuthentication(options =>
        {
            options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        })
        .AddJwtBearer(options =>
        {
            options.RequireHttpsMetadata = false; // Set to true in production
            options.SaveToken = true;
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateIssuer = true,
                ValidIssuer = configuration["JWT:Issuer"],
                ValidateAudience = true,
                ValidAudience = configuration["JWT:Audience"],
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            };

            // Add custom logic for Firebase token validation
            options.Events = new JwtBearerEvents
            {
                OnMessageReceived = context =>
                {
                    // Allow tokens to be passed as query string for SignalR or other scenarios
                    var accessToken = context.Request.Query["access_token"];
                    if (!string.IsNullOrEmpty(accessToken))
                    {
                        context.Token = accessToken;
                    }
                    return Task.CompletedTask;
                },
                OnAuthenticationFailed = context =>
                {
                    if (context.Exception.GetType() == typeof(SecurityTokenExpiredException))
                    {
                        context.Response.Headers.Append("Token-Expired", "true");
                    }
                    return Task.CompletedTask;
                }
            };
        });

        // Add authorization
        services.AddAuthorization(options =>
        {
            // Add role-based policies
            options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
            options.AddPolicy("ClinicOnly", policy => policy.RequireRole("Clinic", "ClinicOrigin", "ClinicPartner"));
            options.AddPolicy("PatientOnly", policy => policy.RequireRole("Patient"));
            
            // Add custom policies
            options.AddPolicy("ClinicOwner", policy =>
                policy.RequireAssertion(context =>
                    context.User.HasClaim(c => c.Type == "clinicId") &&
                    !string.IsNullOrEmpty(context.User.FindFirst("clinicId")?.Value)));
        });

        return services;
    }
}