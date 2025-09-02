using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Data.Seeders;

namespace SingleClin.API.Extensions;

/// <summary>
/// Extension methods for database configuration
/// </summary>
public static class DatabaseExtensions
{
    /// <summary>
    /// Configure database migrations and seeding
    /// </summary>
    public static async Task ConfigureDatabaseAsync(this WebApplication app)
    {
        using var scope = app.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
        
        try
        {
            logger.LogInformation("Checking database migrations...");
            
            // Apply pending migrations in development
            if (app.Environment.IsDevelopment())
            {
                var pendingMigrations = await context.Database.GetPendingMigrationsAsync();
                if (pendingMigrations.Any())
                {
                    logger.LogInformation("Applying {Count} pending migrations...", pendingMigrations.Count());
                    await context.Database.MigrateAsync();
                    logger.LogInformation("Migrations applied successfully");
                }
            }
            else
            {
                // In production, just ensure database exists but don't auto-migrate
                await context.Database.EnsureCreatedAsync();
            }
            
            // Seed roles and default admin user
            logger.LogInformation("Seeding roles and default admin...");
            await RoleSeeder.SeedRolesAsync(scope.ServiceProvider);
            await RoleSeeder.SeedDefaultAdminAsync(scope.ServiceProvider);
            logger.LogInformation("Roles and admin seeding completed");
            
            // Create missing AppDbContext tables to resolve schema conflicts
            logger.LogInformation("Creating missing AppDbContext tables...");
            try
            {
                var appContext = scope.ServiceProvider.GetService<AppDbContext>();
                if (appContext != null)
                {
                    await EnsureTablesExist.CreateMissingTablesAsync(appContext);
                    logger.LogInformation("AppDbContext tables created successfully");
                }
            }
            catch (Exception tableEx)
            {
                logger.LogWarning(tableEx, "Could not create AppDbContext tables - will use mock data");
            }
            
            logger.LogInformation("Database seeding completed");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "An error occurred while configuring the database");
            throw;
        }
    }
}