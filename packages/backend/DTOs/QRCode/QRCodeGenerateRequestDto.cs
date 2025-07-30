using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.QRCode;

/// <summary>
/// Request DTO for QR Code generation
/// </summary>
public class QRCodeGenerateRequestDto
{
    /// <summary>
    /// QR Code size in pixels (optional, default: 300)
    /// </summary>
    [Range(100, 1000, ErrorMessage = "QR Code size must be between 100 and 1000 pixels")]
    public int? Size { get; set; } = 300;

    /// <summary>
    /// QR Code expiration in minutes (optional, default: 30)
    /// </summary>
    [Range(5, 60, ErrorMessage = "QR Code expiration must be between 5 and 60 minutes")]
    public int? ExpirationMinutes { get; set; } = 30;
}