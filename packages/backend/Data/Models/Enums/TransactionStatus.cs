namespace SingleClin.API.Data.Models.Enums;

/// <summary>
/// Status of a transaction
/// </summary>
public enum TransactionStatus
{
    /// <summary>
    /// Transaction is pending validation
    /// </summary>
    Pending = 0,

    /// <summary>
    /// Transaction was validated successfully
    /// </summary>
    Validated = 1,

    /// <summary>
    /// Transaction was cancelled
    /// </summary>
    Cancelled = 2,

    /// <summary>
    /// Transaction expired before validation
    /// </summary>
    Expired = 3
}