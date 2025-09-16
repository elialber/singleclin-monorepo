using SingleClin.API.Data.Models.Enums;

namespace SingleClin.API.DTOs.Transaction;

/// <summary>
/// DTO for filtering transactions
/// </summary>
public class TransactionFilterDto
{
    /// <summary>
    /// Search term for patient name, transaction code, or clinic name
    /// </summary>
    public string? Search { get; set; }

    /// <summary>
    /// Filter by patient ID
    /// </summary>
    public Guid? PatientId { get; set; }

    /// <summary>
    /// Filter by clinic ID
    /// </summary>
    public Guid? ClinicId { get; set; }

    /// <summary>
    /// Filter by plan ID
    /// </summary>
    public Guid? PlanId { get; set; }

    /// <summary>
    /// Filter by transaction status
    /// </summary>
    public TransactionStatus? Status { get; set; }

    /// <summary>
    /// Filter by start date (inclusive)
    /// </summary>
    public DateTime? StartDate { get; set; }

    /// <summary>
    /// Filter by end date (inclusive)
    /// </summary>
    public DateTime? EndDate { get; set; }

    /// <summary>
    /// Filter by validation start date
    /// </summary>
    public DateTime? ValidationStartDate { get; set; }

    /// <summary>
    /// Filter by validation end date
    /// </summary>
    public DateTime? ValidationEndDate { get; set; }

    /// <summary>
    /// Filter by minimum amount
    /// </summary>
    public decimal? MinAmount { get; set; }

    /// <summary>
    /// Filter by maximum amount
    /// </summary>
    public decimal? MaxAmount { get; set; }

    /// <summary>
    /// Filter by minimum credits used
    /// </summary>
    public int? MinCredits { get; set; }

    /// <summary>
    /// Filter by maximum credits used
    /// </summary>
    public int? MaxCredits { get; set; }

    /// <summary>
    /// Filter by service type
    /// </summary>
    public string? ServiceType { get; set; }

    /// <summary>
    /// Include cancelled transactions (default: false)
    /// </summary>
    public bool IncludeCancelled { get; set; } = false;

    /// <summary>
    /// Page number for pagination (1-based)
    /// </summary>
    public int Page { get; set; } = 1;

    /// <summary>
    /// Number of items per page
    /// </summary>
    public int Limit { get; set; } = 20;

    /// <summary>
    /// Field to sort by
    /// </summary>
    public string? SortBy { get; set; } = "CreatedAt";

    /// <summary>
    /// Sort order (asc or desc)
    /// </summary>
    public string? SortOrder { get; set; } = "desc";
}