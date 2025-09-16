using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Azure.Storage.Sas;
using Microsoft.AspNetCore.Http;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Formats.Png;
using SixLabors.ImageSharp.Formats.Webp;

namespace SingleClin.API.Services;

/// <summary>
/// Service implementation for handling image uploads to Azure Blob Storage
/// </summary>
public class ImageUploadService : IImageUploadService
{
    private readonly BlobServiceClient? _blobServiceClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<ImageUploadService> _logger;

    // Configuration values
    private readonly string _containerName;
    private readonly string _baseUrl;
    private readonly long _maxFileSize;
    private readonly string[] _allowedFileTypes;
    private readonly int _imageQuality;
    private readonly int _maxWidth;
    private readonly int _maxHeight;

    public ImageUploadService(
        BlobServiceClient blobServiceClient,
        IConfiguration configuration,
        ILogger<ImageUploadService> logger)
    {
        _blobServiceClient = blobServiceClient;
        _configuration = configuration;
        _logger = logger;

        // Load configuration
        var azureConfig = _configuration.GetSection("AzureStorage");
        _containerName = azureConfig["ContainerName"] ?? "clinic-images";
        _baseUrl = azureConfig["BaseUrl"] ?? "https://localhost:5001/uploads/";
        _maxFileSize = azureConfig.GetValue<long>("MaxFileSize", 5242880); // 5MB default
        _allowedFileTypes = azureConfig.GetSection("AllowedFileTypes").Get<string[]>() ?? new[] { "jpg", "jpeg", "png", "webp" };
        _imageQuality = azureConfig.GetValue<int>("ImageQuality", 85);
        _maxWidth = azureConfig.GetValue<int>("MaxWidth", 1200);
        _maxHeight = azureConfig.GetValue<int>("MaxHeight", 800);

        // Log if using local storage
        if (_blobServiceClient == null)
        {
            _logger.LogWarning("Azure Blob Storage not configured. Using local file storage for development.");
        }
    }

    public async Task<ImageUploadResult> UploadImageAsync(IFormFile file, string folder, CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("Starting image upload process for file: {FileName}", file.FileName);

            // Validate the image
            if (!await ValidateImageAsync(file))
            {
                return ImageUploadResult.CreateFailure("Invalid image file");
            }

            // Generate unique file name
            var fileExtension = Path.GetExtension(file.FileName).ToLowerInvariant();
            var uniqueFileName = $"{folder}/{Guid.NewGuid()}{fileExtension}";

            // Process and optimize the image
            using var originalStream = file.OpenReadStream();
            using var processedImageStream = await ProcessImageAsync(originalStream, fileExtension);

            var contentType = GetContentType(fileExtension);

            // Check if Azure Blob Storage is available
            if (_blobServiceClient != null)
            {
                // Ensure container exists (without public access)
                var containerClient = _blobServiceClient.GetBlobContainerClient(_containerName);
                await containerClient.CreateIfNotExistsAsync();

                // Upload to Azure Blob Storage
                var blobClient = containerClient.GetBlobClient(uniqueFileName);
                var uploadOptions = new BlobUploadOptions
                {
                    HttpHeaders = new BlobHttpHeaders { ContentType = contentType }
                };

                await blobClient.UploadAsync(processedImageStream, uploadOptions, cancellationToken);

                // Set blob to hot access tier for better performance
                await blobClient.SetAccessTierAsync(AccessTier.Hot);

                // Generate a SAS URL for the image with 1 year expiration
                var imageUrl = GenerateSasUrl(blobClient);

                _logger.LogInformation("Successfully uploaded image to Azure Blob Storage: {FileName} to {Url}", uniqueFileName, imageUrl);

                return ImageUploadResult.CreateSuccess(
                    uniqueFileName,
                    imageUrl,
                    processedImageStream.Length,
                    contentType
                );
            }
            else
            {
                // Use local file storage for development
                return await SaveToLocalStorageAsync(processedImageStream, uniqueFileName, contentType);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading image: {FileName}", file.FileName);
            return ImageUploadResult.CreateFailure($"Upload failed: {ex.Message}");
        }
    }

