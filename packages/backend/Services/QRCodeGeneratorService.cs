using QRCoder;
using System.Drawing;
using System.Text.Json;
using SdColor = System.Drawing.Color;

namespace SingleClin.API.Services;

/// <summary>
/// Service for generating QR Code images from JWT tokens
/// </summary>
public class QRCodeGeneratorService : IQRCodeGeneratorService
{
    private readonly ILogger<QRCodeGeneratorService> _logger;

    public QRCodeGeneratorService(ILogger<QRCodeGeneratorService> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Generate QR Code as Data URL from JWT token
    /// </summary>
    public string GenerateQRCode(string token, int size = 300)
    {
        try
        {
            var qrCodeBytes = GenerateQRCodeBytes(token, size);
            var base64String = Convert.ToBase64String(qrCodeBytes);
            var dataUrl = $"data:image/png;base64,{base64String}";

            _logger.LogDebug("Generated QR Code Data URL with size {Size}px", size);
            return dataUrl;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to generate QR Code Data URL");
            throw;
        }
    }

    /// <summary>
    /// Generate QR Code as byte array from JWT token
    /// </summary>
    public byte[] GenerateQRCodeBytes(string token, int size = 300)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(token))
            {
                throw new ArgumentException("Token cannot be null or empty", nameof(token));
            }

            if (size <= 0 || size > 2000)
            {
                throw new ArgumentException("Size must be between 1 and 2000 pixels", nameof(size));
            }

            // Create QR Code payload
            var payload = new QRCodePayload
            {
                Token = token,
                Version = "1.0",
                Type = "singleclin_qr",
                GeneratedAt = DateTime.UtcNow
            };

            // Serialize to JSON
            var payloadJson = JsonSerializer.Serialize(payload, new JsonSerializerOptions
            {
                WriteIndented = false,
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            });

            _logger.LogDebug("QR Code payload JSON length: {Length} characters", payloadJson.Length);

            // Generate QR Code
            using var qrGenerator = new QRCodeGenerator();
            using var qrCodeData = qrGenerator.CreateQrCode(payloadJson, QRCodeGenerator.ECCLevel.M);
            using var qrCode = new PngByteQRCode(qrCodeData);

            // Generate PNG bytes with configuration
            var qrCodeBytes = qrCode.GetGraphic(
                pixelsPerModule: CalculatePixelsPerModule(size),
                darkColor: SdColor.Black,
                lightColor: SdColor.White,
                drawQuietZones: true
            );

            _logger.LogInformation("Generated QR Code with {Size}px size and {ByteSize} bytes",
                size, qrCodeBytes.Length);

            return qrCodeBytes;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to generate QR Code bytes");
            throw;
        }
    }

    /// <summary>
    /// Calculate pixels per module based on desired size
    /// QR Codes have different numbers of modules based on data length
    /// </summary>
    private static int CalculatePixelsPerModule(int desiredSize)
    {
        // Standard QR Code has typically 21-177 modules per side depending on version
        // For our use case (JWT tokens), we'll likely use Version 3-5 (29-41 modules)
        // We'll use a conservative estimate of 33 modules per side
        const int estimatedModules = 33;

        // Calculate pixels per module to achieve desired size
        var pixelsPerModule = Math.Max(1, desiredSize / estimatedModules);

        // Ensure minimum quality (at least 4 pixels per module for readability)
        return Math.Max(4, pixelsPerModule);
    }
}