using System.Text;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using SingleClin.API.Data.Models;
using SingleClin.API.Data.Enums;

namespace SingleClin.API.Extensions;

public static class AuthenticationExtensions
{
    public static IServiceCollection AddFirebaseAuthentication(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // Firebase initialization moved to FirebaseAuthService to centralize the logic

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
            // Add role-based policies based on UserRole enum
            options.AddPolicy("AdminOnly", policy => policy.RequireRole(UserRole.Administrator.ToString()));
            options.AddPolicy("ClinicOnly", policy => policy.RequireRole(
                UserRole.ClinicOrigin.ToString(), 
                UserRole.ClinicPartner.ToString()));
            options.AddPolicy("PatientOnly", policy => policy.RequireRole(UserRole.Patient.ToString()));
            
            // Add custom policies
            options.AddPolicy("ClinicOwner", policy =>
                policy.RequireAssertion(context =>
                    context.User.HasClaim(c => c.Type == "clinicId") &&
                    !string.IsNullOrEmpty(context.User.FindFirst("clinicId")?.Value)));
            
            // Combined policy for any authenticated user
            options.AddPolicy("Authenticated", policy => policy.RequireAuthenticatedUser());
        });

        return services;
    }
}