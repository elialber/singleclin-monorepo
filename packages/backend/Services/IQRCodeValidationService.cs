using SingleClin.API.DTOs.QRCode;

namespace SingleClin.API.Services;

/// <summary>
/// Interface for QR Code validation service
/// </summary>
public interface IQRCodeValidationService
{
    /// <summary>
    /// Validate QR Code token and process transaction
    /// </summary>
    /// <param name="request">Validation request with QR token and clinic info</param>
    /// <returns>Validation result with transaction details</returns>
    Task<QRCodeValidateResponseDto> ValidateQRCodeAsync(QRCodeValidateRequestDto request);

    /// <summary>
    /// Parse QR Code token without consuming nonce (for preview/validation)
    /// </summary>
    /// <param name="qrToken">QR Code token to parse</param>
    /// <returns>Token claims if valid, null otherwise</returns>
    Task<QRTokenClaims?> ParseQRCodeTokenAsync(string qrToken);

    /// <summary>
    /// Check if clinic is authorized to validate QR codes
    /// </summary>
    /// <param name="clinicId">Clinic ID to validate</param>
    /// <returns>True if clinic is authorized</returns>
    Task<bool> IsClinicAuthorizedAsync(Guid clinicId);
}