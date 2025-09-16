using Microsoft.AspNetCore.Mvc;
using SingleClin.API.Controllers;

namespace SingleClin.API.Tests.Controllers;

public class HealthControllerTests
{
    private readonly HealthController _controller;

    public HealthControllerTests()
    {
        _controller = new HealthController();
    }

    [Fact]
    public void GetHealthCheckInfo_ShouldReturnOkWithCorrectStructure()
    {
        // Act
        var result = _controller.GetHealthCheckInfo();

        // Assert
        result.Should().BeOfType<OkObjectResult>();

        var okResult = result as OkObjectResult;
        okResult.Should().NotBeNull();
        okResult!.Value.Should().NotBeNull();

        // Convert to JSON to test structure
        var json = System.Text.Json.JsonSerializer.Serialize(okResult.Value);
        json.Should().Contain("SingleClin API Health Check");
        json.Should().Contain("/health");
        json.Should().Contain("/health/live");
        json.Should().Contain("/health/ready");
    }

    [Fact]
    public void TestCors_MethodExists()
    {
        // Arrange
        var method = typeof(HealthController).GetMethod(nameof(HealthController.TestCors));

        // Assert - Test that the method exists and has correct HTTP attributes
        method.Should().NotBeNull();
        method!.Should().BeDecoratedWith<HttpGetAttribute>(attr => attr.Template == "cors-test");
        method!.Should().BeDecoratedWith<HttpOptionsAttribute>(attr => attr.Template == "cors-test");
    }

    [Fact]
    public void Controller_ShouldHaveCorrectAttributes()
    {
        // Arrange & Act
        var controllerType = typeof(HealthController);

        // Assert
        controllerType.Should().BeDecoratedWith<ApiControllerAttribute>();
        controllerType.Should().BeDecoratedWith<RouteAttribute>(
            attr => attr.Template == "api/[controller]");
    }

    [Fact]
    public void GetHealthCheckInfo_ShouldHaveCorrectSwaggerAttributes()
    {
        // Arrange
        var method = typeof(HealthController).GetMethod(nameof(HealthController.GetHealthCheckInfo));

        // Assert
        method.Should().NotBeNull();
        method!.Should().BeDecoratedWith<HttpGetAttribute>(attr => attr.Template == "info");
    }

}