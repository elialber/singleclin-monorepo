using SingleClin.API.Data.Models.Enums;
using System.Linq;

namespace SingleClin.API.DTOs.Clinic;

/// <summary>
/// Data transfer object for clinic response
/// </summary>
public class ClinicResponseDto
{
    /// <summary>
    /// Clinic unique identifier
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// Clinic name
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Type of clinic
    /// </summary>
    public ClinicType Type { get; set; }

    /// <summary>
    /// Clinic address
    /// </summary>
    public string Address { get; set; } = string.Empty;

    /// <summary>
    /// Clinic phone number
    /// </summary>
    public string? PhoneNumber { get; set; }

    /// <summary>
    /// Clinic email
    /// </summary>
    public string? Email { get; set; }

    /// <summary>
    /// Clinic CNPJ (Brazilian company registration)
    /// </summary>
    public string? Cnpj { get; set; }

    /// <summary>
    /// Whether the clinic is active
    /// </summary>
    public bool IsActive { get; set; }

    /// <summary>
    /// Latitude coordinate
    /// </summary>
    public double? Latitude { get; set; }

    /// <summary>
    /// Longitude coordinate
    /// </summary>
    public double? Longitude { get; set; }

    /// <summary>
    /// When the clinic was created
    /// </summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// When the clinic was last updated
    /// </summary>
    public DateTime UpdatedAt { get; set; }

    /// <summary>
    /// URL da imagem/logo da clínica (DEPRECATED - use Images collection)
    /// </summary>
    private string? _legacyImageUrl;

    [Obsolete("Use Images collection instead. Will be removed in future version.")]
    public string? ImageUrl
    {
        get => _legacyImageUrl ?? FeaturedImage?.ImageUrl;
        set => _legacyImageUrl = value;
    }

    /// <summary>
    /// Collection of images associated with this clinic
    /// </summary>
    public List<ClinicImageDto> Images { get; set; } = new();

    /// <summary>
    /// Services offered by this clinic
    /// </summary>
    public List<ClinicServiceDto> Services { get; set; } = new();

    /// <summary>
    /// Number of transactions processed by this clinic
    /// </summary>
    public int TransactionCount { get; set; }

    /// <summary>
    /// Indicates if the clinic has images
    /// </summary>
    public bool HasImages => Images.Count > 0;

    /// <summary>
    /// Gets the featured image or the first image if no featured image is set
    /// </summary>
    public ClinicImageDto? FeaturedImage => Images.FirstOrDefault(i => i.IsFeatured) ?? Images.FirstOrDefault();

    /// <summary>
    /// Indicates if the clinic has an image (backward compatibility)
    /// </summary>
    [Obsolete("Use HasImages instead. Will be removed in future version.")]
    public bool HasImage => HasImages || !string.IsNullOrEmpty(_legacyImageUrl);

    /// <summary>
    /// Type display name for UI
    /// </summary>
    public string TypeDisplayName => Type switch
    {
        ClinicType.Regular => "Regular",
        ClinicType.Origin => "Origin",
        ClinicType.Partner => "Partner",
        ClinicType.Administrative => "Administrative",
        _ => "Unknown"
    };
}
