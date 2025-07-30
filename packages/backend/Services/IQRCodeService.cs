namespace SingleClin.API.Services;

/// <summary>
/// Interface for QR Code orchestration service
/// </summary>
public interface IQRCodeService
{
    /// <summary>
    /// Generate complete QR Code for a user plan
    /// </summary>
    /// <param name="userPlanId">User plan ID</param>
    /// <param name="userId">User ID</param>
    /// <param name="size">QR Code size in pixels</param>
    /// <param name="expirationMinutes">Token expiration in minutes</param>
    /// <returns>Complete QR Code data</returns>
    Task<QRCodeResult> GenerateQRCodeAsync(Guid userPlanId, string userId, int size = 300, int expirationMinutes = 30);

    /// <summary>
    /// Validate user plan before QR Code generation
    /// </summary>
    /// <param name="userPlanId">User plan ID to validate</param>
    /// <returns>True if plan is valid for QR Code generation</returns>
    Task<bool> ValidateUserPlanAsync(Guid userPlanId);

    /// <summary>
    /// Get QR Code generation metrics
    /// </summary>
    /// <returns>QR Code generation statistics</returns>
    Task<QRCodeMetrics> GetMetricsAsync();
}

/// <summary>
/// QR Code generation result
/// </summary>
public class QRCodeResult
{
    public bool Success { get; set; }
    public string QRCodeDataUrl { get; set; } = string.Empty;
    public string Token { get; set; } = string.Empty;
    public string Nonce { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;
    public string? ErrorMessage { get; set; }
}

/// <summary>
/// QR Code generation metrics
/// </summary>
public class QRCodeMetrics
{
    public long TotalGenerated { get; set; }
    public long SuccessfulGenerated { get; set; }
    public long FailedGenerated { get; set; }
    public double SuccessRate => TotalGenerated > 0 ? (double)SuccessfulGenerated / TotalGenerated * 100 : 0;
    public DateTime LastGenerated { get; set; }
    public DateTime MetricsUpdatedAt { get; set; } = DateTime.UtcNow;
}