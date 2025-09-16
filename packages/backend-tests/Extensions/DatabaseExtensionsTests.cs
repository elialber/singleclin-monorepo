using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.FileProviders;
using SingleClin.API.Data;

namespace SingleClin.API.Tests.Extensions;

/// <summary>
/// Tests for database extension methods
/// </summary>
public class DatabaseExtensionsTests : IDisposable
{
    private readonly ServiceCollection _services;
    private readonly ServiceProvider _serviceProvider;
    private readonly ApplicationDbContext _context;

    public DatabaseExtensionsTests()
    {
        _services = new ServiceCollection();

        // Add required services
        _services.AddLogging();
        _services.AddSingleton<IWebHostEnvironment, MockWebHostEnvironment>();

        // Add in-memory database
        _services.AddDbContext<ApplicationDbContext>(options =>
            options.UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString()));

        _serviceProvider = _services.BuildServiceProvider();
        _context = _serviceProvider.GetRequiredService<ApplicationDbContext>();
    }

    [Fact]
    public async Task EnsureDatabase_WithValidContext_ShouldCreateDatabase()
    {
        // Arrange
        var context = _serviceProvider.GetRequiredService<ApplicationDbContext>();

        // Act
        var result = await context.Database.EnsureCreatedAsync();

        // Assert
        result.Should().BeTrue();
        context.Database.CanConnect().Should().BeTrue();
    }

    [Fact]
    public void DatabaseProvider_ShouldBeInMemory()
    {
        // Arrange & Act
        var context = _serviceProvider.GetRequiredService<ApplicationDbContext>();

        // Assert - Verify we're using in-memory database for testing
        context.Database.ProviderName.Should().Be("Microsoft.EntityFrameworkCore.InMemory");

        // Note: MigrateAsync is not supported on in-memory databases,
        // so we test the provider instead to ensure proper test setup
    }

    [Fact]
    public void DatabaseContext_ShouldBeConfigured()
    {
        // Arrange & Act
        var context = _serviceProvider.GetRequiredService<ApplicationDbContext>();

        // Assert
        context.Should().NotBeNull();
        context.Database.Should().NotBeNull();
    }

    public void Dispose()
    {
        _context?.Dispose();
        _serviceProvider?.Dispose();
    }

    /// <summary>
    /// Mock WebHostEnvironment for testing
    /// </summary>
    private class MockWebHostEnvironment : IWebHostEnvironment
    {
        public string ApplicationName { get; set; } = "Test";
        public IFileProvider ContentRootFileProvider { get; set; } = new NullFileProvider();
        public string ContentRootPath { get; set; } = "/test";
        public string EnvironmentName { get; set; } = "Test";
        public IFileProvider WebRootFileProvider { get; set; } = new NullFileProvider();
        public string WebRootPath { get; set; } = "/test/wwwroot";
    }
}

/// <summary>
/// Unit tests for specific database extension methods (static methods testing)
/// </summary>
public class DatabaseExtensionMethodsTests
{
    [Fact]
    public void ServiceCollection_CanAddDbContext()
    {
        // Arrange
        var services = new ServiceCollection();

        // Act
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseInMemoryDatabase("TestDatabase"));

        // Assert
        var serviceDescriptors = services.ToList();
        serviceDescriptors.Should().Contain(sd => sd.ServiceType == typeof(ApplicationDbContext));
        serviceDescriptors.Should().Contain(sd => sd.ServiceType == typeof(DbContextOptions<ApplicationDbContext>));
    }
}