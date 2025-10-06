using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace SingleClin.API.Services;

/// <summary>
/// Service for generating and validating QR Code JWT tokens
/// </summary>
public class QRCodeTokenService : IQRCodeTokenService
{
    private readonly IConfiguration _configuration;
    private readonly IRedisService _redisService;
    private readonly ILogger<QRCodeTokenService> _logger;
    private readonly JwtSecurityTokenHandler _tokenHandler;

    public QRCodeTokenService(
        IConfiguration configuration,
        IRedisService redisService,
        ILogger<QRCodeTokenService> logger)
    {
        _configuration = configuration;
        _redisService = redisService;
        _logger = logger;
        _tokenHandler = new JwtSecurityTokenHandler();
    }

    /// <summary>
    /// Generate a JWT token for QR Code with unique nonce
    /// </summary>
    public async Task<(string token, string nonce)> GenerateTokenAsync(Guid userPlanId, string userId, int expirationMinutes = 30)
    {
        try
        {
            // Generate unique nonce
            var nonce = _redisService.GenerateNonce();
            var issuedAt = DateTime.UtcNow;
            var expiresAt = issuedAt.AddMinutes(expirationMinutes);

            // Create JWT claims
            var claims = new[]
            {
                new Claim("userPlanId", userPlanId.ToString()),
                new Claim("userId", userId),
                new Claim("nonce", nonce),
                new Claim("tokenType", "qr_code"),
                new Claim(JwtRegisteredClaimNames.Iat, new DateTimeOffset(issuedAt).ToUnixTimeSeconds().ToString(), ClaimValueTypes.Integer64),
                new Claim(JwtRegisteredClaimNames.Exp, new DateTimeOffset(expiresAt).ToUnixTimeSeconds().ToString(), ClaimValueTypes.Integer64),
                new Claim(JwtRegisteredClaimNames.Nbf, new DateTimeOffset(issuedAt).ToUnixTimeSeconds().ToString(), ClaimValueTypes.Integer64),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                new Claim(JwtRegisteredClaimNames.Iss, _configuration["JWT:Issuer"]!),
                new Claim(JwtRegisteredClaimNames.Aud, _configuration["JWT:Audience"]!)
            };

            // Create token descriptor
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = expiresAt,
                Issuer = _configuration["JWT:Issuer"],
                Audience = _configuration["JWT:Audience"],
                SigningCredentials = new SigningCredentials(GetSecurityKey(), SecurityAlgorithms.HmacSha256Signature)
            };

            // Generate token
            var token = _tokenHandler.CreateToken(tokenDescriptor);
            var tokenString = _tokenHandler.WriteToken(token);

            // Store nonce in Redis with user plan data
            var nonceData = System.Text.Json.JsonSerializer.Serialize(new
            {
                userPlanId = userPlanId.ToString(),
                userId = userId,
                issuedAt = issuedAt,
                expiresAt = expiresAt,
                tokenType = "qr_code"
            });

            var stored = await _redisService.StoreNonceAsync(nonce, nonceData, expirationMinutes);

            if (!stored)
            {
                _logger.LogError("Failed to store nonce in Redis for user plan {UserPlanId}", userPlanId);
                throw new InvalidOperationException("Failed to store QR Code nonce");
            }

            _logger.LogInformation("Generated QR Code token for user plan {UserPlanId} with expiration {ExpiresAt}",
                userPlanId, expiresAt);

            return (tokenString, nonce);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to generate QR Code token for user plan {UserPlanId}", userPlanId);
            throw;
        }
    }

    /// <summary>
    /// Validate and consume a QR Code token
    /// </summary>
    public async Task<QRTokenClaims?> ValidateAndConsumeTokenAsync(string token)
    {
        try
        {
            // First parse the token to get claims
            var claims = await ParseTokenAsync(token);
            if (claims == null)
            {
                return null;
            }

            // Check if token is expired
            if (claims.IsExpired)
            {
                _logger.LogWarning("QR Code token is expired for nonce {Nonce}", claims.Nonce);
                return null;
            }

            // Consume the nonce from Redis (this prevents reuse)
            var nonceData = await _redisService.ConsumeNonceAsync(claims.Nonce);
            if (nonceData == null)
            {
                _logger.LogWarning("Nonce {Nonce} not found in Redis or already consumed", claims.Nonce);
                return null;
            }

            _logger.LogInformation("Successfully validated and consumed QR Code token for user plan {UserPlanId}",
                claims.UserPlanId);

            return claims;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to validate and consume QR Code token");
            return null;
        }
    }

    /// <summary>
    /// Extract claims from token without consuming the nonce
    /// </summary>
    public Task<QRTokenClaims?> ParseTokenAsync(string token)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(token))
            {
                return Task.FromResult<QRTokenClaims?>(null);
            }

            // Validate token structure and signature
            var tokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = GetSecurityKey(),
                ValidateIssuer = true,
                ValidIssuer = _configuration["JWT:Issuer"],
                ValidateAudience = true,
                ValidAudience = _configuration["JWT:Audience"],
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            };

            var principal = _tokenHandler.ValidateToken(token, tokenValidationParameters, out var validatedToken);

            // Ensure it's a JWT token
            if (validatedToken is not JwtSecurityToken jwtToken)
            {
                _logger.LogWarning("Token is not a valid JWT token");
                return Task.FromResult<QRTokenClaims?>(null);
            }

            // Extract QR-specific claims
            var userPlanIdClaim = principal.FindFirst("userPlanId")?.Value;
            var userIdClaim = principal.FindFirst("userId")?.Value;
            var nonceClaim = principal.FindFirst("nonce")?.Value;
            var tokenTypeClaim = principal.FindFirst("tokenType")?.Value;
            var iatClaim = principal.FindFirst(JwtRegisteredClaimNames.Iat)?.Value;
            var expClaim = principal.FindFirst(JwtRegisteredClaimNames.Exp)?.Value;

            // Validate required claims
            if (string.IsNullOrEmpty(userPlanIdClaim) ||
                string.IsNullOrEmpty(userIdClaim) ||
                string.IsNullOrEmpty(nonceClaim) ||
                tokenTypeClaim != "qr_code")
            {
                _logger.LogWarning("QR Code token missing required claims");
                return Task.FromResult<QRTokenClaims?>(null);
            }

            if (!Guid.TryParse(userPlanIdClaim, out var userPlanId))
            {
                _logger.LogWarning("Invalid userPlanId in QR Code token: {UserPlanId}", userPlanIdClaim);
                return Task.FromResult<QRTokenClaims?>(null);
            }

            var issuedAt = DateTime.UnixEpoch;
            var expiresAt = DateTime.UnixEpoch;

            if (long.TryParse(iatClaim, out var iatUnix))
            {
                issuedAt = DateTimeOffset.FromUnixTimeSeconds(iatUnix).DateTime;
            }

            if (long.TryParse(expClaim, out var expUnix))
            {
                expiresAt = DateTimeOffset.FromUnixTimeSeconds(expUnix).DateTime;
            }

            var qrClaims = new QRTokenClaims
            {
                UserPlanId = userPlanId,
                UserId = userIdClaim,
                Nonce = nonceClaim,
                TokenType = tokenTypeClaim,
                IssuedAt = issuedAt,
                ExpiresAt = expiresAt
            };

            _logger.LogDebug("Successfully parsed QR Code token for user plan {UserPlanId}", userPlanId);
            return Task.FromResult<QRTokenClaims?>(qrClaims);
        }
        catch (SecurityTokenExpiredException)
        {
            _logger.LogWarning("QR Code token has expired");
            return Task.FromResult<QRTokenClaims?>(null);
        }
        catch (SecurityTokenException ex)
        {
            _logger.LogWarning("Invalid QR Code token: {Message}", ex.Message);
            return Task.FromResult<QRTokenClaims?>(null);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to parse QR Code token");
            return Task.FromResult<QRTokenClaims?>(null);
        }
    }

    /// <summary>
    /// Get the security key for JWT signing/validation
    /// </summary>
    private SymmetricSecurityKey GetSecurityKey()
    {
        var secretKey = _configuration["JWT:SecretKey"];
        if (string.IsNullOrEmpty(secretKey))
        {
            throw new InvalidOperationException("JWT:SecretKey configuration is missing");
        }

        return new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
    }
}
