namespace SingleClin.API.DTOs.QRCode;

/// <summary>
/// Response DTO for QR Code validation
/// </summary>
public class QRCodeValidateResponseDto
{
    /// <summary>
    /// Indicates if validation was successful
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// Transaction ID created for this validation
    /// </summary>
    public Guid? TransactionId { get; set; }

    /// <summary>
    /// Transaction code for reference
    /// </summary>
    public string? TransactionCode { get; set; }

    /// <summary>
    /// Patient information
    /// </summary>
    public PatientInfo? Patient { get; set; }

    /// <summary>
    /// User plan information
    /// </summary>
    public UserPlanInfo? UserPlan { get; set; }

    /// <summary>
    /// Transaction details
    /// </summary>
    public TransactionInfo? Transaction { get; set; }

    /// <summary>
    /// Validation timestamp (UTC)
    /// </summary>
    public DateTime ValidatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Error information if validation failed
    /// </summary>
    public ValidationError? Error { get; set; }
}

/// <summary>
/// Patient information for QR validation response
/// </summary>
public class PatientInfo
{
    public Guid UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
}

/// <summary>
/// User plan information for QR validation response
/// </summary>
public class UserPlanInfo
{
    public Guid Id { get; set; }
    public string PlanName { get; set; } = string.Empty;
    public int CreditsRemaining { get; set; }
    public int CreditsUsed { get; set; }
    public bool IsActive { get; set; }
    public DateTime? ExpiresAt { get; set; }
}

/// <summary>
/// Transaction information for QR validation response
/// </summary>
public class TransactionInfo
{
    public Guid Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public int CreditsUsed { get; set; }
    public decimal Amount { get; set; }
    public string? ServiceType { get; set; }
    public string? ServiceDescription { get; set; }
    public DateTime CreatedAt { get; set; }
}

/// <summary>
/// Validation error information
/// </summary>
public class ValidationError
{
    public string Code { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public Dictionary<string, object>? Details { get; set; }
}