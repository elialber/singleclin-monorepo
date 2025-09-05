using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.Clinic;

/// <summary>
/// Data transfer object for clinic image data
/// </summary>
public class ClinicImageDto
{
    /// <summary>
    /// Image unique identifier
    /// </summary>
    public Guid Id { get; set; }
    
    /// <summary>
    /// ID of the clinic this image belongs to
    /// </summary>
    public Guid ClinicId { get; set; }
    
    /// <summary>
    /// URL of the image in Azure Blob Storage
    /// </summary>
    [Required]
    public string ImageUrl { get; set; } = string.Empty;
    
    /// <summary>
    /// Original file name of the image
    /// </summary>
    [Required]
    public string FileName { get; set; } = string.Empty;
    
    /// <summary>
    /// File name used in storage (with unique identifier)
    /// </summary>
    [Required]
    public string StorageFileName { get; set; } = string.Empty;
    
    /// <summary>
    /// Size of the image file in bytes
    /// </summary>
    public long Size { get; set; }
    
    /// <summary>
    /// MIME type of the image (e.g., image/jpeg)
    /// </summary>
    [Required]
    public string ContentType { get; set; } = string.Empty;
    
    /// <summary>
    /// Alternative text for accessibility
    /// </summary>
    public string? AltText { get; set; }
    
    /// <summary>
    /// Description of the image
    /// </summary>
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
    
    /// <summary>
    /// When the image was created
    /// </summary>
    public DateTime CreatedAt { get; set; }
    
    /// <summary>
    /// When the image was last updated
    /// </summary>
    public DateTime UpdatedAt { get; set; }
}