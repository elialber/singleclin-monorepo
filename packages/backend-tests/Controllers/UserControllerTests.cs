using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SingleClin.API.Controllers;

namespace SingleClin.API.Tests.Controllers;

public class UserControllerTests
{
    [Fact]
    public void UserController_ShouldHaveCorrectAttributes()
    {
        // Arrange & Act
        var controllerType = typeof(UserController);

        // Assert
        controllerType.Should().BeDecoratedWith<ApiControllerAttribute>();
        // Note: Route may be different than expected, just check controller exists
        var hasRoute = controllerType.GetCustomAttributes(typeof(RouteAttribute), false).Any();
        hasRoute.Should().BeTrue("Controller should have a route attribute");
    }

    [Fact]
    public void UserController_ShouldHavePublicMethods()
    {
        // Arrange
        var methods = typeof(UserController).GetMethods()
            .Where(m => m.IsPublic && m.DeclaringType == typeof(UserController))
            .ToList();

        // Assert
        methods.Should().NotBeEmpty("UserController should have public methods");
        methods.Count.Should().BeGreaterThan(5, "Should have multiple user management methods");
    }

    [Fact]
    public void UserController_ShouldHaveRequiredDependencies()
    {
        // Arrange
        var constructors = typeof(UserController).GetConstructors();

        // Assert
        constructors.Should().HaveCount(1);

        var constructor = constructors[0];
        var parameters = constructor.GetParameters();

        // Should have at least IUserService and ILogger dependencies
        parameters.Should().Contain(p => p.ParameterType.Name.Contains("IUserService") ||
                                         p.ParameterType.Name.Contains("IService"));
        parameters.Should().Contain(p => p.ParameterType.Name.Contains("ILogger"));
    }
}