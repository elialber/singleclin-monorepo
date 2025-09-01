using SingleClin.API.Data.Models;
using SingleClin.API.Data.Models.Enums;

namespace SingleClin.API.Repositories;

/// <summary>
/// Repository contract for Clinic entity operations
/// </summary>
public interface IClinicRepository
{
    /// <summary>
    /// Get all clinics with pagination and filtering
    /// </summary>
    /// <param name="pageNumber">Page number (1-based)</param>
    /// <param name="pageSize">Number of items per page</param>
    /// <param name="isActive">Filter by active status (null for all)</param>
    /// <param name="type">Filter by clinic type (null for all)</param>
    /// <param name="searchTerm">Search term for name or address</param>
    /// <param name="city">Filter by city</param>
    /// <param name="state">Filter by state</param>
    /// <param name="sortBy">Field to sort by</param>
    /// <param name="sortDirection">Sort direction (asc or desc)</param>
    /// <returns>Paginated list of clinics</returns>
    Task<(IEnumerable<Clinic> Clinics, int TotalCount)> GetAllAsync(
        int pageNumber = 1,
        int pageSize = 10,
        bool? isActive = null,
        ClinicType? type = null,
        string? searchTerm = null,
        string? city = null,
        string? state = null,
        string sortBy = "Name",
        string sortDirection = "asc");

    /// <summary>
    /// Get clinic by ID
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <returns>Clinic if found, null otherwise</returns>
    Task<Clinic?> GetByIdAsync(Guid id);

    /// <summary>
    /// Get clinic by name
    /// </summary>
    /// <param name="name">Clinic name</param>
    /// <returns>Clinic if found, null otherwise</returns>
    Task<Clinic?> GetByNameAsync(string name);

    /// <summary>
    /// Get clinic by CNPJ
    /// </summary>
    /// <param name="cnpj">Clinic CNPJ</param>
    /// <returns>Clinic if found, null otherwise</returns>
    Task<Clinic?> GetByCnpjAsync(string cnpj);

    /// <summary>
    /// Get all active clinics ordered by name
    /// </summary>
    /// <returns>List of active clinics</returns>
    Task<IEnumerable<Clinic>> GetActiveAsync();

    /// <summary>
    /// Create a new clinic
    /// </summary>
    /// <param name="clinic">Clinic to create</param>
    /// <returns>Created clinic</returns>
    Task<Clinic> CreateAsync(Clinic clinic);

    /// <summary>
    /// Update an existing clinic
    /// </summary>
    /// <param name="clinic">Clinic to update</param>
    /// <returns>Updated clinic</returns>
    Task<Clinic> UpdateAsync(Clinic clinic);

    /// <summary>
    /// Delete a clinic (soft delete)
    /// </summary>
    /// <param name="id">Clinic ID to delete</param>
    /// <returns>True if deleted, false if not found</returns>
    Task<bool> DeleteAsync(Guid id);

    /// <summary>
    /// Check if clinic name exists (for validation)
    /// </summary>
    /// <param name="name">Clinic name to check</param>
    /// <param name="excludeId">Clinic ID to exclude from check (for updates)</param>
    /// <returns>True if name exists, false otherwise</returns>
    Task<bool> NameExistsAsync(string name, Guid? excludeId = null);

    /// <summary>
    /// Check if CNPJ exists (for validation)
    /// </summary>
    /// <param name="cnpj">CNPJ to check</param>
    /// <param name="excludeId">Clinic ID to exclude from check (for updates)</param>
    /// <returns>True if CNPJ exists, false otherwise</returns>
    Task<bool> CnpjExistsAsync(string cnpj, Guid? excludeId = null);

    /// <summary>
    /// Get clinics count by status and type
    /// </summary>
    /// <returns>Dictionary with counts</returns>
    Task<Dictionary<string, int>> GetCountsByStatusAndTypeAsync();
}