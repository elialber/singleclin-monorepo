namespace SingleClin.API.Services;

/// <summary>
/// Interface for Redis operations for QR Code nonce management
/// </summary>
public interface IRedisService
{
    /// <summary>
    /// Store a nonce with expiration for QR Code generation
    /// </summary>
    /// <param name="nonce">Unique nonce identifier</param>
    /// <param name="userData">User data associated with the nonce</param>
    /// <param name="expirationMinutes">Expiration time in minutes (default: 30)</param>
    /// <returns>True if stored successfully</returns>
    Task<bool> StoreNonceAsync(string nonce, string userData, int expirationMinutes = 30);

    /// <summary>
    /// Retrieve and consume (remove) a nonce from Redis
    /// </summary>
    /// <param name="nonce">Nonce to retrieve and consume</param>
    /// <returns>User data if nonce exists and is valid, null otherwise</returns>
    Task<string?> ConsumeNonceAsync(string nonce);

    /// <summary>
    /// Check if a nonce exists without consuming it
    /// </summary>
    /// <param name="nonce">Nonce to check</param>
    /// <returns>True if nonce exists and is valid</returns>
    Task<bool> NonceExistsAsync(string nonce);

    /// <summary>
    /// Generate a new unique nonce
    /// </summary>
    /// <returns>Unique nonce string</returns>
    string GenerateNonce();

    /// <summary>
    /// Check Redis connection health
    /// </summary>
    /// <returns>True if connected to Redis</returns>
    Task<bool> IsConnectedAsync();
}