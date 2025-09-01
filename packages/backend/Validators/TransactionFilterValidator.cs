using FluentValidation;
using SingleClin.API.DTOs.Transaction;
using SingleClin.API.Data.Models.Enums;

namespace SingleClin.API.Validators;

/// <summary>
/// Validator for TransactionFilterDto using FluentValidation
/// </summary>
public class TransactionFilterValidator : AbstractValidator<TransactionFilterDto>
{
    public TransactionFilterValidator()
    {
        // Search validation
        RuleFor(x => x.Search)
            .MaximumLength(100)
            .WithMessage("Search term cannot exceed 100 characters")
            .When(x => !string.IsNullOrWhiteSpace(x.Search));

        // Date range validations
        RuleFor(x => x.StartDate)
            .LessThanOrEqualTo(x => x.EndDate)
            .WithMessage("Start date must be before or equal to end date")
            .When(x => x.StartDate.HasValue && x.EndDate.HasValue);

        RuleFor(x => x.ValidationStartDate)
            .LessThanOrEqualTo(x => x.ValidationEndDate)
            .WithMessage("Validation start date must be before or equal to validation end date")
            .When(x => x.ValidationStartDate.HasValue && x.ValidationEndDate.HasValue);

        // Amount range validations
        RuleFor(x => x.MinAmount)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Minimum amount must be greater than or equal to 0")
            .LessThanOrEqualTo(x => x.MaxAmount)
            .WithMessage("Minimum amount must be less than or equal to maximum amount")
            .When(x => x.MinAmount.HasValue && x.MaxAmount.HasValue);

        RuleFor(x => x.MaxAmount)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Maximum amount must be greater than or equal to 0")
            .When(x => x.MaxAmount.HasValue);

        // Credits range validations
        RuleFor(x => x.MinCredits)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Minimum credits must be greater than or equal to 0")
            .LessThanOrEqualTo(x => x.MaxCredits)
            .WithMessage("Minimum credits must be less than or equal to maximum credits")
            .When(x => x.MinCredits.HasValue && x.MaxCredits.HasValue);

        RuleFor(x => x.MaxCredits)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Maximum credits must be greater than or equal to 0")
            .When(x => x.MaxCredits.HasValue);

        // Service type validation
        RuleFor(x => x.ServiceType)
            .MaximumLength(50)
            .WithMessage("Service type cannot exceed 50 characters")
            .When(x => !string.IsNullOrWhiteSpace(x.ServiceType));

        // Status validation
        RuleFor(x => x.Status)
            .IsInEnum()
            .WithMessage("Invalid transaction status")
            .When(x => x.Status.HasValue);

        // Pagination validations
        RuleFor(x => x.Page)
            .GreaterThanOrEqualTo(1)
            .WithMessage("Page must be greater than or equal to 1");

        RuleFor(x => x.Limit)
            .GreaterThanOrEqualTo(1)
            .WithMessage("Limit must be greater than or equal to 1")
            .LessThanOrEqualTo(100)
            .WithMessage("Limit cannot exceed 100 items per page");

        // Sort validations
        RuleFor(x => x.SortBy)
            .Must(BeValidSortField)
            .WithMessage("Invalid sort field")
            .When(x => !string.IsNullOrWhiteSpace(x.SortBy));

        RuleFor(x => x.SortOrder)
            .Must(BeValidSortOrder)
            .WithMessage("Sort order must be 'asc' or 'desc'")
            .When(x => !string.IsNullOrWhiteSpace(x.SortOrder));

        // GUID validations
        RuleFor(x => x.PatientId)
            .NotEqual(Guid.Empty)
            .WithMessage("Patient ID cannot be empty")
            .When(x => x.PatientId.HasValue);

        RuleFor(x => x.ClinicId)
            .NotEqual(Guid.Empty)
            .WithMessage("Clinic ID cannot be empty")
            .When(x => x.ClinicId.HasValue);

        RuleFor(x => x.PlanId)
            .NotEqual(Guid.Empty)
            .WithMessage("Plan ID cannot be empty")
            .When(x => x.PlanId.HasValue);

        // Business rules
        RuleFor(x => x.StartDate)
            .LessThanOrEqualTo(DateTime.UtcNow.AddDays(1))
            .WithMessage("Start date cannot be in the future")
            .When(x => x.StartDate.HasValue);

        RuleFor(x => x.EndDate)
            .LessThanOrEqualTo(DateTime.UtcNow.AddDays(1))
            .WithMessage("End date cannot be in the future")
            .When(x => x.EndDate.HasValue);

        // Warn if date range is too large
        RuleFor(x => x)
            .Must(x => !x.StartDate.HasValue || !x.EndDate.HasValue || 
                      (x.EndDate.Value - x.StartDate.Value).TotalDays <= 365)
            .WithMessage("Date range should not exceed 365 days for better performance")
            .WithSeverity(Severity.Warning)
            .When(x => x.StartDate.HasValue && x.EndDate.HasValue);
    }

    /// <summary>
    /// Validates if the sort field is allowed
    /// </summary>
    private static bool BeValidSortField(string? sortBy)
    {
        if (string.IsNullOrWhiteSpace(sortBy))
            return true;

        var validFields = new[]
        {
            "code", "patientname", "clinicname", "planname", "status",
            "creditsused", "amount", "createdat", "validationdate", "updatedat"
        };

        return validFields.Contains(sortBy.ToLower());
    }

    /// <summary>
    /// Validates if the sort order is valid
    /// </summary>
    private static bool BeValidSortOrder(string? sortOrder)
    {
        if (string.IsNullOrWhiteSpace(sortOrder))
            return true;

        return sortOrder.ToLower() is "asc" or "desc";
    }
}