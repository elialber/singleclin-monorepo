using SingleClin.API.Data.Models;

namespace SingleClin.API.Services;

/// <summary>
/// Coordinates the removal of a user across Firebase Authentication and the local database.
/// </summary>
public interface IUserDeletionService
{
    /// <summary>
    /// Deletes a user ensuring consistency between Firebase and the local database.
    /// </summary>
    /// <param name="userId">Application user identifier.</param>
    /// <returns>Operation status with potential error descriptions.</returns>
    Task<(bool Success, IEnumerable<string> Errors)> DeleteUserAsync(Guid userId);
}
