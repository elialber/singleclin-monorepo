using SingleClin.API.DTOs.Plan;

namespace SingleClin.API.Services;

/// <summary>
/// Interface for credit validation service
/// </summary>
public interface ICreditValidationService
{
    /// <summary>
    /// Validate if user has sufficient credits for a service
    /// </summary>
    /// <param name="userId">User ID</param>
    /// <param name="creditsRequired">Credits required for the service</param>
    /// <returns>Validation result with success status and available credits</returns>
    Task<(bool HasSufficientCredits, int AvailableCredits, IEnumerable<string> Errors)> ValidateUserCreditsAsync(Guid userId, int creditsRequired);

    /// <summary>
    /// Get user's total available credits across all active plans
    /// </summary>
    /// <param name="userId">User ID</param>
    /// <returns>Total available credits</returns>
    Task<int> GetAvailableCreditsAsync(Guid userId);

    /// <summary>
    /// Get user's active plans with credit information
    /// </summary>
    /// <param name="userId">User ID</param>
    /// <returns>List of active user plans with credit details</returns>
    Task<IEnumerable<UserPlanResponseDto>> GetUserActivePlansAsync(Guid userId);

    /// <summary>
    /// Check if user has any active plans
    /// </summary>
    /// <param name="userId">User ID</param>
    /// <returns>True if user has active plans</returns>
    Task<bool> HasActivePlansAsync(Guid userId);
}