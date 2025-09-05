using SingleClin.API.DTOs.Clinic;
using SingleClin.API.DTOs.Common;
using Microsoft.AspNetCore.Http;

namespace SingleClin.API.Services;

/// <summary>
/// Service contract for Clinic business logic
/// </summary>
public interface IClinicService
{
    /// <summary>
    /// Get all clinics with pagination and filtering
    /// </summary>
    /// <param name="filter">Filter criteria</param>
    /// <returns>Paginated list of clinics</returns>
    Task<PagedResultDto<ClinicResponseDto>> GetAllAsync(ClinicFilterDto filter);

    /// <summary>
    /// Get clinic by ID
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <returns>Clinic if found, null otherwise</returns>
    Task<ClinicResponseDto?> GetByIdAsync(Guid id);

    /// <summary>
    /// Get all active clinics
    /// </summary>
    /// <returns>List of active clinics</returns>
    Task<IEnumerable<ClinicResponseDto>> GetActiveAsync();

    /// <summary>
    /// Create a new clinic
    /// </summary>
    /// <param name="clinicRequest">Clinic data</param>
    /// <returns>Created clinic</returns>
    /// <exception cref="InvalidOperationException">Thrown when clinic name or CNPJ already exists</exception>
    Task<ClinicResponseDto> CreateAsync(ClinicRequestDto clinicRequest);

    /// <summary>
    /// Update an existing clinic
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <param name="clinicRequest">Updated clinic data</param>
    /// <returns>Updated clinic</returns>
    /// <exception cref="InvalidOperationException">Thrown when clinic not found or name/CNPJ already exists</exception>
    Task<ClinicResponseDto> UpdateAsync(Guid id, ClinicRequestDto clinicRequest);

    /// <summary>
    /// Delete a clinic (soft delete)
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <returns>True if deleted, false if not found</returns>
    Task<bool> DeleteAsync(Guid id);

    /// <summary>
    /// Toggle clinic active status
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <returns>Updated clinic with new status</returns>
    /// <exception cref="InvalidOperationException">Thrown when clinic not found</exception>
    Task<ClinicResponseDto> ToggleStatusAsync(Guid id);

    /// <summary>
    /// Get statistics about clinics
    /// </summary>
    /// <returns>Dictionary with clinic statistics</returns>
    Task<Dictionary<string, int>> GetStatisticsAsync();

    /// <summary>
    /// Validate clinic data
    /// </summary>
    /// <param name="clinicRequest">Clinic data to validate</param>
    /// <param name="excludeId">Clinic ID to exclude from uniqueness checks (for updates)</param>
    /// <returns>List of validation errors</returns>
    Task<List<string>> ValidateAsync(ClinicRequestDto clinicRequest, Guid? excludeId = null);

    /// <summary>
    /// Update clinic image (DEPRECATED - use multiple image methods)
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <param name="imageFile">Image file to upload</param>
    /// <returns>Updated clinic with new image</returns>
    /// <exception cref="InvalidOperationException">Thrown when clinic not found or image upload fails</exception>
    [Obsolete("Use AddImagesAsync instead. Will be removed in future version.")]
    Task<ClinicResponseDto> UpdateImageAsync(Guid id, IFormFile imageFile);

    /// <summary>
    /// Delete clinic image (DEPRECATED - use multiple image methods)
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <returns>Updated clinic without image</returns>
    /// <exception cref="InvalidOperationException">Thrown when clinic not found</exception>
    [Obsolete("Use DeleteImageAsync with image ID instead. Will be removed in future version.")]
    Task<ClinicResponseDto> DeleteImageAsync(Guid id);

    // Multiple Image Management Methods

    /// <summary>
    /// Add multiple images to a clinic
    /// </summary>
    /// <param name="clinicId">Clinic ID</param>
    /// <param name="uploadDto">Multiple images upload data</param>
    /// <returns>Upload response with results</returns>
    /// <exception cref="InvalidOperationException">Thrown when clinic not found</exception>
    Task<MultipleImageUploadResponseDto> AddImagesAsync(Guid clinicId, MultipleImageUploadDto uploadDto);

    /// <summary>
    /// Get all images for a clinic
    /// </summary>
    /// <param name="clinicId">Clinic ID</param>
    /// <returns>List of clinic images</returns>
    Task<List<ClinicImageDto>> GetImagesAsync(Guid clinicId);

    /// <summary>
    /// Update image properties (metadata only, not the file)
    /// </summary>
    /// <param name="clinicId">Clinic ID</param>
    /// <param name="imageId">Image ID</param>
    /// <param name="updateDto">Updated image data</param>
    /// <returns>Updated image</returns>
    /// <exception cref="InvalidOperationException">Thrown when clinic or image not found</exception>
    Task<ClinicImageDto> UpdateImageAsync(Guid clinicId, Guid imageId, ClinicImageUpdateDto updateDto);

    /// <summary>
    /// Delete a specific image from a clinic
    /// </summary>
    /// <param name="clinicId">Clinic ID</param>
    /// <param name="imageId">Image ID</param>
    /// <returns>True if deleted, false if not found</returns>
    Task<bool> DeleteImageAsync(Guid clinicId, Guid imageId);

    /// <summary>
    /// Set featured image for a clinic
    /// </summary>
    /// <param name="clinicId">Clinic ID</param>
    /// <param name="imageId">Image ID to set as featured</param>
    /// <returns>Updated image</returns>
    /// <exception cref="InvalidOperationException">Thrown when clinic or image not found</exception>
    Task<ClinicImageDto> SetFeaturedImageAsync(Guid clinicId, Guid imageId);

    /// <summary>
    /// Reorder clinic images
    /// </summary>
    /// <param name="clinicId">Clinic ID</param>
    /// <param name="imageOrders">Dictionary of image ID to display order</param>
    /// <returns>List of updated images</returns>
    /// <exception cref="InvalidOperationException">Thrown when clinic not found</exception>
    Task<List<ClinicImageDto>> ReorderImagesAsync(Guid clinicId, Dictionary<Guid, int> imageOrders);
}