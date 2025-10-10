using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using FirebaseAdmin.Auth;
using Microsoft.IdentityModel.Tokens;

namespace SingleClin.API.Middleware;

public class JwtAuthenticationMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IConfiguration _configuration;
    private readonly ILogger<JwtAuthenticationMiddleware> _logger;

    public JwtAuthenticationMiddleware(
        RequestDelegate next,
        IConfiguration configuration,
        ILogger<JwtAuthenticationMiddleware> logger)
    {
        _next = next;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var token = context.Request.Headers["Authorization"]
            .FirstOrDefault()?.Split(" ").Last();

        if (token != null)
        {
            await AttachUserToContext(context, token);
        }

        await _next(context);
    }

    private async Task AttachUserToContext(HttpContext context, string token)
    {
        try
        {
            // First, try to validate as a Firebase token
            var firebaseToken = await ValidateFirebaseToken(token);
            if (firebaseToken != null)
            {
                _logger.LogDebug("Successfully validated Firebase token for user: {Uid}", firebaseToken.Uid);

                // Convert Firebase token claims to our internal JWT claims
                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.NameIdentifier, firebaseToken.Uid),
                    new Claim(ClaimTypes.Email, firebaseToken.Claims.GetValueOrDefault("email")?.ToString() ?? ""),
                    new Claim("firebase_uid", firebaseToken.Uid)
                };

                // Add custom claims if present
                if (firebaseToken.Claims.TryGetValue("role", out var role))
                {
                    claims.Add(new Claim(ClaimTypes.Role, role.ToString() ?? ""));
                }

                if (firebaseToken.Claims.TryGetValue("clinicId", out var clinicId))
                {
                    claims.Add(new Claim("clinicId", clinicId.ToString() ?? ""));
                }

                var identity = new ClaimsIdentity(claims, "Firebase");
                context.User = new ClaimsPrincipal(identity);
                return;
            }

            // If not a Firebase token, try to validate as our internal JWT
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.ASCII.GetBytes(_configuration["JWT:SecretKey"] ?? "");

            var principal = tokenHandler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateIssuer = true,
                ValidIssuer = _configuration["JWT:Issuer"],
                ValidateAudience = true,
                ValidAudience = _configuration["JWT:Audience"],
                ClockSkew = TimeSpan.Zero
            }, out SecurityToken validatedToken);

            var jwtToken = (JwtSecurityToken)validatedToken;

            // Log all claims for debugging
            _logger.LogDebug("JWT token claims: {Claims}",
                string.Join(", ", jwtToken.Claims.Select(c => $"{c.Type}={c.Value}")));

            var userIdClaim = jwtToken.Claims.FirstOrDefault(x => x.Type == ClaimTypes.NameIdentifier);

            if (userIdClaim == null)
            {
                // Try alternative claim names as fallback
                userIdClaim = jwtToken.Claims.FirstOrDefault(x => x.Type == "sub") ??
                             jwtToken.Claims.FirstOrDefault(x => x.Type == "user_id") ??
                             jwtToken.Claims.FirstOrDefault(x => x.Type == JwtRegisteredClaimNames.Sub);

                if (userIdClaim != null)
                {
                    _logger.LogInformation("Using fallback claim '{ClaimType}' as NameIdentifier", userIdClaim.Type);
                    // Add the NameIdentifier claim with the fallback value
                    var claimsList = jwtToken.Claims.ToList();
                    claimsList.Add(new Claim(ClaimTypes.NameIdentifier, userIdClaim.Value));
                    var identity = new ClaimsIdentity(claimsList, "Jwt");
                    context.User = new ClaimsPrincipal(identity);
                    return;
                }

                _logger.LogWarning("JWT token does not contain NameIdentifier claim. Available claims: {Claims}",
                    string.Join(", ", jwtToken.Claims.Select(c => c.Type)));
                return;
            }

            _logger.LogDebug("Successfully validated JWT token for user: {UserId}", userIdClaim.Value);

            // Attach user to context on successful jwt validation
            context.User = new ClaimsPrincipal(new ClaimsIdentity(jwtToken.Claims, "Jwt"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error validating token");
            // Do nothing if jwt validation fails
            // User is not attached to context so request won't have access to secure routes
        }
    }

    private async Task<FirebaseToken?> ValidateFirebaseToken(string token)
    {
        try
        {
            _logger.LogDebug("🔥 Attempting Firebase token validation...");
            var decodedToken = await FirebaseAuth.DefaultInstance.VerifyIdTokenAsync(token);
            _logger.LogInformation("✅ Firebase token validated successfully for UID: {Uid}", decodedToken.Uid);
            return decodedToken;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "❌ Firebase token validation failed: {Message}", ex.Message);
            return null;
        }
    }
}