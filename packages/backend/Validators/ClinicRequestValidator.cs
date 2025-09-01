using FluentValidation;
using SingleClin.API.DTOs.Clinic;
using SingleClin.API.Data.Models.Enums;

namespace SingleClin.API.Validators;

/// <summary>
/// Validator for ClinicRequestDto using FluentValidation
/// </summary>
public class ClinicRequestValidator : AbstractValidator<ClinicRequestDto>
{
    public ClinicRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty()
            .WithMessage("Clinic name is required")
            .Length(1, 100)
            .WithMessage("Clinic name must be between 1 and 100 characters")
            .Matches(@"^[\w\s\-_\.À-ÿ]+$")
            .WithMessage("Clinic name can only contain letters (including accents), numbers, spaces, hyphens, underscores, and dots");

        RuleFor(x => x.Type)
            .IsInEnum()
            .WithMessage("Invalid clinic type");

        RuleFor(x => x.Address)
            .NotEmpty()
            .WithMessage("Address is required")
            .Length(1, 500)
            .WithMessage("Address must be between 1 and 500 characters");

        RuleFor(x => x.PhoneNumber)
            .MaximumLength(20)
            .WithMessage("Phone number cannot exceed 20 characters")
            .Matches(@"^\+?[\d\s\-\(\)]+$")
            .WithMessage("Phone number contains invalid characters")
            .When(x => !string.IsNullOrWhiteSpace(x.PhoneNumber));

        RuleFor(x => x.Email)
            .EmailAddress()
            .WithMessage("Invalid email format")
            .MaximumLength(100)
            .WithMessage("Email cannot exceed 100 characters")
            .When(x => !string.IsNullOrWhiteSpace(x.Email));

        RuleFor(x => x.Cnpj)
            .MaximumLength(18)
            .WithMessage("CNPJ cannot exceed 18 characters")
            .Must(BeValidCnpjFormat)
            .WithMessage("CNPJ must be in format XX.XXX.XXX/XXXX-XX or 14 digits")
            .When(x => !string.IsNullOrWhiteSpace(x.Cnpj));

        RuleFor(x => x.Latitude)
            .GreaterThanOrEqualTo(-90.0)
            .WithMessage("Latitude must be greater than or equal to -90")
            .LessThanOrEqualTo(90.0)
            .WithMessage("Latitude must be less than or equal to 90")
            .When(x => x.Latitude.HasValue);

        RuleFor(x => x.Longitude)
            .GreaterThanOrEqualTo(-180.0)
            .WithMessage("Longitude must be greater than or equal to -180")
            .LessThanOrEqualTo(180.0)
            .WithMessage("Longitude must be less than or equal to 180")
            .When(x => x.Longitude.HasValue);

        // Business rules
        RuleFor(x => x.Type)
            .NotEqual(ClinicType.Origin)
            .WithMessage("Origin clinics require special authorization and cannot be created through this endpoint")
            .When(x => x.Type == ClinicType.Origin);

        // Coordinates should be provided together
        RuleFor(x => x)
            .Must(x => (x.Latitude.HasValue && x.Longitude.HasValue) || (!x.Latitude.HasValue && !x.Longitude.HasValue))
            .WithMessage("Both latitude and longitude must be provided together or neither should be provided");

        // If clinic type is Partner, coordinates are recommended
        RuleFor(x => x)
            .Must(x => x.Latitude.HasValue && x.Longitude.HasValue)
            .WithMessage("Partner clinics should have location coordinates for better patient experience")
            .When(x => x.Type == ClinicType.Partner)
            .WithSeverity(Severity.Warning);
    }

    /// <summary>
    /// Validates Brazilian CNPJ format
    /// </summary>
    /// <param name="cnpj">CNPJ to validate</param>
    /// <returns>True if format is valid, false otherwise</returns>
    private static bool BeValidCnpjFormat(string? cnpj)
    {
        if (string.IsNullOrWhiteSpace(cnpj))
            return true; // CNPJ is optional

        // Check if it matches XX.XXX.XXX/XXXX-XX format
        if (System.Text.RegularExpressions.Regex.IsMatch(cnpj, @"^\d{2}\.\d{3}\.\d{3}\/\d{4}\-\d{2}$"))
            return true;

        // Check if it matches 14 digits format
        if (System.Text.RegularExpressions.Regex.IsMatch(cnpj, @"^\d{14}$"))
            return true;

        return false;
    }
}