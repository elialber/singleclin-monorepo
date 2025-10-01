using SingleClin.API.Data.Models;

namespace SingleClin.API.Services;

public interface IDomainUserSyncService
{
    Task EnsureUserAsync(ApplicationUser applicationUser, CancellationToken cancellationToken = default);
    Task RemoveUserAsync(Guid applicationUserId, CancellationToken cancellationToken = default);
}
