using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.QRCode;

/// <summary>
/// Request DTO for QR Code validation by clinics
/// </summary>
public class QRCodeValidateRequestDto
{
    /// <summary>
    /// JWT token extracted from QR Code
    /// </summary>
    [Required(ErrorMessage = "QR token is required")]
    [StringLength(2000, ErrorMessage = "QR token is too long")]
    public string QRToken { get; set; } = string.Empty;

    /// <summary>
    /// ID of the clinic performing the validation
    /// </summary>
    [Required(ErrorMessage = "Clinic ID is required")]
    public Guid ClinicId { get; set; }

    /// <summary>
    /// Type of service being provided (optional)
    /// </summary>
    [StringLength(200, ErrorMessage = "Service type must not exceed 200 characters")]
    public string? ServiceType { get; set; }

    /// <summary>
    /// Service description or additional notes
    /// </summary>
    [StringLength(500, ErrorMessage = "Service description must not exceed 500 characters")]
    public string? ServiceDescription { get; set; }

    /// <summary>
    /// Amount to charge for this service (optional, defaults to 1 credit)
    /// </summary>
    [Range(0.01, 1000.00, ErrorMessage = "Amount must be between 0.01 and 1000.00")]
    public decimal? Amount { get; set; }
}