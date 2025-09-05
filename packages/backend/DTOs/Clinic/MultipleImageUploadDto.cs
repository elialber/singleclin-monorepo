using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace SingleClin.API.DTOs.Clinic;

/// <summary>
/// Data transfer object for uploading multiple clinic images
/// </summary>
public class MultipleImageUploadDto
{
    /// <summary>
    /// Image files to upload (maximum 10 files)
    /// </summary>
    [Required(ErrorMessage = "At least one image file is required")]
    [MaxLength(10, ErrorMessage = "Maximum 10 images allowed")]
    public IFormFile[] Images { get; set; } = Array.Empty<IFormFile>();

    /// <summary>
    /// Optional alt texts for each image (must match image count)
    /// </summary>
    public string[]? AltTexts { get; set; }

    /// <summary>
    /// Optional descriptions for each image (must match image count)
    /// </summary>
    public string[]? Descriptions { get; set; }

    /// <summary>
    /// Display orders for each image (if not provided, will use array index)
    /// </summary>
    public int[]? DisplayOrders { get; set; }

    /// <summary>
    /// Index of the featured image (0-based, default is first image)
    /// </summary>
    [Range(0, int.MaxValue, ErrorMessage = "Featured image index must be non-negative")]
    public int FeaturedImageIndex { get; set; } = 0;
}

/// <summary>
/// Data transfer object for updating clinic image properties
/// </summary>
public class ClinicImageUpdateDto
{
    /// <summary>
    /// Alternative text for accessibility
    /// </summary>
    [StringLength(500, ErrorMessage = "Alt text cannot exceed 500 characters")]
    public string? AltText { get; set; }

    /// <summary>
    /// Description of the image
    /// </summary>
    [StringLength(1000, ErrorMessage = "Description cannot exceed 1000 characters")]
    public string? Description { get; set; }

    /// <summary>
    /// Display order for sorting images
    /// </summary>
    [Range(0, int.MaxValue, ErrorMessage = "Display order must be non-negative")]
    public int DisplayOrder { get; set; }

    /// <summary>
    /// Whether this is the featured/primary image
    /// </summary>
    public bool IsFeatured { get; set; }
}

/// <summary>
/// Response DTO for multiple image upload operations
/// </summary>
public class MultipleImageUploadResponseDto
{
    /// <summary>
    /// Indicates if the upload was successful
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// List of uploaded images
    /// </summary>
    public List<ClinicImageDto> UploadedImages { get; set; } = new();

    /// <summary>
    /// Error messages if any uploads failed
    /// </summary>
    public List<string> ErrorMessages { get; set; } = new();

    /// <summary>
    /// Count of successfully uploaded images
    /// </summary>
    public int SuccessCount { get; set; }

    /// <summary>
    /// Count of failed uploads
    /// </summary>
    public int FailureCount { get; set; }

    /// <summary>
    /// Timestamp when the upload was completed
    /// </summary>
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Create a successful upload response
    /// </summary>
    public static MultipleImageUploadResponseDto CreateSuccess(List<ClinicImageDto> uploadedImages)
    {
        return new MultipleImageUploadResponseDto
        {
            Success = true,
            UploadedImages = uploadedImages,
            SuccessCount = uploadedImages.Count,
            FailureCount = 0,
            UploadedAt = DateTime.UtcNow
        };
    }

    /// <summary>
    /// Create a partial success response
    /// </summary>
    public static MultipleImageUploadResponseDto CreatePartialSuccess(
        List<ClinicImageDto> uploadedImages, 
        List<string> errorMessages)
    {
        return new MultipleImageUploadResponseDto
        {
            Success = uploadedImages.Count > 0,
            UploadedImages = uploadedImages,
            ErrorMessages = errorMessages,
            SuccessCount = uploadedImages.Count,
            FailureCount = errorMessages.Count,
            UploadedAt = DateTime.UtcNow
        };
    }

    /// <summary>
    /// Create a failed upload response
    /// </summary>
    public static MultipleImageUploadResponseDto CreateFailure(List<string> errorMessages)
    {
        return new MultipleImageUploadResponseDto
        {
            Success = false,
            ErrorMessages = errorMessages,
            SuccessCount = 0,
            FailureCount = errorMessages.Count,
            UploadedAt = DateTime.UtcNow
        };
    }
}