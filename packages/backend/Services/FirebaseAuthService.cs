using FirebaseAdmin;
using FirebaseAdmin.Auth;
using Google.Apis.Auth.OAuth2;
using System.IO;

namespace SingleClin.API.Services;

/// <summary>
/// Service for Firebase authentication operations
/// </summary>
public class FirebaseAuthService : IFirebaseAuthService
{
    private readonly ILogger<FirebaseAuthService> _logger;
    private readonly IConfiguration _configuration;

    public FirebaseAuthService(ILogger<FirebaseAuthService> logger, IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
    }

    /// <summary>
    /// Check if Firebase is properly configured
    /// </summary>
    public bool IsConfigured => FirebaseApp.DefaultInstance != null;


    public async Task<FirebaseToken?> VerifyIdTokenAsync(string idToken)
    {
        if (!IsConfigured)
        {
            _logger.LogWarning("Firebase is not configured. Cannot verify ID token.");
            return null;
        }

        try
        {
            var decodedToken = await FirebaseAuth.DefaultInstance.VerifyIdTokenAsync(idToken);
            _logger.LogInformation("Successfully verified Firebase token for user: {Uid}", decodedToken.Uid);
            return decodedToken;
        }
        catch (FirebaseAuthException ex)
        {
            _logger.LogWarning(ex, "Failed to verify Firebase ID token");
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error verifying Firebase ID token");
            return null;
        }
    }

    public async Task<UserRecord?> GetUserAsync(string uid)
    {
        if (!IsConfigured)
        {
            _logger.LogWarning("Firebase is not configured. Cannot get user.");
            return null;
        }

        try
        {
            var user = await FirebaseAuth.DefaultInstance.GetUserAsync(uid);
            _logger.LogInformation("Successfully retrieved Firebase user: {Uid}", uid);
            return user;
        }
        catch (FirebaseAuthException ex)
        {
            _logger.LogWarning(ex, "Failed to get Firebase user: {Uid}", uid);
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error getting Firebase user: {Uid}", uid);
            return null;
        }
    }

    public async Task<string> CreateCustomTokenAsync(string uid, Dictionary<string, object>? claims = null)
    {
        if (!IsConfigured)
        {
            throw new InvalidOperationException("Firebase is not configured");
        }

        try
        {
            string customToken;
            if (claims != null && claims.Any())
            {
                customToken = await FirebaseAuth.DefaultInstance.CreateCustomTokenAsync(uid, claims);
            }
            else
            {
                customToken = await FirebaseAuth.DefaultInstance.CreateCustomTokenAsync(uid);
            }

            _logger.LogInformation("Successfully created custom token for user: {Uid}", uid);
            return customToken;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create custom token for user: {Uid}", uid);
            throw;
        }
    }

    public async Task<bool> DeleteUserAsync(string uid)
    {
        if (!IsConfigured)
        {
            _logger.LogWarning("Firebase is not configured. Cannot delete user.");
            return false;
        }

        try
        {
            await FirebaseAuth.DefaultInstance.DeleteUserAsync(uid);
            _logger.LogInformation("Successfully deleted Firebase user: {Uid}", uid);
            return true;
        }
        catch (FirebaseAuthException ex)
        {
            _logger.LogWarning(ex, "Failed to delete Firebase user: {Uid}", uid);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error deleting Firebase user: {Uid}", uid);
            return false;
        }
    }

    public async Task<UserRecord?> CreateUserAsync(string email, string password, string? displayName = null, bool emailVerified = false)
    {
        _logger.LogInformation("CreateUserAsync called - Email: {Email}, DisplayName: {DisplayName}", email, displayName);
        _logger.LogInformation("Firebase IsConfigured: {IsConfigured}, FirebaseApp.DefaultInstance: {HasInstance}",
            IsConfigured, FirebaseApp.DefaultInstance != null);

        if (!IsConfigured)
        {
            _logger.LogError("Firebase is not configured! Cannot create user.");
            return null;
        }

        try
        {
            _logger.LogInformation("Creating user in Firebase Authentication...");

            var args = new UserRecordArgs
            {
                Email = email,
                Password = password,
                EmailVerified = emailVerified,
                Disabled = false
            };

            if (!string.IsNullOrEmpty(displayName))
            {
                args.DisplayName = displayName;
            }

            _logger.LogInformation("Calling Firebase CreateUserAsync with args: Email={Email}, DisplayName={DisplayName}, EmailVerified={EmailVerified}",
                args.Email, args.DisplayName, args.EmailVerified);

            var userRecord = await FirebaseAuth.DefaultInstance.CreateUserAsync(args);

            _logger.LogInformation("Firebase user created successfully! UID: {Uid}, Email: {Email}",
                userRecord.Uid, userRecord.Email);

            return userRecord;
        }
        catch (FirebaseAuthException ex)
        {
            _logger.LogError(ex, "Firebase Authentication Error - Code: {ErrorCode}, Message: {Message}, Email: {Email}",
                ex.ErrorCode, ex.Message, email);

            // Log more details about the error
            if (ex.Message.Contains("EMAIL_EXISTS") || ex.Message.Contains("already exists"))
            {
                _logger.LogWarning("User with email {Email} already exists in Firebase", email);
            }

            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error creating Firebase user for email: {Email}", email);
            return null;
        }
    }

    public async Task<UserRecord?> UpdateUserAsync(string uid, string? email = null, string? password = null, string? displayName = null, bool? emailVerified = null)
    {
        if (!IsConfigured)
        {
            _logger.LogWarning("Firebase is not configured. Cannot update user.");
            return null;
        }

        try
        {
            var args = new UserRecordArgs
            {
                Uid = uid
            };

            if (!string.IsNullOrEmpty(email))
            {
                args.Email = email;
            }

            if (!string.IsNullOrEmpty(password))
            {
                args.Password = password;
            }

            if (!string.IsNullOrEmpty(displayName))
            {
                args.DisplayName = displayName;
            }

            if (emailVerified.HasValue)
            {
                args.EmailVerified = emailVerified.Value;
            }

            var userRecord = await FirebaseAuth.DefaultInstance.UpdateUserAsync(args);
            _logger.LogInformation("Successfully updated Firebase user: {Uid}", uid);
            return userRecord;
        }
        catch (FirebaseAuthException ex)
        {
            _logger.LogWarning(ex, "Failed to update Firebase user: {Uid}", uid);
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error updating Firebase user: {Uid}", uid);
            return null;
        }
    }

    public async Task<UserRecord?> GetUserByEmailAsync(string email)
    {
        if (!IsConfigured)
        {
            _logger.LogWarning("Firebase is not configured. Cannot get user by email.");
            return null;
        }

        try
        {
            var user = await FirebaseAuth.DefaultInstance.GetUserByEmailAsync(email);
            _logger.LogInformation("Successfully retrieved Firebase user by email: {Email}", email);
            return user;
        }
        catch (FirebaseAuthException ex)
        {
            _logger.LogWarning(ex, "Failed to get Firebase user by email: {Email}", email);
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error getting Firebase user by email: {Email}", email);
            return null;
        }
    }
}