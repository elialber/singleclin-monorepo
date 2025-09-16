namespace SingleClin.API.Exceptions;

/// <summary>
/// Base exception for QR Code validation errors
/// </summary>
public abstract class QRCodeValidationException : Exception
{
    public string ErrorCode { get; }

    protected QRCodeValidationException(string errorCode, string message) : base(message)
    {
        ErrorCode = errorCode;
    }

    protected QRCodeValidationException(string errorCode, string message, Exception innerException)
        : base(message, innerException)
    {
        ErrorCode = errorCode;
    }
}

/// <summary>
/// Exception thrown when QR Code token is expired
/// </summary>
public class QRExpiredException : QRCodeValidationException
{
    public DateTime ExpiresAt { get; }

    public QRExpiredException(DateTime expiresAt)
        : base("QR_EXPIRED", $"QR Code expired at {expiresAt:yyyy-MM-dd HH:mm:ss} UTC")
    {
        ExpiresAt = expiresAt;
    }
}

/// <summary>
/// Exception thrown when QR Code has already been used
/// </summary>
public class QRAlreadyUsedException : QRCodeValidationException
{
    public string Nonce { get; }

    public QRAlreadyUsedException(string nonce)
        : base("QR_ALREADY_USED", $"QR Code with nonce {nonce} has already been used")
    {
        Nonce = nonce;
    }
}

/// <summary>
/// Exception thrown when QR Code token is invalid or malformed
/// </summary>
public class InvalidQRException : QRCodeValidationException
{
    public InvalidQRException(string message)
        : base("INVALID_QR", $"Invalid QR Code: {message}")
    {
    }

    public InvalidQRException(string message, Exception innerException)
        : base("INVALID_QR", $"Invalid QR Code: {message}", innerException)
    {
    }
}

/// <summary>
/// Exception thrown when user plan has insufficient credits
/// </summary>
public class InsufficientCreditsException : QRCodeValidationException
{
    public int AvailableCredits { get; }
    public int RequiredCredits { get; }

    public InsufficientCreditsException(int availableCredits, int requiredCredits)
        : base("INSUFFICIENT_CREDITS", $"Insufficient credits. Available: {availableCredits}, Required: {requiredCredits}")
    {
        AvailableCredits = availableCredits;
        RequiredCredits = requiredCredits;
    }
}

/// <summary>
/// Exception thrown when user plan is not found or inactive
/// </summary>
public class InvalidUserPlanException : QRCodeValidationException
{
    public Guid UserPlanId { get; }

    public InvalidUserPlanException(Guid userPlanId)
        : base("INVALID_USER_PLAN", $"User plan {userPlanId} is not found or inactive")
    {
        UserPlanId = userPlanId;
    }
}

/// <summary>
/// Exception thrown when clinic is not authorized for the operation
/// </summary>
public class UnauthorizedClinicException : QRCodeValidationException
{
    public Guid ClinicId { get; }

    public UnauthorizedClinicException(Guid clinicId)
        : base("UNAUTHORIZED_CLINIC", $"Clinic {clinicId} is not authorized for this operation")
    {
        ClinicId = clinicId;
    }
}