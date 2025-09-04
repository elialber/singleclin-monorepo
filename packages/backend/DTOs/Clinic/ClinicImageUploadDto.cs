using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace SingleClin.API.DTOs.Clinic;

/// <summary>
/// Data transfer object for clinic image upload operations
/// </summary>
public class ClinicImageUploadDto
{
    /// <summary>
    /// Image file to upload
    /// </summary>
    [Required(ErrorMessage = "Image file is required")]
    public IFormFile Image { get; set; } = null!;

    /// <summary>
    /// Optional alt text for accessibility
    /// </summary>
    [StringLength(500, ErrorMessage = "Alt text cannot exceed 500 characters")]
    public string? AltText { get; set; }

    /// <summary>
    /// Optional description of the image
    /// </summary>
    [StringLength(1000, ErrorMessage = "Description cannot exceed 1000 characters")]
    public string? Description { get; set; }
}

/// <summary>
/// Response DTO for image upload operations
/// </summary>
public class ImageUploadResponseDto
{
    /// <summary>
    /// Indicates if the upload was successful
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// Public URL of the uploaded image
    /// </summary>
    public string? ImageUrl { get; set; }

    /// <summary>
    /// Size of the uploaded image in bytes
    /// </summary>
    public long? FileSize { get; set; }

    /// <summary>
    /// Original filename of the uploaded image
    /// </summary>
    public string? OriginalFileName { get; set; }

    /// <summary>
    /// Content type of the uploaded image
    /// </summary>
    public string? ContentType { get; set; }

    /// <summary>
    /// Error message if upload failed
    /// </summary>
    public string? ErrorMessage { get; set; }

    /// <summary>
    /// Timestamp when the upload was completed
    /// </summary>
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Create a successful upload response
    /// </summary>
    public static ImageUploadResponseDto CreateSuccess(string imageUrl, long fileSize, string originalFileName, string contentType)
    {
        return new ImageUploadResponseDto
        {
            Success = true,
            ImageUrl = imageUrl,
            FileSize = fileSize,
            OriginalFileName = originalFileName,
            ContentType = contentType,
            UploadedAt = DateTime.UtcNow
        };
    }

    /// <summary>
    /// Create a failed upload response
    /// </summary>
    public static ImageUploadResponseDto CreateFailure(string errorMessage)
    {
        return new ImageUploadResponseDto
        {
            Success = false,
            ErrorMessage = errorMessage,
            UploadedAt = DateTime.UtcNow
        };
    }
}