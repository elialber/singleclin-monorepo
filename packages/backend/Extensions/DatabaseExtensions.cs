using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;

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
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
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
            
            // Seed initial data
            logger.LogInformation("Seeding database...");
            var seeder = new DatabaseSeeder(context);
            await seeder.SeedAsync();
            logger.LogInformation("Database seeding completed");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "An error occurred while configuring the database");
            throw;
        }
    }
}