using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SingleClin.API.Controllers;

namespace SingleClin.API.Tests.Controllers;

public class ClinicControllerTests
{
    [Fact]
    public void ClinicController_ShouldHaveCorrectAttributes()
    {
        // Arrange & Act
        var controllerType = typeof(ClinicController);

        // Assert
        controllerType.Should().BeDecoratedWith<ApiControllerAttribute>();
        controllerType.Should().BeDecoratedWith<RouteAttribute>(
            attr => attr.Template == "api/[controller]");
        // Note: AuthorizeAttribute may be on specific methods instead of controller level
    }

    [Fact]
    public void ClinicController_ShouldHavePublicMethods()
    {
        // Arrange
        var methods = typeof(ClinicController).GetMethods()
            .Where(m => m.IsPublic && m.DeclaringType == typeof(ClinicController))
            .ToList();

        // Assert
        methods.Should().NotBeEmpty("ClinicController should have public methods");
        methods.Count.Should().BeGreaterThan(5, "Should have multiple clinic management methods");
    }

    [Fact]
    public void ClinicController_ShouldHaveRequiredDependencies()
    {
        // Arrange
        var constructors = typeof(ClinicController).GetConstructors();

        // Assert
        constructors.Should().HaveCount(1);

        var constructor = constructors[0];
        var parameters = constructor.GetParameters();

        // Should have at least IClinicService and ILogger dependencies
        parameters.Should().Contain(p => p.ParameterType.Name.Contains("IClinicService") ||
                                         p.ParameterType.Name.Contains("IService"));
        parameters.Should().Contain(p => p.ParameterType.Name.Contains("ILogger"));
    }
}