namespace SingleClin.API.Services;

/// <summary>
/// Interface for QR Code image generation
/// </summary>
public interface IQRCodeGeneratorService
{
    /// <summary>
    /// Generate QR Code as Data URL from JWT token
    /// </summary>
    /// <param name="token">JWT token to embed in QR Code</param>
    /// <param name="size">QR Code size in pixels (default: 300)</param>
    /// <returns>QR Code as Data URL string</returns>
    string GenerateQRCode(string token, int size = 300);

    /// <summary>
    /// Generate QR Code as byte array from JWT token
    /// </summary>
    /// <param name="token">JWT token to embed in QR Code</param>
    /// <param name="size">QR Code size in pixels (default: 300)</param>
    /// <returns>QR Code as PNG byte array</returns>
    byte[] GenerateQRCodeBytes(string token, int size = 300);
}

/// <summary>
/// QR Code payload structure
/// </summary>
public class QRCodePayload
{
    public string Token { get; set; } = string.Empty;
    public string Version { get; set; } = "1.0";
    public string Type { get; set; } = "singleclin_qr";
    public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;
}