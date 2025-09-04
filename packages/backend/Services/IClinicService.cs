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
    /// Update clinic image
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <param name="imageFile">Image file to upload</param>
    /// <returns>Updated clinic with new image</returns>
    /// <exception cref="InvalidOperationException">Thrown when clinic not found or image upload fails</exception>
    Task<ClinicResponseDto> UpdateImageAsync(Guid id, IFormFile imageFile);

    /// <summary>
    /// Delete clinic image
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <returns>Updated clinic without image</returns>
    /// <exception cref="InvalidOperationException">Thrown when clinic not found</exception>
    Task<ClinicResponseDto> DeleteImageAsync(Guid id);
}