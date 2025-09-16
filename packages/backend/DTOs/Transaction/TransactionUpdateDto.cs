namespace SingleClin.API.DTOs.Transaction;

/// <summary>
/// DTO for updating transaction information
/// </summary>
public class TransactionUpdateDto
{
    /// <summary>
    /// Service or procedure description
    /// </summary>
    public string? ServiceDescription { get; set; }

    /// <summary>
    /// Service type
    /// </summary>
    public string? ServiceType { get; set; }

    /// <summary>
    /// Validation notes
    /// </summary>
    public string? ValidationNotes { get; set; }

    /// <summary>
    /// Amount charged for this transaction
    /// </summary>
    public decimal? Amount { get; set; }
}