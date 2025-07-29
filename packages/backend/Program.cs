using SingleClin.API.Extensions;
using SingleClin.API.Middleware;
using SingleClin.API.Services;
using SingleClin.API.Filters;
using SingleClin.API.HealthChecks;
using Microsoft.OpenApi.Models;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Swashbuckle.AspNetCore.Annotations;

namespace SingleClin.API;

public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // Add services to the container.
        builder.Services.AddControllers();
        
        // Add CORS
        builder.Services.AddCors(options =>
        {
            options.AddPolicy("AllowSpecificOrigins",
                builder =>
                {
                    builder.WithOrigins(
                            "http://localhost:3000", // React web admin
                            "http://localhost:4200", // Alternative frontend
                            "http://localhost:5173", // Vite dev server
                            "capacitor://localhost", // Capacitor mobile
                            "http://localhost"       // Mobile emulator
                        )
                        .AllowAnyHeader()
                        .AllowAnyMethod()
                        .AllowCredentials();
                });
        });

        // Add Firebase authentication and JWT services
        builder.Services.AddFirebaseAuthentication(builder.Configuration);
        builder.Services.AddScoped<IJwtService, JwtService>();

        // Configure Swagger with JWT support
        builder.Services.AddEndpointsApiExplorer();
        builder.Services.AddSwaggerGen(c =>
        {
            c.SwaggerDoc("v1", new OpenApiInfo
            {
                Title = "SingleClin API",
                Version = "v1",
                Description = "API for SingleClin Healthcare Management System",
                Contact = new OpenApiContact
                {
                    Name = "SingleClin Support",
                    Email = "support@singleclin.com"
                },
                License = new OpenApiLicense
                {
                    Name = "Private License",
                    Url = new Uri("https://singleclin.com/license")
                }
            });

            // Add JWT Authentication
            c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
            {
                Description = "JWT Authorization header using the Bearer scheme. Example: \"Authorization: Bearer {token}\"",
                Name = "Authorization",
                In = ParameterLocation.Header,
                Type = SecuritySchemeType.Http,
                Scheme = "bearer",
                BearerFormat = "JWT"
            });

            c.AddSecurityRequirement(new OpenApiSecurityRequirement
            {
                {
                    new OpenApiSecurityScheme
                    {
                        Reference = new OpenApiReference
                        {
                            Type = ReferenceType.SecurityScheme,
                            Id = "Bearer"
                        }
                    },
                    Array.Empty<string>()
                }
            });

            // Include XML comments
            var xmlFilename = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
            var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFilename);
            if (File.Exists(xmlPath))
            {
                c.IncludeXmlComments(xmlPath);
            }

            // Enable annotations
            c.EnableAnnotations();

            // Custom operation filter for better documentation
            c.OperationFilter<SwaggerDefaultValues>();
        });

        // Add health checks
        builder.Services.AddHealthChecks()
            .AddCheck<SingleClin.API.HealthChecks.ApiHealthCheck>("api", tags: new[] { "api", "live" })
            .AddCheck<SingleClin.API.HealthChecks.FirebaseHealthCheck>("firebase", 
                failureStatus: HealthStatus.Degraded,
                tags: new[] { "firebase", "auth" });

        var app = builder.Build();

        // Configure the HTTP request pipeline.
        if (app.Environment.IsDevelopment())
        {
            app.UseSwagger();
            app.UseSwaggerUI(c =>
            {
                c.SwaggerEndpoint("/swagger/v1/swagger.json", "SingleClin API V1");
                c.RoutePrefix = string.Empty; // Set Swagger UI at the app's root
                c.DocumentTitle = "SingleClin API Documentation";
                c.DocExpansion(Swashbuckle.AspNetCore.SwaggerUI.DocExpansion.None);
                c.DefaultModelsExpandDepth(-1); // Hide schemas section by default
                c.DisplayRequestDuration();
                c.EnableFilter();
                c.EnableTryItOutByDefault();
                c.ShowCommonExtensions();
            });
        }

        app.UseHttpsRedirection();

        // Add global exception handler
        app.UseGlobalExceptionHandler();

        // Add CORS
        app.UseCors("AllowSpecificOrigins");

        // Add custom JWT middleware
        app.UseMiddleware<JwtAuthenticationMiddleware>();

        // Add authentication & authorization
        app.UseAuthentication();
        app.UseAuthorization();

        app.MapControllers();

        // Map health check endpoints
        app.MapHealthChecks("/health");
        
        // Detailed health check endpoint with JSON response
        app.MapHealthChecks("/health/detailed", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
        {
            ResponseWriter = async (context, report) =>
            {
                context.Response.ContentType = "application/json";
                
                var response = new
                {
                    status = report.Status.ToString(),
                    timestamp = DateTime.UtcNow,
                    duration = report.TotalDuration.TotalMilliseconds,
                    checks = report.Entries.Select(x => new
                    {
                        name = x.Key,
                        status = x.Value.Status.ToString(),
                        description = x.Value.Description,
                        duration = x.Value.Duration.TotalMilliseconds,
                        tags = x.Value.Tags,
                        data = x.Value.Data,
                        exception = x.Value.Exception?.Message
                    })
                };
                
                await context.Response.WriteAsync(
                    System.Text.Json.JsonSerializer.Serialize(response, 
                        new System.Text.Json.JsonSerializerOptions 
                        { 
                            WriteIndented = true,
                            PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
                        }));
            }
        });
        
        // Liveness probe endpoint
        app.MapHealthChecks("/health/live", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
        {
            Predicate = check => check.Tags.Contains("live")
        });
        
        // Readiness probe endpoint  
        app.MapHealthChecks("/health/ready", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
        {
            Predicate = check => check.Tags.Contains("ready") || check.Tags.Contains("firebase")
        });

        app.Run();
    }
}

// Keep the WeatherForecast record for now
record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}