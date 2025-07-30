namespace SingleClin.API.Services;

/// <summary>
/// Interface for QR Code token generation and validation
/// </summary>
public interface IQRCodeTokenService
{
    /// <summary>
    /// Generate a JWT token for QR Code with unique nonce
    /// </summary>
    /// <param name="userPlanId">User plan ID for the token</param>
    /// <param name="userId">User ID for the token</param>
    /// <param name="expirationMinutes">Token expiration in minutes (default: 30)</param>
    /// <returns>JWT token string and nonce for QR Code</returns>
    Task<(string token, string nonce)> GenerateTokenAsync(Guid userPlanId, string userId, int expirationMinutes = 30);

    /// <summary>
    /// Validate and consume a QR Code token
    /// </summary>
    /// <param name="token">JWT token to validate</param>
    /// <returns>QR token claims if valid, null otherwise</returns>
    Task<QRTokenClaims?> ValidateAndConsumeTokenAsync(string token);

    /// <summary>
    /// Extract claims from token without consuming the nonce
    /// </summary>
    /// <param name="token">JWT token to parse</param>
    /// <returns>QR token claims if valid, null otherwise</returns>
    Task<QRTokenClaims?> ParseTokenAsync(string token);
}

/// <summary>
/// QR Code token claims data
/// </summary>
public class QRTokenClaims
{
    public Guid UserPlanId { get; set; }
    public string UserId { get; set; } = string.Empty;
    public string Nonce { get; set; } = string.Empty;
    public DateTime IssuedAt { get; set; }
    public DateTime ExpiresAt { get; set; }
    public string TokenType { get; set; } = "qr_code";
    public bool IsExpired => DateTime.UtcNow > ExpiresAt;
}