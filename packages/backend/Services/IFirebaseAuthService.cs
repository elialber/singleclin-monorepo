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
}