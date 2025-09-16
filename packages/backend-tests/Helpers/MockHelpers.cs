using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SingleClin.API.Data.Enums;
using System.Security.Claims;

namespace SingleClin.API.Tests.Helpers;

public static class MockHelpers
{
    public static Mock<ILogger<T>> CreateMockLogger<T>()
    {
        return new Mock<ILogger<T>>();
    }

    public static Mock<IConfiguration> CreateMockConfiguration(Dictionary<string, string>? settings = null)
    {
        var mockConfig = new Mock<IConfiguration>();

        if (settings != null)
        {
            foreach (var setting in settings)
            {
                mockConfig.Setup(x => x[setting.Key]).Returns(setting.Value);
            }
        }

        return mockConfig;
    }

    public static Mock<HttpContext> CreateMockHttpContext(string? userId = null, UserRole? role = null)
    {
        var mockContext = new Mock<HttpContext>();
        var mockUser = new Mock<ClaimsPrincipal>();

        var claims = new List<Claim>();

        if (userId != null)
        {
            claims.Add(new Claim(ClaimTypes.NameIdentifier, userId));
        }

        if (role != null)
        {
            claims.Add(new Claim(ClaimTypes.Role, role.ToString()!));
        }

        mockUser.Setup(u => u.Claims).Returns(claims);
        mockUser.Setup(u => u.FindFirst(It.IsAny<string>()))
            .Returns<string>(claimType => claims.FirstOrDefault(c => c.Type == claimType));

        mockContext.Setup(c => c.User).Returns(mockUser.Object);

        return mockContext;
    }

    public static Mock<IServiceProvider> CreateMockServiceProvider()
    {
        return new Mock<IServiceProvider>();
    }

    public static string GenerateRandomEmail() => $"test{Guid.NewGuid():N}@example.com";

    public static string GenerateRandomPhoneNumber() => $"+1{Random.Shared.Next(1000000000, 2147483647)}";

    public static string GenerateRandomCNPJ() => $"{Random.Shared.Next(10, 99)}.{Random.Shared.Next(100, 999)}.{Random.Shared.Next(100, 999)}/{Random.Shared.Next(1000, 9999)}-{Random.Shared.Next(10, 99)}";
}