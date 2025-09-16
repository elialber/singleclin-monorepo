using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.Data.Models;

/// <summary>
/// Represents an image associated with a clinic
/// </summary>
public class ClinicImage : BaseEntity
{
    /// <summary>
    /// ID of the clinic this image belongs to
    /// </summary>
    [Required]
    public Guid ClinicId { get; set; }

    /// <summary>
    /// Navigation property to the clinic
    /// </summary>
    public Clinic Clinic { get; set; } = null!;

    /// <summary>
    /// URL of the image in Azure Blob Storage
    /// </summary>
    [Required]
    [MaxLength(2048)]
    public string ImageUrl { get; set; } = string.Empty;

    /// <summary>
    /// Original file name of the image
    /// </summary>
    [Required]
    [MaxLength(500)]
    public string FileName { get; set; } = string.Empty;

    /// <summary>
    /// File name used in storage (with unique identifier)
    /// </summary>
    [Required]
    [MaxLength(500)]
    public string StorageFileName { get; set; } = string.Empty;

    /// <summary>
    /// Size of the image file in bytes
    /// </summary>
    public long Size { get; set; }

    /// <summary>
    /// MIME type of the image (e.g., image/jpeg)
    /// </summary>
    [Required]
    [MaxLength(100)]
    public string ContentType { get; set; } = string.Empty;

    /// <summary>
    /// Alternative text for accessibility
    /// </summary>
    [MaxLength(500)]
    public string? AltText { get; set; }

    /// <summary>
    /// Description of the image
    /// </summary>
    [MaxLength(1000)]
    public string? Description { get; set; }

    /// <summary>
    /// Display order for sorting images (0 = first)
    /// </summary>
    public int DisplayOrder { get; set; }

    /// <summary>
    /// Whether this is the featured/primary image
    /// </summary>
    public bool IsFeatured { get; set; }

    /// <summary>
    /// Width of the image in pixels
    /// </summary>
    public int? Width { get; set; }

    /// <summary>
    /// Height of the image in pixels
    /// </summary>
    public int? Height { get; set; }
}