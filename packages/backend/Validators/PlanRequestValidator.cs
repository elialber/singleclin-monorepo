using FluentValidation;
using SingleClin.API.DTOs.Plan;

namespace SingleClin.API.Validators;

/// <summary>
/// Validator for PlanRequestDto using FluentValidation
/// </summary>
public class PlanRequestValidator : AbstractValidator<PlanRequestDto>
{
    public PlanRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty()
            .WithMessage("Plan name is required")
            .Length(1, 100)
            .WithMessage("Plan name must be between 1 and 100 characters")
            .Matches(@"^[\w\s\-_\.À-ÿ]+$")
            .WithMessage("Plan name can only contain letters (including accents), numbers, spaces, hyphens, underscores, and dots");

        RuleFor(x => x.Description)
            .MaximumLength(500)
            .WithMessage("Description cannot exceed 500 characters");

        RuleFor(x => x.Credits)
            .GreaterThan(0)
            .WithMessage("Credits must be greater than 0")
            .LessThanOrEqualTo(10000)
            .WithMessage("Credits cannot exceed 10,000");

        RuleFor(x => x.Price)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Price must be greater than or equal to 0")
            .LessThanOrEqualTo(999999.99m)
            .WithMessage("Price cannot exceed R$ 999,999.99")
            .Must(price => HaveMaxTwoDecimalPlaces(price))
            .WithMessage("Price cannot have more than 2 decimal places");

        RuleFor(x => x.OriginalPrice)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Original price must be greater than or equal to 0")
            .LessThanOrEqualTo(999999.99m)
            .WithMessage("Original price cannot exceed R$ 999,999.99")
            .Must(originalPrice => HaveMaxTwoDecimalPlaces(originalPrice))
            .WithMessage("Original price cannot have more than 2 decimal places")
            .When(x => x.OriginalPrice.HasValue);

        RuleFor(x => x.ValidityDays)
            .GreaterThan(0)
            .WithMessage("Validity days must be greater than 0")
            .LessThanOrEqualTo(3650)
            .WithMessage("Validity days cannot exceed 10 years (3650 days)");

        RuleFor(x => x.DisplayOrder)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Display order must be greater than or equal to 0")
            .LessThanOrEqualTo(999)
            .WithMessage("Display order cannot exceed 999")
            .When(x => x.DisplayOrder.HasValue);

        // Business rule: Original price must be greater than current price (if set)
        RuleFor(x => x.OriginalPrice)
            .GreaterThan(x => x.Price)
            .WithMessage("Original price must be greater than current price")
            .When(x => x.OriginalPrice.HasValue && x.OriginalPrice > 0);

        // Business rule: Featured plans should have reasonable pricing
        RuleFor(x => x.Price)
            .GreaterThan(0)
            .WithMessage("Featured plans must have a price greater than 0")
            .When(x => x.IsFeatured);

        // Business rule: Inactive plans should not be featured
        RuleFor(x => x.IsFeatured)
            .Must(featured => !featured)
            .WithMessage("Inactive plans cannot be featured")
            .When(x => !x.IsActive);


        // Business rule: Long validity should have more credits
        RuleFor(x => x.Credits)
            .GreaterThanOrEqualTo(x => x.ValidityDays / 10)
            .WithMessage("Plans with long validity should have proportional credits (minimum 1 credit per 10 days)")
            .When(x => x.ValidityDays > 365);
    }

    /// <summary>
    /// Validates that decimal value has maximum 2 decimal places
    /// </summary>
    /// <param name="value">Decimal value to validate</param>
    /// <returns>True if valid, false otherwise</returns>
    private static bool HaveMaxTwoDecimalPlaces(decimal value)
    {
        return decimal.Round(value, 2) == value;
    }

    /// <summary>
    /// Validates that nullable decimal value has maximum 2 decimal places
    /// </summary>
    /// <param name="value">Nullable decimal value to validate</param>
    /// <returns>True if valid, false otherwise</returns>
    private static bool HaveMaxTwoDecimalPlaces(decimal? value)
    {
        if (!value.HasValue) return true;
        return decimal.Round(value.Value, 2) == value.Value;
    }
}