using FluentValidation;
using SingleClin.API.DTOs.Transaction;

namespace SingleClin.API.Validators;

/// <summary>
/// Validator for TransactionCancelDto using FluentValidation
/// </summary>
public class TransactionCancelValidator : AbstractValidator<TransactionCancelDto>
{
    public TransactionCancelValidator()
    {
        // Cancellation reason is required
        RuleFor(x => x.CancellationReason)
            .NotEmpty()
            .WithMessage("Cancellation reason is required")
            .Length(3, 500)
            .WithMessage("Cancellation reason must be between 3 and 500 characters")
            .Matches(@"^[\w\s\-_\.\,\!\?\(\)À-ÿ]+$")
            .WithMessage("Cancellation reason contains invalid characters");

        // Additional notes validation
        RuleFor(x => x.Notes)
            .MaximumLength(1000)
            .WithMessage("Additional notes cannot exceed 1000 characters")
            .When(x => !string.IsNullOrWhiteSpace(x.Notes));

        // Business rules
        RuleFor(x => x.CancellationReason)
            .Must(BeValidCancellationReason)
            .WithMessage("Cancellation reason must provide meaningful information")
            .When(x => !string.IsNullOrWhiteSpace(x.CancellationReason));

        // RefundCredits is already bool, no validation needed but we can add business logic
        RuleFor(x => x.RefundCredits)
            .Equal(true)
            .WithMessage("Credits should typically be refunded when cancelling transactions for better customer experience")
            .WithSeverity(Severity.Warning)
            .When(x => !x.RefundCredits);
    }

    /// <summary>
    /// Validates that cancellation reason is meaningful
    /// </summary>
    private static bool BeValidCancellationReason(string reason)
    {
        if (string.IsNullOrWhiteSpace(reason))
            return false;

        // Check if it's not just generic/too short reasons
        var trimmedReason = reason.Trim().ToLower();
        var invalidReasons = new[]
        {
            "erro", "error", "cancel", "cancelar", "test", "teste", "wrong", "errado",
            "mistake", "engano", "ops", "oops", "deleted", "deletar", "remove", "remover"
        };

        // If the reason is too generic or in the invalid list, require more detail
        return !invalidReasons.Contains(trimmedReason) && trimmedReason.Length >= 3;
    }
}