    public async Task<bool> DeleteImageAsync(string fileName, string folder, CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("Deleting image: {FileName}", fileName);

            // Check if Azure Blob Storage is available
            if (_blobServiceClient != null)
            {
                var blobClient = _blobServiceClient.GetBlobContainerClient(_containerName).GetBlobClient(fileName);
                var response = await blobClient.DeleteIfExistsAsync(DeleteSnapshotsOption.IncludeSnapshots, cancellationToken: cancellationToken);

                if (response.Value)
                {
                    _logger.LogInformation("Successfully deleted image from Azure Blob Storage: {FileName}", fileName);
                    return true;
                }

                _logger.LogWarning("Image not found for deletion in Azure Blob Storage: {FileName}", fileName);
                return false;
            }
            else
            {
                // Delete from local storage
                return await DeleteFromLocalStorageAsync(fileName);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting image: {FileName}", fileName);
            return false;
        }
    }

    public async Task<string> GetImageUrlAsync(string fileName, string folder)
    {
        await Task.CompletedTask; // Placeholder for async pattern

        if (_blobServiceClient != null)
        {
            var containerClient = _blobServiceClient.GetBlobContainerClient(_containerName);
            var blobClient = containerClient.GetBlobClient(fileName);

            // Generate a fresh SAS URL
            return GenerateSasUrl(blobClient);
        }
        else
        {
            // Local storage fallback
            return $"{_baseUrl.TrimEnd('/')}/uploads/{fileName}";
        }
    }

