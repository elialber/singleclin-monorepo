using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;

namespace SingleClin.API.Services;

/// <summary>
/// Service to migrate existing image URLs to use SAS tokens
/// </summary>
public class ImageMigrationService
{
    private readonly ApplicationDbContext _context;
    private readonly IImageUploadService _imageUploadService;
    private readonly ILogger<ImageMigrationService> _logger;

    public ImageMigrationService(
        ApplicationDbContext context,
        IImageUploadService imageUploadService,
        ILogger<ImageMigrationService> logger)
    {
        _context = context;
        _imageUploadService = imageUploadService;
        _logger = logger;
    }

    /// <summary>
    /// Update all clinic images to use fresh SAS URLs
    /// </summary>
    public async Task<int> UpdateImageUrlsAsync()
    {
        var updatedCount = 0;

        try
        {
            _logger.LogInformation("Starting image URL migration...");

            // Get all clinic images
            var clinicImages = await _context.ClinicImages.ToListAsync();

            foreach (var image in clinicImages)
            {
                if (!string.IsNullOrEmpty(image.StorageFileName))
                {
                    try
                    {
                        // Generate fresh SAS URL
                        var newUrl = await _imageUploadService.GetImageUrlAsync(image.StorageFileName, "clinics");
                        
                        if (image.ImageUrl != newUrl)
                        {
                            image.ImageUrl = newUrl;
                            image.UpdatedAt = DateTime.UtcNow;
                            updatedCount++;

                            _logger.LogDebug("Updated URL for image {ImageId}: {NewUrl}", image.Id, newUrl);
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error updating URL for image {ImageId} with storage file {StorageFileName}", 
                            image.Id, image.StorageFileName);
                    }
                }
            }

            if (updatedCount > 0)
            {
                await _context.SaveChangesAsync();
                _logger.LogInformation("Successfully updated {Count} image URLs", updatedCount);
            }
            else
            {
                _logger.LogInformation("No image URLs needed updating");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during image URL migration");
            throw;
        }

        return updatedCount;
    }

    /// <summary>
    /// Update URLs for a specific clinic's images
    /// </summary>
    public async Task<int> UpdateClinicImageUrlsAsync(Guid clinicId)
    {
        var updatedCount = 0;

        try
        {
            var clinicImages = await _context.ClinicImages
                .Where(i => i.ClinicId == clinicId)
                .ToListAsync();

            foreach (var image in clinicImages)
            {
                if (!string.IsNullOrEmpty(image.StorageFileName))
                {
                    var newUrl = await _imageUploadService.GetImageUrlAsync(image.StorageFileName, "clinics");
                    
                    if (image.ImageUrl != newUrl)
                    {
                        image.ImageUrl = newUrl;
                        image.UpdatedAt = DateTime.UtcNow;
                        updatedCount++;
                    }
                }
            }

            if (updatedCount > 0)
            {
                await _context.SaveChangesAsync();
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating URLs for clinic {ClinicId} images", clinicId);
            throw;
        }

        return updatedCount;
    }
}