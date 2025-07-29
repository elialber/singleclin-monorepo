using SingleClin.API.DTOs.Plan;
using SingleClin.API.DTOs.Common;

namespace SingleClin.API.Services;

/// <summary>
/// Service contract for Plan business logic
/// </summary>
public interface IPlanService
{
    /// <summary>
    /// Get all plans with pagination and filtering
    /// </summary>
    /// <param name="filter">Filter criteria</param>
    /// <returns>Paginated list of plans</returns>
    Task<PagedResultDto<PlanResponseDto>> GetAllAsync(PlanFilterDto filter);

    /// <summary>
    /// Get plan by ID
    /// </summary>
    /// <param name="id">Plan ID</param>
    /// <returns>Plan if found, null otherwise</returns>
    Task<PlanResponseDto?> GetByIdAsync(Guid id);

    /// <summary>
    /// Get all active plans
    /// </summary>
    /// <returns>List of active plans</returns>
    Task<IEnumerable<PlanResponseDto>> GetActiveAsync();

    /// <summary>
    /// Create a new plan
    /// </summary>
    /// <param name="planRequest">Plan data</param>
    /// <returns>Created plan</returns>
    /// <exception cref="InvalidOperationException">Thrown when plan name already exists</exception>
    Task<PlanResponseDto> CreateAsync(PlanRequestDto planRequest);

    /// <summary>
    /// Update an existing plan
    /// </summary>
    /// <param name="id">Plan ID</param>
    /// <param name="planRequest">Updated plan data</param>
    /// <returns>Updated plan</returns>
    /// <exception cref="InvalidOperationException">Thrown when plan not found or name already exists</exception>
    Task<PlanResponseDto> UpdateAsync(Guid id, PlanRequestDto planRequest);

    /// <summary>
    /// Delete a plan (soft delete)
    /// </summary>
    /// <param name="id">Plan ID</param>
    /// <returns>True if deleted, false if not found</returns>
    Task<bool> DeleteAsync(Guid id);

    /// <summary>
    /// Get statistics about plans
    /// </summary>
    /// <returns>Dictionary with plan statistics</returns>
    Task<Dictionary<string, int>> GetStatisticsAsync();

    /// <summary>
    /// Validate plan data
    /// </summary>
    /// <param name="planRequest">Plan data to validate</param>
    /// <param name="excludeId">Plan ID to exclude from uniqueness checks (for updates)</param>
    /// <returns>List of validation errors</returns>
    Task<List<string>> ValidateAsync(PlanRequestDto planRequest, Guid? excludeId = null);
}