using SingleClin.API.Extensions;
using SingleClin.API.Middleware;
using SingleClin.API.Services;
using SingleClin.API.Repositories;
using SingleClin.API.Filters;
using SingleClin.API.HealthChecks;
using SingleClin.API.Data;
using SingleClin.API.Data.Models;
using SingleClin.API.Jobs;
using Microsoft.OpenApi.Models;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Authentication;
using Swashbuckle.AspNetCore.Annotations;
using DotNetEnv;
using FluentValidation;
using FluentValidation.AspNetCore;
using Hangfire;
using Hangfire.PostgreSql;

namespace SingleClin.API;

public class Program
{
    public static async Task Main(string[] args)
    {
        // Load .env file for development
        Env.Load();
        
        var builder = WebApplication.CreateBuilder(args);

        // Add services to the container.
        builder.Services.AddControllers();

        // Add FluentValidation
        builder.Services.AddFluentValidationAutoValidation()
            .AddFluentValidationClientsideAdapters()
            .AddValidatorsFromAssemblyContaining<Program>();
        
        // Add Entity Framework Core with PostgreSQL
        builder.Services.AddSingleton<SingleClin.API.Data.Interceptors.AuditingInterceptor>();
        builder.Services.AddDbContext<ApplicationDbContext>((serviceProvider, options) =>
        {
            options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"))
                .EnableSensitiveDataLogging(builder.Environment.IsDevelopment())
                .EnableDetailedErrors(builder.Environment.IsDevelopment());
            
            // Add auditing interceptor in development
            if (builder.Environment.IsDevelopment())
            {
                var auditingInterceptor = serviceProvider.GetRequiredService<SingleClin.API.Data.Interceptors.AuditingInterceptor>();
                options.AddInterceptors(auditingInterceptor);
            }
        });

        // Configure ASP.NET Core Identity
        builder.Services.AddIdentity<ApplicationUser, IdentityRole<Guid>>(options =>
        {
            // Password settings
            options.Password.RequireDigit = true;
            options.Password.RequiredLength = 8;
            options.Password.RequireNonAlphanumeric = true;
            options.Password.RequireUppercase = true;
            options.Password.RequireLowercase = true;
            options.Password.RequiredUniqueChars = 6;

            // Lockout settings
            options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(5);
            options.Lockout.MaxFailedAccessAttempts = 5;
            options.Lockout.AllowedForNewUsers = true;

            // User settings
            options.User.RequireUniqueEmail = true;
            options.User.AllowedUserNameCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._@+";
            
            // Sign in settings
            options.SignIn.RequireConfirmedEmail = false; // Set to true in production
            options.SignIn.RequireConfirmedPhoneNumber = false;
        })
        .AddEntityFrameworkStores<ApplicationDbContext>()
        .AddDefaultTokenProviders();
        
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
        builder.Services.AddScoped<IRefreshTokenService, RefreshTokenService>();
        builder.Services.AddScoped<IAuthService, AuthService>();
        builder.Services.AddScoped<IFirebaseAuthService, FirebaseAuthService>();

        // Add Plan services
        builder.Services.AddScoped<IPlanRepository, PlanRepository>();
        builder.Services.AddScoped<IPlanService, PlanService>();

        // Add Redis caching
        builder.Services.AddStackExchangeRedisCache(options =>
        {
            options.Configuration = builder.Configuration.GetSection("Redis:ConnectionString").Value;
            options.InstanceName = builder.Configuration.GetSection("Redis:InstanceName").Value ?? "SingleClin";
        });

        // Add in-memory caching for reports
        builder.Services.AddMemoryCache();

        // Add Redis service for QR Code nonce management
        builder.Services.AddScoped<IRedisService, RedisService>();

        // Add QR Code token service
        builder.Services.AddScoped<IQRCodeTokenService, QRCodeTokenService>();

        // Add QR Code generator service
        builder.Services.AddScoped<IQRCodeGeneratorService, QRCodeGeneratorService>();

        // Add QR Code orchestrator service
        builder.Services.AddScoped<IQRCodeService, QRCodeService>();

        // Add QR Code validation service
        builder.Services.AddScoped<IQRCodeValidationService, QRCodeValidationService>();

        // Add claims transformation service
        builder.Services.AddScoped<IClaimsTransformation, ClaimsTransformationService>();

        // Configure notification providers
        builder.Services.Configure<FcmOptions>(
            builder.Configuration.GetSection(FcmOptions.SectionName));
        builder.Services.Configure<SendGridOptions>(
            builder.Configuration.GetSection(SendGridOptions.SectionName));

        // Add notification providers
        builder.Services.AddScoped<IPushNotificationProvider, FcmProvider>();
        builder.Services.AddScoped<IEmailNotificationProvider, SendGridProvider>();
        
        // Add email template service
        builder.Services.AddScoped<IEmailTemplateService, EmailTemplateService>();
        
        // Add notification services
        builder.Services.AddScoped<INotificationRepository, NotificationRepository>();
        builder.Services.AddScoped<INotificationService, NotificationService>();
        
        // Add notification preferences services
        builder.Services.AddScoped<IUserNotificationPreferencesRepository, UserNotificationPreferencesRepository>();
        builder.Services.AddScoped<INotificationPreferencesService, NotificationPreferencesService>();
        
        // Configure notification options
        builder.Services.Configure<NotificationOptions>(
            builder.Configuration.GetSection(NotificationOptions.SectionName));
        
        // Register notification providers collection
        builder.Services.AddScoped<IEnumerable<INotificationProvider>>(provider =>
            new List<INotificationProvider>
            {
                provider.GetRequiredService<IPushNotificationProvider>(),
                provider.GetRequiredService<IEmailNotificationProvider>()
            });

        // Add Hangfire services
        builder.Services.AddHangfire(configuration => configuration
            .SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
            .UseSimpleAssemblyNameTypeSerializer()
            .UseRecommendedSerializerSettings()
            .UsePostgreSqlStorage(options =>
            {
                options.UseNpgsqlConnection(builder.Configuration.GetConnectionString("DefaultConnection"));
            }));

        // Add Hangfire server
        builder.Services.AddHangfireServer(options =>
        {
            options.ServerName = $"SingleClin-{Environment.MachineName}";
            options.WorkerCount = Environment.ProcessorCount; // Scale with CPU cores
            options.Queues = new[] { "default", "notifications" }; // Separate queue for notifications
        });

        // Register background jobs
        builder.Services.AddScoped<BalanceCheckJob>();

        // Add Report Service
        builder.Services.AddScoped<IReportService, ReportService>();

        // Add Export Service
        builder.Services.AddScoped<IExportService, ExportService>();

        // Configure authorization policies
        builder.Services.AddAuthorization(options =>
        {
            // Role-based policies
            options.AddPolicy("RequirePatientRole", policy => 
                policy.RequireClaim("role", "Patient"));
            
            options.AddPolicy("RequireClinicRole", policy => 
                policy.RequireClaim("role", "ClinicOrigin", "ClinicPartner"));
            
            options.AddPolicy("RequireAdminRole", policy => 
                policy.RequireClaim("role", "Administrator"));

            // Clinic owner policy - requires clinic role and clinicId claim
            options.AddPolicy("RequireClinicOwner", policy =>
            {
                policy.RequireAuthenticatedUser();
                policy.RequireAssertion(context =>
                {
                    var roleClaim = context.User.FindFirst("role")?.Value;
                    var isAdmin = roleClaim == "Administrator";
                    var isClinicUser = roleClaim == "ClinicOrigin" || roleClaim == "ClinicPartner";
                    var hasClinicId = context.User.HasClaim(c => c.Type == "clinicId");
                    
                    return isAdmin || (isClinicUser && hasClinicId);
                });
            });

            // Admin or clinic owner policy
            options.AddPolicy("RequireAdminOrClinicOwner", policy =>
            {
                policy.RequireAuthenticatedUser();
                policy.RequireAssertion(context =>
                {
                    var roleClaim = context.User.FindFirst("role")?.Value;
                    var isAdmin = roleClaim == "Administrator";
                    var isClinicUser = roleClaim == "ClinicOrigin" || roleClaim == "ClinicPartner";
                    var hasClinicId = context.User.HasClaim(c => c.Type == "clinicId");
                    
                    return isAdmin || (isClinicUser && hasClinicId);
                });
            });

            // Permission-based policies
            options.AddPolicy("CanManageUsers", policy =>
                policy.RequireClaim("permissions", "users.manage"));
            
            options.AddPolicy("CanManageClinics", policy =>
                policy.RequireClaim("permissions", "clinics.manage"));
            
            options.AddPolicy("CanValidateQR", policy =>
                policy.RequireClaim("permissions", "qr.validate"));
            
            options.AddPolicy("CanGenerateQR", policy =>
                policy.RequireClaim("permissions", "qr.generate"));

            // Active user policy
            options.AddPolicy("RequireActiveUser", policy =>
                policy.RequireClaim("isActive", "True"));
        });

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
                tags: new[] { "firebase", "auth" })
            .AddCheck<SingleClin.API.HealthChecks.RedisHealthCheck>("redis",
                failureStatus: HealthStatus.Degraded,
                tags: new[] { "redis", "cache", "ready" })
            .AddDbContextCheck<ApplicationDbContext>("database",
                failureStatus: HealthStatus.Unhealthy,
                tags: new[] { "database", "ready" });

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
            
