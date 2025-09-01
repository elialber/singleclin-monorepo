namespace SingleClin.API.DTOs.Transaction;

/// <summary>
/// DTO for cancelling a transaction
/// </summary>
public class TransactionCancelDto
{
    /// <summary>
    /// Reason for cancelling the transaction (required)
    /// </summary>
    public string CancellationReason { get; set; } = string.Empty;
    
    /// <summary>
    /// Additional notes about the cancellation
    /// </summary>
    public string? Notes { get; set; }
    
    /// <summary>
    /// Whether to refund credits to the patient's plan (default: true)
    /// </summary>
    public bool RefundCredits { get; set; } = true;
}