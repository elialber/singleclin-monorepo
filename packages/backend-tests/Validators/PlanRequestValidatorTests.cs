using FluentValidation;
using SingleClin.API.DTOs.Plan;
using SingleClin.API.Validators;

namespace SingleClin.API.Tests.Validators;

public class PlanRequestValidatorTests
{
    private readonly PlanRequestValidator _validator = new();

    [Fact]
    public void Name_WhenEmpty_ShouldHaveValidationError()
    {
        // Arrange
        var request = new PlanRequestDto { Name = "" };

        // Act
        var result = _validator.Validate(request);

        // Assert
        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == nameof(PlanRequestDto.Name));
    }

    [Fact]
    public void Name_WhenValid_ShouldNotHaveValidationError()
    {
        // Arrange
        var request = new PlanRequestDto
        {
            Name = "Valid Plan Name",
            Description = "Valid description",
            Price = 100.50m,
            Credits = 10,
            ValidityDays = 30
        };

        // Act
        var result = _validator.Validate(request);

        // Assert
        result.Errors.Where(e => e.PropertyName == nameof(PlanRequestDto.Name)).Should().BeEmpty();
    }

    [Fact]
    public void Price_WhenZero_ShouldNotHaveValidationError()
    {
        // Arrange
        var request = new PlanRequestDto
        {
            Name = "Test Plan",
            Description = "Test description",
            Price = 0,
            Credits = 10,
            ValidityDays = 30
        };

        // Act
        var result = _validator.Validate(request);

        // Assert - Price can be 0 according to validator (GreaterThanOrEqualTo(0))
        result.Errors.Where(e => e.PropertyName == nameof(PlanRequestDto.Price)).Should().BeEmpty();
    }

    [Fact]
    public void Price_WhenNegative_ShouldHaveValidationError()
    {
        // Arrange
        var request = new PlanRequestDto
        {
            Name = "Test Plan",
            Description = "Test description",
            Price = -10.50m,
            Credits = 10,
            ValidityDays = 30
        };

        // Act
        var result = _validator.Validate(request);

        // Assert
        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == nameof(PlanRequestDto.Price));
    }

    [Theory]
    [InlineData(10.50)]
    [InlineData(100)]
    [InlineData(1500.99)]
    public void Price_WhenValid_ShouldNotHaveValidationError(decimal validPrice)
    {
        // Arrange
        var request = new PlanRequestDto
        {
            Name = "Test Plan",
            Description = "Test description",
            Price = validPrice,
            Credits = 10,
            ValidityDays = 30
        };

        // Act
        var result = _validator.Validate(request);

        // Assert
        result.Errors.Where(e => e.PropertyName == nameof(PlanRequestDto.Price)).Should().BeEmpty();
    }

    [Fact]
    public void Credits_WhenZero_ShouldHaveValidationError()
    {
        // Arrange
        var request = new PlanRequestDto
        {
            Name = "Test Plan",
            Description = "Test description",
            Price = 100.50m,
            Credits = 0,
            ValidityDays = 30
        };

        // Act
        var result = _validator.Validate(request);

        // Assert
        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == nameof(PlanRequestDto.Credits));
    }

    [Fact]
    public void Credits_WhenNegative_ShouldHaveValidationError()
    {
        // Arrange
        var request = new PlanRequestDto
        {
            Name = "Test Plan",
            Description = "Test description",
            Price = 100.50m,
            Credits = -5,
            ValidityDays = 30
        };

        // Act
        var result = _validator.Validate(request);

        // Assert
        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == nameof(PlanRequestDto.Credits));
    }

    [Theory]
    [InlineData(1)]
    [InlineData(10)]
    [InlineData(100)]
    public void Credits_WhenValid_ShouldNotHaveValidationError(int validCredits)
    {
        // Arrange
        var request = new PlanRequestDto
        {
            Name = "Test Plan",
            Description = "Test description",
            Price = 100.50m,
            Credits = validCredits,
            ValidityDays = 30
        };

        // Act
        var result = _validator.Validate(request);

        // Assert
        result.Errors.Where(e => e.PropertyName == nameof(PlanRequestDto.Credits)).Should().BeEmpty();
    }

    [Fact]
    public void ValidRequest_ShouldPassValidation()
    {
        // Arrange
        var request = new PlanRequestDto
        {
            Name = "Premium Plan",
            Description = "Premium healthcare plan with extended coverage",
            Price = 299.99m,
            Credits = 50,
            ValidityDays = 365
        };

        // Act
        var result = _validator.Validate(request);

        // Assert
        result.IsValid.Should().BeTrue();
        result.Errors.Should().BeEmpty();
    }
}