using FirebaseAdmin.Auth;
using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Services;

namespace SingleClin.API.Jobs;

/// <summary>
/// Performs reconciliation between the local user store and Firebase Authentication.
/// Removes or quarantines orphan Firebase accounts and flags local inconsistencies.
/// </summary>
public class FirebaseUserReconciliationJob
{
    private readonly ApplicationDbContext _applicationDbContext;
    private readonly IFirebaseAuthService _firebaseAuthService;
    private readonly ILogger<FirebaseUserReconciliationJob> _logger;

    public FirebaseUserReconciliationJob(
        ApplicationDbContext applicationDbContext,
        IFirebaseAuthService firebaseAuthService,
        ILogger<FirebaseUserReconciliationJob> logger)
    {
        _applicationDbContext = applicationDbContext;
        _firebaseAuthService = firebaseAuthService;
        _logger = logger;
    }

    /// <summary>
    /// Executes reconciliation, disabling/removing orphan Firebase accounts and reporting divergences.
    /// </summary>
    public async Task<int> ExecuteAsync()
    {
        if (!_firebaseAuthService.IsConfigured)
        {
            _logger.LogWarning("Firebase reconciliation skipped because Firebase is not configured");
            return 0;
        }

        var firebaseAuth = FirebaseAuth.DefaultInstance;

        var localUsers = await _applicationDbContext.Users
            .Select(u => new { u.Id, u.Email, u.FirebaseUid })
            .ToListAsync();

        var localUids = new HashSet<string>(localUsers.Where(u => !string.IsNullOrWhiteSpace(u.FirebaseUid)).Select(u => u.FirebaseUid!), StringComparer.OrdinalIgnoreCase);
        var localEmails = new HashSet<string>(localUsers.Where(u => !string.IsNullOrWhiteSpace(u.Email)).Select(u => u.Email!.ToLowerInvariant()));

        var orphanCount = 0;
        var disabledCount = 0;

        await foreach (var firebaseUser in firebaseAuth.ListUsersAsync(null))
        {
            var uid = firebaseUser.Uid;
            var email = firebaseUser.Email?.ToLowerInvariant();

            var existsLocally = (!string.IsNullOrWhiteSpace(uid) && localUids.Contains(uid)) ||
                                (!string.IsNullOrWhiteSpace(email) && localEmails.Contains(email));

            if (!existsLocally)
            {
                // Quarantine account by disabling, then delete to avoid access.
                if (!firebaseUser.Disabled)
                {
                    var disableArgs = new UserRecordArgs
                    {
                        Uid = uid,
                        Disabled = true
                    };

                    await firebaseAuth.UpdateUserAsync(disableArgs);
                    disabledCount++;
                    _logger.LogWarning("Firebase orphan disabled: UID={Uid}, Email={Email}", firebaseUser.Uid, firebaseUser.Email);
                }

                await firebaseAuth.DeleteUserAsync(uid);
                orphanCount++;
                _logger.LogInformation("Firebase orphan removed: UID={Uid}, Email={Email}", firebaseUser.Uid, firebaseUser.Email);
            }
        }

        // Detect local users missing in Firebase and log alerts for manual resync.
        foreach (var localUser in localUsers.Where(u => !string.IsNullOrWhiteSpace(u.FirebaseUid)))
        {
            var firebaseUser = await _firebaseAuthService.GetUserAsync(localUser.FirebaseUid!);
            if (firebaseUser == null)
            {
                _logger.LogWarning("Local user missing in Firebase: UserId={UserId}, Email={Email}, FirebaseUid={FirebaseUid}",
                    localUser.Id, localUser.Email, localUser.FirebaseUid);
            }
        }

        _logger.LogInformation("Firebase reconciliation completed. OrphansRemoved={OrphanCount}, Disabled={DisabledCount}", orphanCount, disabledCount);
        return orphanCount;
    }
}
