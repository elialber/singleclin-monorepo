using FirebaseAdmin;
using FirebaseAdmin.Auth;
using Google.Apis.Auth.OAuth2;

namespace SingleClin.API.Services;

/// <summary>
/// Service for Firebase authentication operations
/// </summary>
public class FirebaseAuthService : IFirebaseAuthService
{
    private readonly ILogger<FirebaseAuthService> _logger;
    private readonly IConfiguration _configuration;
    private readonly bool _isConfigured;

    public FirebaseAuthService(ILogger<FirebaseAuthService> logger, IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
        _isConfigured = InitializeFirebase();
    }

    /// <summary>
    /// Check if Firebase is properly configured
    /// </summary>
    public bool IsConfigured => _isConfigured;

    private bool InitializeFirebase()
    {
        try
        {
            // Check if already initialized
            if (FirebaseApp.DefaultInstance != null)
            {
                return true;
            }

            var projectId = _configuration["Firebase:ProjectId"];
            if (string.IsNullOrEmpty(projectId))
            {
                _logger.LogWarning("Firebase ProjectId not configured. Social login will not be available.");
                return false;
            }

            var serviceAccountPath = _configuration["Firebase:ServiceAccountPath"];
            GoogleCredential credential;

            if (!string.IsNullOrEmpty(serviceAccountPath) && File.Exists(serviceAccountPath))
            {
                // Use service account file if provided
                credential = GoogleCredential.FromFile(serviceAccountPath);
                _logger.LogInformation("Firebase initialized with service account file");
            }
            else
            {
                try
                {
                    // Try to use application default credentials (for cloud environments)
                    credential = GoogleCredential.GetApplicationDefault();
                    _logger.LogInformation("Firebase initialized with application default credentials");
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to get application default credentials. Social login will not be available.");
                    return false;
                }
            }

            FirebaseApp.Create(new AppOptions
            {
                Credential = credential,
                ProjectId = projectId
            });

            _logger.LogInformation("Firebase Admin SDK initialized successfully for project: {ProjectId}", projectId);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to initialize Firebase Admin SDK");
            return false;
        }
    }

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
        if (!IsConfigured)
        {
            _logger.LogWarning("Firebase is not configured. Cannot create user.");
            return null;
        }

        try
        {
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

            var userRecord = await FirebaseAuth.DefaultInstance.CreateUserAsync(args);
            _logger.LogInformation("Successfully created Firebase user: {Uid}, Email: {Email}", userRecord.Uid, email);
            return userRecord;
        }
        catch (FirebaseAuthException ex)
        {
            _logger.LogWarning(ex, "Failed to create Firebase user: {Email}", email);
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error creating Firebase user: {Email}", email);
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