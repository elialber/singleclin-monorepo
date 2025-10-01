using System.Linq;
using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Data.Models;
using SingleClin.API.Services;

namespace SingleClin.API.Jobs;

public class DomainUserReconciliationJob
{
    private readonly ApplicationDbContext _applicationDbContext;
    private readonly AppDbContext _appDbContext;
    private readonly IDomainUserSyncService _domainUserSyncService;
    private readonly ILogger<DomainUserReconciliationJob> _logger;

    public DomainUserReconciliationJob(
        ApplicationDbContext applicationDbContext,
        AppDbContext appDbContext,
        IDomainUserSyncService domainUserSyncService,
        ILogger<DomainUserReconciliationJob> logger)
    {
        _applicationDbContext = applicationDbContext;
        _appDbContext = appDbContext;
        _domainUserSyncService = domainUserSyncService;
        _logger = logger;
    }

    public async Task ExecuteAsync()
    {
        var applicationUsers = await _applicationDbContext.Users.AsNoTracking().ToListAsync();
        foreach (var appUser in applicationUsers)
        {
            await _domainUserSyncService.EnsureUserAsync(appUser);
        }

        var domainUsers = await _appDbContext.Users.AsNoTracking().ToListAsync();
        foreach (var domainUser in domainUsers)
        {
            if (!applicationUsers.Any(u => u.Id == domainUser.ApplicationUserId))
            {
                _logger.LogWarning("Removing orphan domain user Id={DomainUserId}, ApplicationUserId={ApplicationUserId}", domainUser.Id, domainUser.ApplicationUserId);
                _appDbContext.Users.Remove(domainUser);
            }
        }

        await _appDbContext.SaveChangesAsync();
        _logger.LogInformation("Domain user reconciliation completed. TotalApplicationUsers={AppUserCount}, TotalDomainUsers={DomainUserCount}",
            applicationUsers.Count, domainUsers.Count);
    }
}
