using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SingleClin.API.Controllers;

namespace SingleClin.API.Tests.Controllers;

public class AuthControllerTests
{
    [Fact]
    public void AuthController_ShouldHaveCorrectAttributes()
    {
        // Arrange & Act
        var controllerType = typeof(AuthController);

        // Assert
        controllerType.Should().BeDecoratedWith<ApiControllerAttribute>();
        controllerType.Should().BeDecoratedWith<RouteAttribute>(
            attr => attr.Template == "api/[controller]");
        controllerType.Should().BeDecoratedWith<ProducesAttribute>(
            attr => attr.ContentTypes.Contains("application/json"));
    }

    [Fact]
    public void Register_ShouldHaveCorrectAttributes()
    {
        // Arrange
        var method = typeof(AuthController).GetMethod("Register");

        // Assert
        method.Should().NotBeNull();
        method!.Should().BeDecoratedWith<HttpPostAttribute>(attr => attr.Template == "register");
        method!.Should().BeDecoratedWith<AllowAnonymousAttribute>();
    }

    [Fact]
    public void AuthController_ShouldHavePublicMethods()
    {
        // Arrange
        var methods = typeof(AuthController).GetMethods()
            .Where(m => m.IsPublic && m.DeclaringType == typeof(AuthController))
            .ToList();

        // Assert
        methods.Should().NotBeEmpty("AuthController should have public methods");
        methods.Should().Contain(m => m.Name == "Register", "Should have Register method");
    }

    [Fact]
    public void AuthController_ShouldHaveRequiredDependencies()
    {
        // Arrange
        var constructors = typeof(AuthController).GetConstructors();

        // Assert
        constructors.Should().HaveCount(1);

        var constructor = constructors[0];
        var parameters = constructor.GetParameters();

        parameters.Should().Contain(p => p.ParameterType.Name.Contains("IAuthService"));
        parameters.Should().Contain(p => p.ParameterType.Name.Contains("ILogger"));
        parameters.Should().Contain(p => p.ParameterType.Name.Contains("IWebHostEnvironment"));
    }
}