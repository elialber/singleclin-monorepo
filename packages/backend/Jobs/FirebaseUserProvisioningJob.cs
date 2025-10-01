using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Identity;
using SingleClin.API.Data.Models;
using SingleClin.API.Services;

namespace SingleClin.API.Jobs;

public class FirebaseUserProvisioningJob
{
    private readonly IFirebaseAuthService _firebaseAuthService;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IDataProtector _protector;
    private readonly IDomainUserSyncService _domainUserSyncService;
    private readonly ILogger<FirebaseUserProvisioningJob> _logger;

    public FirebaseUserProvisioningJob(
        IFirebaseAuthService firebaseAuthService,
        UserManager<ApplicationUser> userManager,
        IDataProtectionProvider dataProtectionProvider,
        IDomainUserSyncService domainUserSyncService,
        ILogger<FirebaseUserProvisioningJob> logger)
    {
        _firebaseAuthService = firebaseAuthService;
        _userManager = userManager;
        _protector = dataProtectionProvider.CreateProtector("FirebaseUserProvisioning");
        _domainUserSyncService = domainUserSyncService;
        _logger = logger;
    }

    public async Task ExecuteAsync(Guid userId, string email, string protectedPassword, string? displayName)
    {
        if (!_firebaseAuthService.IsConfigured)
        {
            _logger.LogWarning("Firebase not configured. Skipping provisioning for UserId={UserId}", userId);
            return;
        }

        var user = await _userManager.FindByIdAsync(userId.ToString())
                   ?? throw new InvalidOperationException($"ApplicationUser {userId} not found for Firebase provisioning");

        if (!string.IsNullOrWhiteSpace(user.FirebaseUid))
        {
            var existing = await _firebaseAuthService.GetUserAsync(user.FirebaseUid);
            if (existing != null)
            {
                _logger.LogInformation("Firebase user already provisioned for UserId={UserId}", userId);
                return;
            }
        }

        var password = _protector.Unprotect(protectedPassword);

        var firebaseUser = await _firebaseAuthService.CreateUserAsync(
            email,
            password,
            displayName ?? user.FullName,
            emailVerified: user.EmailConfirmed);

        if (firebaseUser == null)
        {
            throw new InvalidOperationException($"Failed to create Firebase user for {email}");
        }

        user.FirebaseUid = firebaseUser.Uid;
        await _userManager.UpdateAsync(user);
        await _userManager.UpdateSecurityStampAsync(user);

        await _domainUserSyncService.EnsureUserAsync(user);

        _logger.LogInformation("Firebase provisioning completed for UserId={UserId}, FirebaseUid={FirebaseUid}", userId, firebaseUser.Uid);
    }
}
