namespace SingleClin.API.DTOs.QRCode;

/// <summary>
/// Response DTO for QR Code generation
/// </summary>
public class QRCodeGenerateResponseDto
{
    /// <summary>
    /// Indicates if QR Code generation was successful
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// QR Code image as Data URL (base64 encoded PNG)
    /// </summary>
    public string QRCode { get; set; } = string.Empty;

    /// <summary>
    /// JWT token embedded in the QR Code
    /// </summary>
    public string Token { get; set; } = string.Empty;

    /// <summary>
    /// Unique nonce for this QR Code
    /// </summary>
    public string Nonce { get; set; } = string.Empty;

    /// <summary>
    /// QR Code expiration timestamp (UTC)
    /// </summary>
    public DateTime ExpiresAt { get; set; }

    /// <summary>
    /// QR Code generation timestamp (UTC)
    /// </summary>
    public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Error message if generation failed
    /// </summary>
    public string? ErrorMessage { get; set; }
}