    public async Task<bool> ValidateImageAsync(IFormFile file)
    {
        try
        {
            // Check if file exists and has content
            if (file == null || file.Length == 0)
            {
                _logger.LogWarning("Validation failed: File is null or empty");
                return false;
            }

            // Check file size
            if (file.Length > _maxFileSize)
            {
                _logger.LogWarning("Validation failed: File size {FileSize} exceeds maximum {MaxSize}", file.Length, _maxFileSize);
                return false;
            }

            // Check file extension
            var fileExtension = Path.GetExtension(file.FileName)?.ToLowerInvariant().TrimStart('.');
            if (string.IsNullOrEmpty(fileExtension) || !_allowedFileTypes.Contains(fileExtension))
            {
                _logger.LogWarning("Validation failed: File extension {Extension} not allowed", fileExtension);
                return false;
            }

            // Validate actual image content
            using var stream = file.OpenReadStream();
            try
            {
                using var image = await Image.LoadAsync(stream);

                // Additional checks can be added here
                _logger.LogInformation("Image validation successful: {Width}x{Height}, Format: {Format}",
                    image.Width, image.Height, image.Metadata.DecodedImageFormat?.Name);

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Validation failed: Not a valid image file");
                return false;
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error validating image");
            return false;
        }
    }

    private async Task<MemoryStream> ProcessImageAsync(Stream originalStream, string fileExtension)
    {
        var outputStream = new MemoryStream();

        try
        {
            using var image = await Image.LoadAsync(originalStream);

            // Resize if necessary
            if (image.Width > _maxWidth || image.Height > _maxHeight)
            {
                image.Mutate(x => x.Resize(new ResizeOptions
                {
                    Size = new Size(_maxWidth, _maxHeight),
                    Mode = ResizeMode.Max,
                    Sampler = KnownResamplers.Lanczos3
                }));

                _logger.LogInformation("Image resized from original size to {Width}x{Height}", image.Width, image.Height);
            }

            // Save with appropriate format and quality
            switch (fileExtension.ToLowerInvariant())
            {
                case ".jpg":
                case ".jpeg":
                    await image.SaveAsJpegAsync(outputStream, new JpegEncoder { Quality = _imageQuality });
                    break;
                case ".png":
                    await image.SaveAsPngAsync(outputStream, new PngEncoder());
                    break;
                case ".webp":
                    await image.SaveAsWebpAsync(outputStream, new WebpEncoder { Quality = _imageQuality });
                    break;
                default:
                    // Fallback to JPEG
                    await image.SaveAsJpegAsync(outputStream, new JpegEncoder { Quality = _imageQuality });
                    break;
            }

            outputStream.Position = 0;
            _logger.LogInformation("Image processed successfully, final size: {Size} bytes", outputStream.Length);

            return outputStream;
        }
        catch (Exception ex)
        {
            outputStream.Dispose();
            _logger.LogError(ex, "Error processing image");
            throw;
        }
    }

    private async Task<ImageUploadResult> SaveToLocalStorageAsync(MemoryStream imageStream, string fileName, string contentType)
    {
        try
        {
            // Create uploads directory if it doesn't exist
            var uploadsDir = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads");
            Directory.CreateDirectory(uploadsDir);

            // Create the file path
            var filePath = Path.Combine(uploadsDir, fileName);
            var directory = Path.GetDirectoryName(filePath);
            if (!string.IsNullOrEmpty(directory))
            {
                Directory.CreateDirectory(directory);
            }

            // Save the file
            imageStream.Position = 0;
            using var fileStream = new FileStream(filePath, FileMode.Create, FileAccess.Write);
            await imageStream.CopyToAsync(fileStream);

            // Generate local URL
            var imageUrl = $"{_baseUrl.TrimEnd('/')}/uploads/{fileName}";

            _logger.LogInformation("Successfully saved image to local storage: {FileName} to {Path}", fileName, filePath);

            return ImageUploadResult.CreateSuccess(
                fileName,
                imageUrl,
                imageStream.Length,
                contentType
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving image to local storage: {FileName}", fileName);
            throw;
        }
    }

    private async Task<bool> DeleteFromLocalStorageAsync(string fileName)
    {
        try
        {
            var uploadsDir = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads");
            var filePath = Path.Combine(uploadsDir, fileName);

            if (File.Exists(filePath))
            {
                await Task.Run(() => File.Delete(filePath));
                _logger.LogInformation("Successfully deleted image from local storage: {FileName} at {Path}", fileName, filePath);
                return true;
            }

            _logger.LogWarning("Image not found for deletion in local storage: {FileName} at {Path}", fileName, filePath);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting image from local storage: {FileName}", fileName);
            return false;
        }
    }

    private static string GetContentType(string fileExtension)
    {
        return fileExtension.ToLowerInvariant() switch
        {
            ".jpg" or ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            ".webp" => "image/webp",
            _ => "application/octet-stream"
        };
    }

    private string GenerateSasUrl(BlobClient blobClient)
    {
        try
        {
            // Check if the blob client can generate SAS tokens
            if (blobClient.CanGenerateSasUri)
            {
                // Create a SAS builder for read access
                var sasBuilder = new BlobSasBuilder
                {
                    BlobContainerName = blobClient.BlobContainerName,
                    BlobName = blobClient.Name,
                    Resource = "b", // "b" for blob
                    ExpiresOn = DateTimeOffset.UtcNow.AddYears(1) // 1 year expiration
                };

                // Set read permissions
                sasBuilder.SetPermissions(BlobSasPermissions.Read);

                // Generate the SAS URI
                return blobClient.GenerateSasUri(sasBuilder).ToString();
            }
            else
            {
                // Fallback to base URL if SAS cannot be generated
                _logger.LogWarning("Cannot generate SAS URI for blob: {BlobName}, using base URL", blobClient.Name);
                return blobClient.Uri.ToString();
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating SAS URL for blob: {BlobName}", blobClient.Name);
            // Fallback to base URL
            return blobClient.Uri.ToString();
        }
    }
}