            // Add Hangfire Dashboard in development
            app.UseHangfireDashboard("/hangfire", new DashboardOptions
            {
                Authorization = new[] { new Hangfire.Dashboard.LocalRequestsOnlyAuthorizationFilter() },
                DisplayStorageConnectionString = false,
                DashboardTitle = "SingleClin Background Jobs"
            });
        }

        app.UseHttpsRedirection();

        // Add global exception handler
        app.UseGlobalExceptionHandler();

        // Add CORS
        app.UseCors("AllowSpecificOrigins");

        // Add custom JWT middleware
        app.UseMiddleware<JwtAuthenticationMiddleware>();

        // Add clinic rate limiting middleware
        app.UseMiddleware<ClinicRateLimitingMiddleware>();

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

        // Configure database migrations and seeding
        await app.ConfigureDatabaseAsync();

        // Schedule recurring jobs
        var recurringJobManager = app.Services.GetRequiredService<IRecurringJobManager>();
        
        // Schedule balance check job to run every 4 hours
        recurringJobManager.AddOrUpdate<BalanceCheckJob>(
            "balance-check-job",
            job => job.ExecuteAsync(),
            "0 */4 * * *", // Every 4 hours at minute 0
            TimeZoneInfo.Local);

        await app.RunAsync();
    }
}

// Keep the WeatherForecast record for now
record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}