using Microsoft.AspNetCore.Http;

namespace SingleClin.API.Services;

/// <summary>
/// Service interface for handling image uploads to Azure Blob Storage
/// </summary>
public interface IImageUploadService
{
    /// <summary>
    /// Upload an image file to Azure Blob Storage
    /// </summary>
    /// <param name="file">The image file to upload</param>
    /// <param name="folder">The folder/container to upload to</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Upload result with file details</returns>
    Task<ImageUploadResult> UploadImageAsync(IFormFile file, string folder, CancellationToken cancellationToken = default);

    /// <summary>
    /// Delete an image file from Azure Blob Storage
    /// </summary>
    /// <param name="fileName">Name of the file to delete</param>
    /// <param name="folder">The folder/container where the file is located</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>True if deletion was successful</returns>
    Task<bool> DeleteImageAsync(string fileName, string folder, CancellationToken cancellationToken = default);

    /// <summary>
    /// Get the public URL for an image
    /// </summary>
    /// <param name="fileName">Name of the file</param>
    /// <param name="folder">The folder/container where the file is located</param>
    /// <returns>Public URL of the image</returns>
    Task<string> GetImageUrlAsync(string fileName, string folder);

    /// <summary>
    /// Validate an image file before upload
    /// </summary>
    /// <param name="file">The image file to validate</param>
    /// <returns>True if the file is valid for upload</returns>
    Task<bool> ValidateImageAsync(IFormFile file);
}

/// <summary>
/// Result of an image upload operation
/// </summary>
public class ImageUploadResult
{
    /// <summary>
    /// Indicates if the upload was successful
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// Generated file name in storage
    /// </summary>
    public string? FileName { get; set; }

    /// <summary>
    /// Public URL of the uploaded image
    /// </summary>
    public string? Url { get; set; }

    /// <summary>
    /// Size of the uploaded file in bytes
    /// </summary>
    public long Size { get; set; }

    /// <summary>
    /// Content type (MIME type) of the uploaded file
    /// </summary>
    public string? ContentType { get; set; }

    /// <summary>
    /// Error message if upload failed
    /// </summary>
    public string? ErrorMessage { get; set; }

    /// <summary>
    /// Create a successful upload result
    /// </summary>
    public static ImageUploadResult CreateSuccess(string fileName, string url, long size, string contentType)
    {
        return new ImageUploadResult
        {
            Success = true,
            FileName = fileName,
            Url = url,
            Size = size,
            ContentType = contentType
        };
    }

    /// <summary>
    /// Create a failed upload result
    /// </summary>
    public static ImageUploadResult CreateFailure(string errorMessage)
    {
        return new ImageUploadResult
        {
            Success = false,
            ErrorMessage = errorMessage
        };
    }
}