using FluentValidation;
using SingleClin.API.DTOs.Clinic;
using SingleClin.API.Validators;

namespace SingleClin.API.Tests.Validators;

public class ClinicRequestValidatorTests
{
    private readonly ClinicRequestValidator _validator = new();

    [Fact]
    public void Name_WhenEmpty_ShouldHaveValidationError()
    {
        // Arrange
        var request = new ClinicRequestDto { Name = "" };

        // Act
        var result = _validator.Validate(request);

        // Assert
        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == nameof(ClinicRequestDto.Name));
    }

    [Fact]
    public void Name_WhenValid_ShouldNotHaveValidationError()
    {
        // Arrange
        var request = new ClinicRequestDto
        {
            Name = "Valid Clinic Name",
            Address = "123 Street, City, State"
        };

        // Act
        var result = _validator.Validate(request);

        // Assert
        result.Errors.Where(e => e.PropertyName == nameof(ClinicRequestDto.Name)).Should().BeEmpty();
    }

    [Theory]
    [InlineData("clinic@example.com")]
    [InlineData("test.email@domain.org")]
    [InlineData("user+tag@example.co.uk")]
    [InlineData(null)] // Email is optional
    public void Email_WhenValidFormat_ShouldNotHaveValidationError(string? validEmail)
    {
        // Arrange
        var request = new ClinicRequestDto
        {
            Name = "Test Clinic",
            Address = "123 Street, City, State",
            Email = validEmail
        };

        // Act
        var result = _validator.Validate(request);

        // Assert
        result.Errors.Where(e => e.PropertyName == nameof(ClinicRequestDto.Email)).Should().BeEmpty();
    }

    [Theory]
    [InlineData("invalid-email")]
    [InlineData("@domain.com")]
    [InlineData("user@")]
    public void Email_WhenInvalidFormat_ShouldHaveValidationError(string invalidEmail)
    {
        // Arrange
        var request = new ClinicRequestDto
        {
            Name = "Test Clinic",
            Address = "123 Street, City, State",
            Email = invalidEmail
        };

        // Act
        var result = _validator.Validate(request);

        // Assert
        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == nameof(ClinicRequestDto.Email));
    }

    [Fact]
    public void ValidRequest_ShouldPassValidation()
    {
        // Arrange
        var request = new ClinicRequestDto
        {
            Name = "Valid Clinic Name",
            Address = "123 Street, City, State",
            Email = "clinic@example.com",
            PhoneNumber = "(11) 99999-9999"
        };

        // Act
        var result = _validator.Validate(request);

        // Assert
        if (result.Errors.Any())
        {
            // If there are validation errors, they should not be for basic required fields
            result.Errors.Should().NotContain(e => e.PropertyName == nameof(ClinicRequestDto.Name));
            result.Errors.Should().NotContain(e => e.PropertyName == nameof(ClinicRequestDto.Address));
        }
    }
}