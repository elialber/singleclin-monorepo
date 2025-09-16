using SingleClin.API.Data.Models;

namespace SingleClin.API.Repositories;

/// <summary>
/// Repository contract for Plan entity operations
/// </summary>
public interface IPlanRepository
{
    /// <summary>
    /// Get all plans with pagination and filtering
    /// </summary>
    /// <param name="pageNumber">Page number (1-based)</param>
    /// <param name="pageSize">Number of items per page</param>
    /// <param name="isActive">Filter by active status (null for all)</param>
    /// <param name="searchTerm">Search term for name or description</param>
    /// <param name="minPrice">Minimum price filter</param>
    /// <param name="maxPrice">Maximum price filter</param>
    /// <param name="isFeatured">Filter by featured status (null for all)</param>
    /// <param name="minCredits">Minimum credits filter</param>
    /// <param name="maxCredits">Maximum credits filter</param>
    /// <param name="sortBy">Field to sort by</param>
    /// <param name="sortDirection">Sort direction (asc or desc)</param>
    /// <returns>Paginated list of plans</returns>
    Task<(IEnumerable<Plan> Plans, int TotalCount)> GetAllAsync(
        int pageNumber = 1,
        int pageSize = 10,
        bool? isActive = null,
        string? searchTerm = null,
        decimal? minPrice = null,
        decimal? maxPrice = null,
        bool? isFeatured = null,
        int? minCredits = null,
        int? maxCredits = null,
        string sortBy = "DisplayOrder",
        string sortDirection = "asc");

    /// <summary>
    /// Get plan by ID
    /// </summary>
    /// <param name="id">Plan ID</param>
    /// <returns>Plan if found, null otherwise</returns>
    Task<Plan?> GetByIdAsync(Guid id);

    /// <summary>
    /// Get plan by name
    /// </summary>
    /// <param name="name">Plan name</param>
    /// <returns>Plan if found, null otherwise</returns>
    Task<Plan?> GetByNameAsync(string name);

    /// <summary>
    /// Get all active plans ordered by display order
    /// </summary>
    /// <returns>List of active plans</returns>
    Task<IEnumerable<Plan>> GetActiveAsync();

    /// <summary>
    /// Create a new plan
    /// </summary>
    /// <param name="plan">Plan to create</param>
    /// <returns>Created plan</returns>
    Task<Plan> CreateAsync(Plan plan);

    /// <summary>
    /// Update an existing plan
    /// </summary>
    /// <param name="plan">Plan to update</param>
    /// <returns>Updated plan</returns>
    Task<Plan> UpdateAsync(Plan plan);

    /// <summary>
    /// Delete a plan (soft delete)
    /// </summary>
    /// <param name="id">Plan ID to delete</param>
    /// <returns>True if deleted, false if not found</returns>
    Task<bool> DeleteAsync(Guid id);

    /// <summary>
    /// Check if plan name exists (for validation)
    /// </summary>
    /// <param name="name">Plan name to check</param>
    /// <param name="excludeId">Plan ID to exclude from check (for updates)</param>
    /// <returns>True if name exists, false otherwise</returns>
    Task<bool> NameExistsAsync(string name, Guid? excludeId = null);

    /// <summary>
    /// Get plans count by status
    /// </summary>
    /// <returns>Dictionary with status counts</returns>
    Task<Dictionary<string, int>> GetCountsByStatusAsync();
}