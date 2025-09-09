using System.ComponentModel.DataAnnotations;
using SingleClin.API.Data.Models.Enums;

namespace SingleClin.API.DTOs.Clinic;

/// <summary>
/// Data transfer object for creating or updating a clinic
/// </summary>
public class ClinicRequestDto
{
    /// <summary>
    /// Clinic name
    /// </summary>
    [Required(ErrorMessage = "Clinic name is required")]
    [StringLength(100, ErrorMessage = "Clinic name cannot exceed 100 characters")]
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Type of clinic
    /// </summary>
    [Required(ErrorMessage = "Clinic type is required")]
    public ClinicType Type { get; set; }

    /// <summary>
    /// Clinic address
    /// </summary>
    [Required(ErrorMessage = "Address is required")]
    [StringLength(500, ErrorMessage = "Address cannot exceed 500 characters")]
    public string Address { get; set; } = string.Empty;

    /// <summary>
    /// Clinic phone number
    /// </summary>
    [StringLength(20, ErrorMessage = "Phone number cannot exceed 20 characters")]
    [RegularExpression(@"^\+?[\d\s\-\(\)]+$", ErrorMessage = "Invalid phone number format")]
    public string? PhoneNumber { get; set; }

    /// <summary>
    /// Clinic email
    /// </summary>
    [EmailAddress(ErrorMessage = "Invalid email format")]
    [StringLength(100, ErrorMessage = "Email cannot exceed 100 characters")]
    public string? Email { get; set; }

    /// <summary>
    /// Clinic CNPJ (Brazilian company registration)
    /// </summary>
    [StringLength(18, ErrorMessage = "CNPJ cannot exceed 18 characters")]
    [RegularExpression(@"^\d{2}\.\d{3}\.\d{3}\/\d{4}\-\d{2}$|^\d{14}$", ErrorMessage = "CNPJ must be in format XX.XXX.XXX/XXXX-XX or 14 digits")]
    public string? Cnpj { get; set; }

    /// <summary>
    /// Whether the clinic is active
    /// </summary>
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// Latitude coordinate
    /// </summary>
    [Range(-90.0, 90.0, ErrorMessage = "Latitude must be between -90 and 90")]
    public double? Latitude { get; set; }

    /// <summary>
    /// Longitude coordinate
    /// </summary>
    [Range(-180.0, 180.0, ErrorMessage = "Longitude must be between -180 and 180")]
    public double? Longitude { get; set; }

    /// <summary>
    /// Services offered by this clinic
    /// </summary>
    public List<ClinicServiceDto> Services { get; set; } = new();
}