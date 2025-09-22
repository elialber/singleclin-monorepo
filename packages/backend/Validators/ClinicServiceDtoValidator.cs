using FluentValidation;
using SingleClin.API.DTOs.Clinic;

namespace SingleClin.API.Validators;

/// <summary>
/// Validator for ClinicServiceDto with automatic CreditCost calculation
/// </summary>
public class ClinicServiceDtoValidator : AbstractValidator<ClinicServiceDto>
{
    public ClinicServiceDtoValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty()
            .WithMessage("Service name is required")
            .MaximumLength(100)
            .WithMessage("Service name cannot exceed 100 characters");

        RuleFor(x => x.Description)
            .MaximumLength(500)
            .WithMessage("Service description cannot exceed 500 characters");

        RuleFor(x => x.Price)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Service price must be non-negative");

        RuleFor(x => x.Duration)
            .GreaterThan(0)
            .WithMessage("Service duration must be at least 1 minute");

        RuleFor(x => x.Category)
            .NotEmpty()
            .WithMessage("Service category is required")
            .MaximumLength(50)
            .WithMessage("Service category cannot exceed 50 characters");

        RuleFor(x => x.ImageUrl)
            .Must(BeValidUrl)
            .When(x => !string.IsNullOrEmpty(x.ImageUrl))
            .WithMessage("Service image URL must be a valid URL");

        // Custom validation to set CreditCost if not provided
        RuleFor(x => x)
            .Must(SetCreditCostFromPrice)
            .WithMessage("Credit cost calculation failed");
    }

    private static bool BeValidUrl(string? url)
    {
        if (string.IsNullOrEmpty(url))
            return true;

        return Uri.TryCreate(url, UriKind.Absolute, out var result)
               && (result.Scheme == Uri.UriSchemeHttp || result.Scheme == Uri.UriSchemeHttps);
    }

    private static bool SetCreditCostFromPrice(ClinicServiceDto service)
    {
        // If CreditCost is not set or is 0, calculate from Price
        if (service.CreditCost <= 0)
        {
            service.CreditCost = Math.Max(1, (int)Math.Ceiling(service.Price));
        }

        return service.CreditCost >= 1;
    }
}