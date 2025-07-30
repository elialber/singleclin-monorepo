using SingleClin.API.Data.Models.Enums;

namespace SingleClin.API.Data.Models;

/// <summary>
/// Represents a transaction (credit usage) in the system
/// </summary>
public class Transaction : BaseEntity
{
    /// <summary>
    /// Unique transaction code
    /// </summary>
    public string Code { get; set; } = string.Empty;
    
    /// <summary>
    /// User plan used for this transaction
    /// </summary>
    public Guid UserPlanId { get; set; }
    
    /// <summary>
    /// Navigation property to UserPlan
    /// </summary>
    public UserPlan UserPlan { get; set; } = null!;
    
    /// <summary>
    /// Clinic where the transaction occurred
    /// </summary>
    public Guid ClinicId { get; set; }
    
    /// <summary>
    /// Navigation property to Clinic
    /// </summary>
    public Clinic Clinic { get; set; } = null!;
    
    /// <summary>
    /// Transaction status
    /// </summary>
    public TransactionStatus Status { get; set; } = TransactionStatus.Pending;
    
    /// <summary>
    /// Number of credits used
    /// </summary>
    public int CreditsUsed { get; set; }
    
    /// <summary>
    /// Service or procedure description
    /// </summary>
    public string ServiceDescription { get; set; } = string.Empty;
    
    /// <summary>
    /// Date when the transaction was validated
    /// </summary>
    public DateTime? ValidationDate { get; set; }
    
    /// <summary>
    /// User who validated the transaction (clinic staff)
    /// </summary>
    public string? ValidatedBy { get; set; }
    
    /// <summary>
    /// Validation notes
    /// </summary>
    public string? ValidationNotes { get; set; }
    
    /// <summary>
    /// IP address from where the transaction was created
    /// </summary>
    public string? IpAddress { get; set; }
    
    /// <summary>
    /// User agent of the device that created the transaction
    /// </summary>
    public string? UserAgent { get; set; }
    
    /// <summary>
    /// Latitude where the transaction occurred
    /// </summary>
    public double? Latitude { get; set; }
    
    /// <summary>
    /// Longitude where the transaction occurred
    /// </summary>
    public double? Longitude { get; set; }
    
    /// <summary>
    /// Cancellation reason if cancelled
    /// </summary>
    public string? CancellationReason { get; set; }
    
    /// <summary>
    /// Date when the transaction was cancelled
    /// </summary>
    public DateTime? CancellationDate { get; set; }
    
    /// <summary>
    /// QR Code token used for this transaction (if applicable)
    /// </summary>
    public string? QRToken { get; set; }
    
    /// <summary>
    /// QR Code nonce for security verification
    /// </summary>
    public string? QRNonce { get; set; }
    
    /// <summary>
    /// Service type from QR Code validation
    /// </summary>
    public string? ServiceType { get; set; }
    
    /// <summary>
    /// Amount charged for this transaction
    /// </summary>
    public decimal Amount { get; set; }
}