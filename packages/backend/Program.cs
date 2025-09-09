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
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Azure.Storage.Blobs;

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

        // Add AppDbContext with the same configuration
        builder.Services.AddDbContext<AppDbContext>((serviceProvider, options) =>
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
                            "http://localhost:3001", // React web admin (alternative port)
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
        
        // Firebase initialization will be done after app build

        // Add Plan services
        builder.Services.AddScoped<IPlanRepository, PlanRepository>();
        builder.Services.AddScoped<IPlanService, PlanService>();

        // Add Clinic services
        builder.Services.AddScoped<IClinicRepository, ClinicRepository>();
        builder.Services.AddScoped<IClinicService, ClinicService>();

        // Add Transaction services
        builder.Services.AddScoped<ITransactionRepository, TransactionRepository>();
        builder.Services.AddScoped<ITransactionService, TransactionService>();

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

        // Add User Service
        builder.Services.AddScoped<IUserService, UserService>();

        // Add Azure Blob Storage Client
        builder.Services.AddSingleton<BlobServiceClient>(provider =>
        {
            var connectionString = builder.Configuration.GetSection("AzureStorage")["ConnectionString"];
            return new BlobServiceClient(connectionString);
        });

        // Add Image Upload Service with Azure Blob Storage
        builder.Services.AddScoped<IImageUploadService, ImageUploadService>();
        
        // Add image migration service
        builder.Services.AddScoped<ImageMigrationService>();

        // Configure authorization policies
        builder.Services.AddAuthorization(options =>
        {
            // Role-based policies
            options.AddPolicy("RequirePatientRole", policy => 
                policy.RequireClaim("role", "Patient"));
            
            options.AddPolicy("RequireClinicRole", policy => 
                policy.RequireClaim("role", "ClinicOrigin", "ClinicPartner"));
            
            options.AddPolicy("RequireAdministratorRole", policy => 
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
            
            // Use full type names to avoid schema conflicts
            c.CustomSchemaIds(type => type.FullName?.Replace('+', '.'));
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

        // Initialize Firebase after app build
        {
            var logger = app.Services.GetRequiredService<ILogger<Program>>();
            var configuration = app.Configuration;
            
            logger.LogInformation("=== Initializing Firebase ===");
            logger.LogInformation("Environment: {Environment}", app.Environment.EnvironmentName);
            
            try
            {
                // Debug configuration sources
                logger.LogInformation("Configuration Sources:");
                var configRoot = configuration as IConfigurationRoot;
                if (configRoot != null)
                {
                    foreach (var provider in configRoot.Providers)
                    {
                        logger.LogInformation("  Provider: {Provider}", provider.GetType().Name);
                    }
                }
                
                // Test configuration loading
                logger.LogInformation("Testing configuration:");
                logger.LogInformation("  ConnectionString: {HasValue}", !string.IsNullOrEmpty(configuration.GetConnectionString("DefaultConnection")));
                logger.LogInformation("  JWT:SecretKey: {HasValue}", !string.IsNullOrEmpty(configuration["JWT:SecretKey"]));
                
                // Debug Firebase configuration
                var firebaseSection = configuration.GetSection("Firebase");
                logger.LogInformation("Firebase Section exists: {Exists}", firebaseSection.Exists());
                logger.LogInformation("Firebase Section path: {Path}", firebaseSection.Path);
                logger.LogInformation("Firebase Section children:");
                foreach (var child in firebaseSection.GetChildren())
                {
                    logger.LogInformation("  {Key}: '{Value}' (Path: {Path})", child.Key, child.Value, child.Path);
                    
                    // For nested sections, log their children too
                    if (child.GetChildren().Any())
                    {
                        foreach (var subchild in child.GetChildren())
                        {
                            logger.LogInformation("    {Key}: '{Value}'", subchild.Key, subchild.Value);
                        }
                    }
                }
                
                // Try different ways to access ProjectId
                var projectId1 = configuration["Firebase:ProjectId"];
                var projectId2 = configuration.GetValue<string>("Firebase:ProjectId");
                var projectId3 = firebaseSection["ProjectId"];
                var projectId4 = firebaseSection.GetValue<string>("ProjectId");
                
                logger.LogInformation("ProjectId access methods:");
                logger.LogInformation("  Method 1 (indexer): '{Value}'", projectId1 ?? "NULL");
                logger.LogInformation("  Method 2 (GetValue): '{Value}'", projectId2 ?? "NULL");
                logger.LogInformation("  Method 3 (section indexer): '{Value}'", projectId3 ?? "NULL");
                logger.LogInformation("  Method 4 (section GetValue): '{Value}'", projectId4 ?? "NULL");
                
                var projectId = projectId1 ?? projectId2 ?? projectId3 ?? projectId4;
                var serviceAccountPath = configuration["Firebase:ServiceAccountKeyPath"];
                
                logger.LogInformation("Firebase Configuration:");
                logger.LogInformation("  ProjectId: '{ProjectId}'", projectId ?? "NULL");
                logger.LogInformation("  ServiceAccountKeyPath: '{Path}'", serviceAccountPath ?? "NULL");
                logger.LogInformation("  Current Directory: {Dir}", Directory.GetCurrentDirectory());
                
                if (!string.IsNullOrEmpty(projectId))
                {
                    if (FirebaseApp.DefaultInstance == null)
                    {
                        if (!string.IsNullOrEmpty(serviceAccountPath) && File.Exists(serviceAccountPath))
                        {
                            logger.LogInformation("Service account file exists: {Exists}", File.Exists(serviceAccountPath));
                            logger.LogInformation("Initializing Firebase Admin SDK...");
                            
                            var credential = GoogleCredential.FromFile(serviceAccountPath);
                            FirebaseApp.Create(new AppOptions
                            {
                                Credential = credential,
                                ProjectId = projectId
                            });
                            
                            logger.LogInformation("✅ Firebase Admin SDK initialized successfully!");
                            logger.LogInformation("Firebase Project: {ProjectId}", FirebaseApp.DefaultInstance.Options.ProjectId);
                        }
                        else
                        {
                            logger.LogError("Firebase service account file not found!");
                            logger.LogError("  Expected path: {Path}", serviceAccountPath);
                            logger.LogError("  File exists: {Exists}", File.Exists(serviceAccountPath));
                        }
                    }
                    else
                    {
                        logger.LogInformation("Firebase already initialized for project: {ProjectId}", 
                            FirebaseApp.DefaultInstance.Options.ProjectId);
                    }
                }
                else
                {
                    logger.LogError("Firebase ProjectId is NULL or empty!");
                }
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to initialize Firebase");
            }
            
            logger.LogInformation("=== Firebase Initialization Complete ===");
        }

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

        // Enable static files serving for uploaded images
        app.UseStaticFiles();

        app.UseHttpsRedirection();

        // Add global exception handler
        app.UseGlobalExceptionHandler();

        // Add CORS
        app.UseCors("AllowSpecificOrigins");

        // Add custom JWT middleware
        app.UseMiddleware<JwtAuthenticationMiddleware>();

        // Add Firebase authentication middleware
        app.UseFirebaseAuthentication();

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