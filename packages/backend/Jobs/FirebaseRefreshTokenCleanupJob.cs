using System.Linq;
using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Data.Models;

namespace SingleClin.API.Jobs;

/// <summary>
/// Job responsible for revoking duplicate refresh tokens generated for Firebase-authenticated users.
/// Keeps the most recent active token per user and revokes the remainder.
/// </summary>
public class FirebaseRefreshTokenCleanupJob
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<FirebaseRefreshTokenCleanupJob> _logger;

    public FirebaseRefreshTokenCleanupJob(ApplicationDbContext context, ILogger<FirebaseRefreshTokenCleanupJob> logger)
    {
        _context = context;
        _logger = logger;
    }

    /// <summary>
    /// Executes the cleanup routine.
    /// </summary>
    public async Task<int> ExecuteAsync()
    {
        var tokens = await _context.RefreshTokens
            .Include(rt => rt.User)
            .Where(rt => rt.IsActive && rt.User.FirebaseUid != null)
            .OrderByDescending(rt => rt.CreatedAt)
            .ToListAsync();

        if (!tokens.Any())
        {
            _logger.LogInformation("Firebase refresh token cleanup executed - no active tokens found");
            return 0;
        }

        var now = DateTime.UtcNow;
        var revokedCount = 0;

        foreach (var group in tokens.GroupBy(t => t.UserId))
        {
            // Keep the most recent token (first item after ordering descending)
            foreach (var token in group.Skip(1))
            {
                token.IsRevoked = true;
                token.RevokedAt = now;
                revokedCount++;
            }
        }

        if (revokedCount == 0)
        {
            _logger.LogInformation("Firebase refresh token cleanup executed - no tokens required revocation");
            return 0;
        }

        await _context.SaveChangesAsync();
        _logger.LogInformation("Firebase refresh token cleanup revoked {Count} duplicate tokens", revokedCount);

        return revokedCount;
    }
}
