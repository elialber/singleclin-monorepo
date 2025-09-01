using SingleClin.API.Data.Models.Enums;

namespace SingleClin.API.DTOs.Transaction;

/// <summary>
/// Response DTO for transaction information
/// </summary>
public class TransactionResponseDto
{
    /// <summary>
    /// Transaction ID
    /// </summary>
    public Guid Id { get; set; }
    
    /// <summary>
    /// Unique transaction code
    /// </summary>
    public string Code { get; set; } = string.Empty;
    
    /// <summary>
    /// Patient ID
    /// </summary>
    public Guid PatientId { get; set; }
    
    /// <summary>
    /// Patient full name
    /// </summary>
    public string PatientName { get; set; } = string.Empty;
    
    /// <summary>
    /// Patient email
    /// </summary>
    public string PatientEmail { get; set; } = string.Empty;
    
    /// <summary>
    /// Clinic ID where transaction occurred
    /// </summary>
    public Guid ClinicId { get; set; }
    
    /// <summary>
    /// Clinic name
    /// </summary>
    public string ClinicName { get; set; } = string.Empty;
    
    /// <summary>
    /// Plan ID used for transaction
    /// </summary>
    public Guid PlanId { get; set; }
    
    /// <summary>
    /// Plan name
    /// </summary>
    public string PlanName { get; set; } = string.Empty;
    
    /// <summary>
    /// User plan ID used
    /// </summary>
    public Guid UserPlanId { get; set; }
    
    /// <summary>
    /// Transaction status
    /// </summary>
    public TransactionStatus Status { get; set; }
    
    /// <summary>
    /// Number of credits used
    /// </summary>
    public int CreditsUsed { get; set; }
    
    /// <summary>
    /// Service or procedure description
    /// </summary>
    public string ServiceDescription { get; set; } = string.Empty;
    
    /// <summary>
    /// Service type
    /// </summary>
    public string? ServiceType { get; set; }
    
    /// <summary>
    /// Amount charged for this transaction
    /// </summary>
    public decimal Amount { get; set; }
    
    /// <summary>
    /// Date when transaction was created
    /// </summary>
    public DateTime CreatedAt { get; set; }
    
    /// <summary>
    /// Date when transaction was validated
    /// </summary>
    public DateTime? ValidationDate { get; set; }
    
    /// <summary>
    /// User who validated the transaction
    /// </summary>
    public string? ValidatedBy { get; set; }
    
    /// <summary>
    /// Validation notes
    /// </summary>
    public string? ValidationNotes { get; set; }
    
    /// <summary>
    /// Date when transaction was cancelled
    /// </summary>
    public DateTime? CancellationDate { get; set; }
    
    /// <summary>
    /// Cancellation reason
    /// </summary>
    public string? CancellationReason { get; set; }
    
    /// <summary>
    /// Latitude where transaction occurred
    /// </summary>
    public double? Latitude { get; set; }
    
    /// <summary>
    /// Longitude where transaction occurred
    /// </summary>
    public double? Longitude { get; set; }
    
    /// <summary>
    /// IP address from where transaction was created
    /// </summary>
    public string? IpAddress { get; set; }
    
    /// <summary>
    /// User agent of device that created transaction
    /// </summary>
    public string? UserAgent { get; set; }
    
    /// <summary>
    /// QR token used for transaction
    /// </summary>
    public string? QRToken { get; set; }
    
    /// <summary>
    /// Last updated date
    /// </summary>
    public DateTime UpdatedAt { get; set; }
}