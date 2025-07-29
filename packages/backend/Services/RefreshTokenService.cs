using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Data.Models;

namespace SingleClin.API.Services;

/// <summary>
/// Service for managing refresh tokens
/// </summary>
public class RefreshTokenService : IRefreshTokenService
{
    private readonly ApplicationDbContext _context;
    private readonly IJwtService _jwtService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<RefreshTokenService> _logger;

    public RefreshTokenService(
        ApplicationDbContext context,
        IJwtService jwtService,
        IConfiguration configuration,
        ILogger<RefreshTokenService> logger)
    {
        _context = context;
        _jwtService = jwtService;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<RefreshToken> CreateRefreshTokenAsync(Guid userId, string? ipAddress = null, string? deviceInfo = null, int? expirationDays = null)
    {
        var refreshToken = new RefreshToken
        {
            Token = _jwtService.GenerateRefreshToken(),
            UserId = userId,
            ExpiresAt = DateTime.UtcNow.AddDays(expirationDays ?? _configuration.GetValue<int>("JWT:RefreshTokenExpirationInDays", 7)),
            IpAddress = ipAddress,
            DeviceInfo = deviceInfo
        };

        _context.RefreshTokens.Add(refreshToken);
        await _context.SaveChangesAsync();

        _logger.LogInformation("Created refresh token for user {UserId}", userId);
        return refreshToken;
    }

    public async Task<Guid?> ValidateRefreshTokenAsync(string token)
    {
        var refreshToken = await _context.RefreshTokens
            .Include(rt => rt.User)
            .FirstOrDefaultAsync(rt => rt.Token == token);

        if (refreshToken == null)
        {
            _logger.LogWarning("Refresh token not found");
            return null;
        }

        if (!refreshToken.IsActive)
        {
            _logger.LogWarning("Refresh token is not active. Token: {TokenId}, Revoked: {IsRevoked}, Expired: {IsExpired}", 
                refreshToken.Id, refreshToken.IsRevoked, refreshToken.ExpiresAt < DateTime.UtcNow);
            return null;
        }

        // Additional check for user account status
        if (!refreshToken.User.IsActive)
        {
            _logger.LogWarning("User account is not active. UserId: {UserId}", refreshToken.UserId);
            return null;
        }

        return refreshToken.UserId;
    }

    public async Task<bool> RevokeTokenAsync(string token)
    {
        var refreshToken = await _context.RefreshTokens
            .FirstOrDefaultAsync(rt => rt.Token == token);

        if (refreshToken == null)
        {
            _logger.LogWarning("Attempted to revoke non-existent token");
            return false;
        }

        refreshToken.IsRevoked = true;
        refreshToken.RevokedAt = DateTime.UtcNow;
        
        await _context.SaveChangesAsync();
        _logger.LogInformation("Revoked refresh token {TokenId}", refreshToken.Id);
        
        return true;
    }

    public async Task<int> RevokeAllUserTokensAsync(Guid userId)
    {
        var tokens = await _context.RefreshTokens
            .Where(rt => rt.UserId == userId && !rt.IsRevoked)
            .ToListAsync();

        if (!tokens.Any())
        {
            return 0;
        }

        var now = DateTime.UtcNow;
        foreach (var token in tokens)
        {
            token.IsRevoked = true;
            token.RevokedAt = now;
        }

        await _context.SaveChangesAsync();
        _logger.LogInformation("Revoked {Count} refresh tokens for user {UserId}", tokens.Count, userId);
        
        return tokens.Count;
    }

    public async Task<IEnumerable<RefreshToken>> GetActiveUserTokensAsync(Guid userId)
    {
        return await _context.RefreshTokens
            .Where(rt => rt.UserId == userId && rt.IsActive)
            .OrderByDescending(rt => rt.CreatedAt)
            .ToListAsync();
    }

    public async Task<int> CleanupExpiredTokensAsync()
    {
        var expiredTokens = await _context.RefreshTokens
            .Where(rt => rt.ExpiresAt < DateTime.UtcNow || (rt.IsRevoked && rt.RevokedAt < DateTime.UtcNow.AddDays(-30)))
            .ToListAsync();

        if (!expiredTokens.Any())
        {
            return 0;
        }

        _context.RefreshTokens.RemoveRange(expiredTokens);
        await _context.SaveChangesAsync();
        
        _logger.LogInformation("Cleaned up {Count} expired refresh tokens", expiredTokens.Count);
        return expiredTokens.Count;
    }

    public async Task<bool> UpdateDeviceInfoAsync(string token, string deviceInfo)
    {
        var refreshToken = await _context.RefreshTokens
            .FirstOrDefaultAsync(rt => rt.Token == token);

        if (refreshToken == null || !refreshToken.IsActive)
        {
            return false;
        }

        refreshToken.DeviceInfo = deviceInfo;
        refreshToken.UpdatedAt = DateTime.UtcNow;
        
        await _context.SaveChangesAsync();
        return true;
    }
}