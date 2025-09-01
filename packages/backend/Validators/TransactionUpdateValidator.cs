using FluentValidation;
using SingleClin.API.DTOs.Transaction;

namespace SingleClin.API.Validators;

/// <summary>
/// Validator for TransactionUpdateDto using FluentValidation
/// </summary>
public class TransactionUpdateValidator : AbstractValidator<TransactionUpdateDto>
{
    public TransactionUpdateValidator()
    {
        // Service description validation
        RuleFor(x => x.ServiceDescription)
            .MaximumLength(500)
            .WithMessage("Service description cannot exceed 500 characters")
            .When(x => !string.IsNullOrWhiteSpace(x.ServiceDescription));

        // Service type validation
        RuleFor(x => x.ServiceType)
            .MaximumLength(50)
            .WithMessage("Service type cannot exceed 50 characters")
            .Matches(@"^[\w\s\-_\.]+$")
            .WithMessage("Service type can only contain letters, numbers, spaces, hyphens, underscores, and dots")
            .When(x => !string.IsNullOrWhiteSpace(x.ServiceType));

        // Validation notes validation
        RuleFor(x => x.ValidationNotes)
            .MaximumLength(1000)
            .WithMessage("Validation notes cannot exceed 1000 characters")
            .When(x => !string.IsNullOrWhiteSpace(x.ValidationNotes));

        // Amount validation
        RuleFor(x => x.Amount)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Amount must be greater than or equal to 0")
            .LessThanOrEqualTo(999999.99m)
            .WithMessage("Amount cannot exceed R$ 999,999.99")
            .When(x => x.Amount.HasValue);

        // Business rules
        RuleFor(x => x)
            .Must(x => !string.IsNullOrWhiteSpace(x.ServiceDescription) ||
                      !string.IsNullOrWhiteSpace(x.ServiceType) ||
                      !string.IsNullOrWhiteSpace(x.ValidationNotes) ||
                      x.Amount.HasValue)
            .WithMessage("At least one field must be provided for update");

        // Amount precision validation
        RuleFor(x => x.Amount)
            .Must(BeValidDecimalPrecision)
            .WithMessage("Amount can have maximum 2 decimal places")
            .When(x => x.Amount.HasValue);
    }

    /// <summary>
    /// Validates that decimal has maximum 2 decimal places
    /// </summary>
    private static bool BeValidDecimalPrecision(decimal? amount)
    {
        if (!amount.HasValue)
            return true;

        var decimalPlaces = BitConverter.GetBytes(decimal.GetBits(amount.Value)[3])[2];
        return decimalPlaces <= 2;
    }
}