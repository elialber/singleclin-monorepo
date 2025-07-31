using FirebaseAdmin.Auth;

namespace SingleClin.API.Services;

/// <summary>
/// Service interface for Firebase authentication operations
/// </summary>
public interface IFirebaseAuthService
{
    /// <summary>
    /// Verify a Firebase ID token
    /// </summary>
    /// <param name="idToken">The Firebase ID token to verify</param>
    /// <returns>Firebase token information if valid, null otherwise</returns>
    Task<FirebaseToken?> VerifyIdTokenAsync(string idToken);

    /// <summary>
    /// Get user information from Firebase
    /// </summary>
    /// <param name="uid">Firebase user ID</param>
    /// <returns>User record if found, null otherwise</returns>
    Task<UserRecord?> GetUserAsync(string uid);

    /// <summary>
    /// Create a custom token for a user
    /// </summary>
    /// <param name="uid">User ID</param>
    /// <param name="claims">Optional custom claims</param>
    /// <returns>Custom token</returns>
    Task<string> CreateCustomTokenAsync(string uid, Dictionary<string, object>? claims = null);

    /// <summary>
    /// Delete a user from Firebase
    /// </summary>
    /// <param name="uid">Firebase user ID</param>
    /// <returns>Success status</returns>
    Task<bool> DeleteUserAsync(string uid);

    /// <summary>
    /// Check if Firebase is properly configured
    /// </summary>
    /// <returns>True if Firebase is configured, false otherwise</returns>
    bool IsConfigured { get; }

    /// <summary>
    /// Create a new user in Firebase Authentication
    /// </summary>
    /// <param name="email">User email</param>
    /// <param name="password">User password</param>
    /// <param name="displayName">User display name</param>
    /// <param name="emailVerified">Whether email is verified</param>
    /// <returns>Created user record</returns>
    Task<UserRecord?> CreateUserAsync(string email, string password, string? displayName = null, bool emailVerified = false);

    /// <summary>
    /// Update a user in Firebase Authentication
    /// </summary>
    /// <param name="uid">Firebase user ID</param>
    /// <param name="email">New email (optional)</param>
    /// <param name="password">New password (optional)</param>
    /// <param name="displayName">New display name (optional)</param>
    /// <param name="emailVerified">New email verified status (optional)</param>
    /// <returns>Updated user record</returns>
    Task<UserRecord?> UpdateUserAsync(string uid, string? email = null, string? password = null, string? displayName = null, bool? emailVerified = null);

    /// <summary>
    /// Get user by email from Firebase
    /// </summary>
    /// <param name="email">User email</param>
    /// <returns>User record if found, null otherwise</returns>
    Task<UserRecord?> GetUserByEmailAsync(string email);
}