using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Data.Models;

namespace SingleClin.API.Services;

/// <summary>
/// Saga-style orchestrator that guarantees user deletion happens in Firebase before the local removal.
/// </summary>
public class UserDeletionService : IUserDeletionService
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IRefreshTokenService _refreshTokenService;
    private readonly IFirebaseAuthService _firebaseAuthService;
    private readonly ApplicationDbContext _applicationDbContext;
    private readonly AppDbContext _appDbContext;
    private readonly ILogger<UserDeletionService> _logger;
    private readonly IDomainUserSyncService _domainUserSyncService;

    public UserDeletionService(
        UserManager<ApplicationUser> userManager,
        IRefreshTokenService refreshTokenService,
        IFirebaseAuthService firebaseAuthService,
        ApplicationDbContext applicationDbContext,
        AppDbContext appDbContext,
        ILogger<UserDeletionService> logger,
        IDomainUserSyncService domainUserSyncService)
    {
        _userManager = userManager;
        _refreshTokenService = refreshTokenService;
        _firebaseAuthService = firebaseAuthService;
        _applicationDbContext = applicationDbContext;
        _appDbContext = appDbContext;
        _logger = logger;
        _domainUserSyncService = domainUserSyncService;
    }

    public async Task<(bool Success, IEnumerable<string> Errors)> DeleteUserAsync(Guid userId)
    {
        var user = await _userManager.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null)
        {
            _logger.LogWarning("User deletion requested but not found: {UserId}", userId);
            return (false, new[] { "User not found" });
        }

        // Mark as inactive immediately to block further access while saga executes.
        if (user.IsActive)
        {
            user.IsActive = false;
            user.UpdatedAt = DateTime.UtcNow;
            await _userManager.UpdateAsync(user);
        }

        if (!_firebaseAuthService.IsConfigured)
        {
            const string message = "Firebase Admin SDK is not configured — cannot remove user from Firebase.";
            _logger.LogError(message + " UserId={UserId}", user.Id);
            return (false, new[] { message });
        }

        var firebaseDeletion = await DeleteFromFirebaseAsync(user);
        if (!firebaseDeletion.Success)
        {
            _logger.LogError("Firebase deletion failed for user {UserId}. Error={Error}", user.Id, firebaseDeletion.Error);
            return (false, new[] { firebaseDeletion.Error ?? "Failed to delete user in Firebase" });
        }

        // Revoke issued refresh tokens to avoid dangling sessions.
        await _refreshTokenService.RevokeAllUserTokensAsync(userId);

        // Remove domain representation if present.
        await _domainUserSyncService.RemoveUserAsync(userId);

        var identityResult = await _userManager.DeleteAsync(user);
        if (!identityResult.Succeeded)
        {
            var errors = identityResult.Errors.Select(e => e.Description).ToList();
            _logger.LogError("Failed to delete ApplicationUser {UserId}. Errors={Errors}", user.Id, string.Join(", ", errors));
            return (false, errors);
        }

        _logger.LogInformation("User deletion completed successfully for {UserId} ({Email})", user.Id, user.Email);
        return (true, Enumerable.Empty<string>());
    }

    private async Task<(bool Success, string? Error)> DeleteFromFirebaseAsync(ApplicationUser user)
    {
        var firebaseUid = user.FirebaseUid;

        if (string.IsNullOrWhiteSpace(firebaseUid) && !string.IsNullOrWhiteSpace(user.Email))
        {
            var firebaseUser = await _firebaseAuthService.GetUserByEmailAsync(user.Email);
            firebaseUid = firebaseUser?.Uid;
        }

        if (string.IsNullOrWhiteSpace(firebaseUid))
        {
            _logger.LogWarning("Firebase UID missing for user {UserId}. Assuming already removed in Firebase.", user.Id);
            return (true, null);
        }

        // If user already gone in Firebase treat as success for idempotency
        var existingFirebaseUser = await _firebaseAuthService.GetUserAsync(firebaseUid);
        if (existingFirebaseUser == null)
        {
            _logger.LogInformation("Firebase user already absent. UID={FirebaseUid}", firebaseUid);
            return (true, null);
        }

        var deletionSucceeded = await _firebaseAuthService.DeleteUserAsync(firebaseUid);
        if (!deletionSucceeded)
        {
            return (false, "Failed to delete user from Firebase Authentication");
        }

        _logger.LogInformation("Firebase user deleted successfully. UID={FirebaseUid}", firebaseUid);
        return (true, null);
    }
}
