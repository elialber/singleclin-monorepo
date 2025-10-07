using System.Linq;
using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Data.Models;
using SingleClin.API.Data.Models.Enums;

namespace SingleClin.API.Services;

public class DomainUserSyncService : IDomainUserSyncService
{
    private readonly AppDbContext _appDbContext;
    private readonly ILogger<DomainUserSyncService> _logger;

    public DomainUserSyncService(AppDbContext appDbContext, ILogger<DomainUserSyncService> logger)
    {
        _appDbContext = appDbContext;
        _logger = logger;
    }

    public async Task EnsureUserAsync(ApplicationUser applicationUser, CancellationToken cancellationToken = default)
    {
        var domainUser = await _appDbContext.Users
            .FirstOrDefaultAsync(u => u.ApplicationUserId == applicationUser.Id, cancellationToken);

        if (domainUser == null)
        {
            domainUser = new User
            {
                Id = Guid.NewGuid(),
                ApplicationUserId = applicationUser.Id,
                Email = applicationUser.Email ?? string.Empty,
                FullName = applicationUser.FullName,
                Role = (UserRole)(int)applicationUser.Role,
                FirstName = ExtractFirstName(applicationUser.FullName),
                LastName = ExtractLastName(applicationUser.FullName),
                DisplayName = applicationUser.FullName,
                PhoneNumber = applicationUser.PhoneNumber,
                FirebaseUid = applicationUser.FirebaseUid,
                IsActive = applicationUser.IsActive,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _appDbContext.Users.Add(domainUser);
            _logger.LogInformation("Domain user created for ApplicationUserId={UserId}", applicationUser.Id);
        }
        else
        {
            domainUser.Email = applicationUser.Email ?? domainUser.Email;
            domainUser.FullName = applicationUser.FullName;
            domainUser.FirstName = ExtractFirstName(applicationUser.FullName);
            domainUser.LastName = ExtractLastName(applicationUser.FullName);
            domainUser.DisplayName = applicationUser.FullName;
            domainUser.PhoneNumber = applicationUser.PhoneNumber;
            domainUser.FirebaseUid = applicationUser.FirebaseUid;
            domainUser.Role = (UserRole)(int)applicationUser.Role;
            domainUser.IsActive = applicationUser.IsActive;
            domainUser.UpdatedAt = DateTime.UtcNow;

            _logger.LogDebug("Domain user synced for ApplicationUserId={UserId}", applicationUser.Id);
        }

        await _appDbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task RemoveUserAsync(Guid applicationUserId, CancellationToken cancellationToken = default)
    {
        var domainUser = await _appDbContext.Users
            .FirstOrDefaultAsync(u => u.ApplicationUserId == applicationUserId, cancellationToken);
        if (domainUser == null)
        {
            return;
        }

        // Soft delete: mark as inactive instead of hard delete to preserve UserPlans and audit trail
        domainUser.IsActive = false;
        domainUser.UpdatedAt = DateTime.UtcNow;
        
        await _appDbContext.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("Domain user marked as inactive (soft delete) for ApplicationUserId={UserId}", applicationUserId);
    }

    private static string? ExtractFirstName(string fullName)
    {
        if (string.IsNullOrWhiteSpace(fullName)) return null;
        var parts = fullName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        return parts.Length > 0 ? parts[0] : null;
    }

    private static string? ExtractLastName(string fullName)
    {
        if (string.IsNullOrWhiteSpace(fullName)) return null;
        var parts = fullName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        return parts.Length > 1 ? string.Join(" ", parts.Skip(1)) : null;
    }
}
