using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;

namespace SingleClin.API.Tests.Helpers;

/// <summary>
/// Factory for creating test database contexts
/// </summary>
public static class TestDbContextFactory
{
    /// <summary>
    /// Creates an in-memory database context for testing
    /// </summary>
    public static ApplicationDbContext CreateInMemoryDbContext(string? databaseName = null)
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(databaseName: databaseName ?? Guid.NewGuid().ToString())
            .Options;

        var context = new ApplicationDbContext(options);

        // Ensure database is created
        context.Database.EnsureCreated();

        return context;
    }

    /// <summary>
    /// Seeds the database with test data for simple tests
    /// </summary>
    public static async Task SeedTestDataAsync(ApplicationDbContext context)
    {
        // Simple test data seeding - can be expanded as needed
        await context.SaveChangesAsync();
    }
}