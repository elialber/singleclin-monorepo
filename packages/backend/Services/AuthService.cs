using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Data.Models;
using SingleClin.API.Data.Models.Enums;
using SingleClin.API.Data.Enums;
using SingleClin.API.DTOs.Auth;

namespace SingleClin.API.Services;

/// <summary>
/// Service for handling authentication operations
/// </summary>
public class AuthService : IAuthService
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly IJwtService _jwtService;
    private readonly IRefreshTokenService _refreshTokenService;
    private readonly ApplicationDbContext _context;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        UserManager<ApplicationUser> userManager,
        SignInManager<ApplicationUser> signInManager,
        IJwtService jwtService,
        IRefreshTokenService refreshTokenService,
        ApplicationDbContext context,
        IConfiguration configuration,
        ILogger<AuthService> logger)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _jwtService = jwtService;
        _refreshTokenService = refreshTokenService;
        _context = context;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<(bool Success, AuthResponseDto? Response, string? Error)> RegisterAsync(RegisterDto registerDto, string? ipAddress = null)
    {
        try
        {
            // Validate clinic name requirement
            if (!registerDto.IsValid())
            {
                return (false, null, "Clinic name is required for clinic users");
            }

            // Check if email already exists
            var existingUser = await _userManager.FindByEmailAsync(registerDto.Email);
            if (existingUser != null)
            {
                return (false, null, "Email already registered");
            }

            // Create new user
            var user = new ApplicationUser
            {
                UserName = registerDto.Email,
                Email = registerDto.Email,
                FullName = registerDto.FullName,
                Role = registerDto.Role,
                EmailConfirmed = false, // Will be set to true in production after email verification
                CreatedAt = DateTime.UtcNow
            };

            // Handle clinic creation for clinic users
            if (registerDto.Role == Data.Enums.UserRole.ClinicOrigin || registerDto.Role == Data.Enums.UserRole.ClinicPartner)
            {
                var clinic = new Clinic
                {
                    Name = registerDto.ClinicName!,
                    Email = registerDto.Email,
                    Type = registerDto.Role == Data.Enums.UserRole.ClinicOrigin ? ClinicType.Origin : ClinicType.Partner,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Clinics.Add(clinic);
                await _context.SaveChangesAsync(); // Save to get the clinic ID
                
                user.ClinicId = clinic.Id;
            }

            // Create user with password
            var result = await _userManager.CreateAsync(user, registerDto.Password);
            if (!result.Succeeded)
            {
                var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                _logger.LogWarning("User registration failed for {Email}: {Errors}", registerDto.Email, errors);
                return (false, null, errors);
            }

            // Add role claim
            await _userManager.AddClaimAsync(user, new System.Security.Claims.Claim("role", user.Role.ToString()));
            
            // Add clinic claim if applicable
            if (user.ClinicId.HasValue)
            {
                await _userManager.AddClaimAsync(user, new System.Security.Claims.Claim("clinicId", user.ClinicId.Value.ToString()));
            }

            // Generate tokens
            var accessToken = _jwtService.GenerateAccessToken(user);
            var refreshToken = await _refreshTokenService.CreateRefreshTokenAsync(user.Id, ipAddress, null);

            _logger.LogInformation("User registered successfully: {UserId}, Role: {Role}", user.Id, user.Role);

            return (true, new AuthResponseDto
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken.Token,
                ExpiresIn = _configuration.GetValue<int>("JWT:AccessTokenExpirationInMinutes", 15) * 60,
                UserId = user.Id,
                Email = user.Email!,
                FullName = user.FullName,
                Role = user.Role,
                ClinicId = user.ClinicId,
                IsFirstLogin = true
            }, null);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during user registration for {Email}", registerDto.Email);
            return (false, null, "An error occurred during registration");
        }
    }

    public async Task<(bool Success, AuthResponseDto? Response, string? Error)> LoginAsync(LoginDto loginDto, string? ipAddress = null)
    {
        try
        {
            var user = await _userManager.FindByEmailAsync(loginDto.Email);
            if (user == null)
            {
                return (false, null, "Invalid email or password");
            }

            // Check if user is active
            if (!user.IsActive)
            {
                return (false, null, "Account is disabled");
            }

            // Verify password
            var result = await _signInManager.CheckPasswordSignInAsync(user, loginDto.Password, lockoutOnFailure: true);
            if (!result.Succeeded)
            {
                if (result.IsLockedOut)
                {
                    return (false, null, "Account is locked out. Please try again later");
                }
                return (false, null, "Invalid email or password");
            }

            // Update last login
            user.LastLoginAt = DateTime.UtcNow;
            await _userManager.UpdateAsync(user);

            // Generate tokens
            var accessToken = _jwtService.GenerateAccessToken(user);
            var expirationDays = loginDto.RememberMe ? 30 : _configuration.GetValue<int>("JWT:RefreshTokenExpirationInDays", 7);
            var refreshToken = await _refreshTokenService.CreateRefreshTokenAsync(user.Id, ipAddress, loginDto.DeviceInfo, expirationDays);

            _logger.LogInformation("User logged in successfully: {UserId}", user.Id);

            return (true, new AuthResponseDto
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken.Token,
                ExpiresIn = _configuration.GetValue<int>("JWT:AccessTokenExpirationInMinutes", 15) * 60,
                UserId = user.Id,
                Email = user.Email!,
                FullName = user.FullName,
                Role = user.Role,
                ClinicId = user.ClinicId,
                IsFirstLogin = user.LastLoginAt == null
            }, null);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during login for {Email}", loginDto.Email);
            return (false, null, "An error occurred during login");
        }
    }

    public async Task<(bool Success, AuthResponseDto? Response, string? Error)> RefreshTokenAsync(string refreshToken, string? ipAddress = null)
    {
        try
        {
            // Validate refresh token
            var userId = await _refreshTokenService.ValidateRefreshTokenAsync(refreshToken);
            if (!userId.HasValue)
            {
                return (false, null, "Invalid or expired refresh token");
            }

            // Get user
            var user = await _userManager.FindByIdAsync(userId.Value.ToString());
            if (user == null || !user.IsActive)
            {
                return (false, null, "User not found or inactive");
            }

            // Revoke old refresh token
            await _refreshTokenService.RevokeTokenAsync(refreshToken);

            // Generate new tokens
            var accessToken = _jwtService.GenerateAccessToken(user);
            var newRefreshToken = await _refreshTokenService.CreateRefreshTokenAsync(user.Id, ipAddress);

            _logger.LogInformation("Tokens refreshed for user: {UserId}", user.Id);

            return (true, new AuthResponseDto
            {
                AccessToken = accessToken,
                RefreshToken = newRefreshToken.Token,
                ExpiresIn = _configuration.GetValue<int>("JWT:AccessTokenExpirationInMinutes", 15) * 60,
                UserId = user.Id,
                Email = user.Email!,
                FullName = user.FullName,
                Role = user.Role,
                ClinicId = user.ClinicId,
                IsFirstLogin = false
            }, null);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during token refresh");
            return (false, null, "An error occurred during token refresh");
        }
    }

    public async Task<bool> LogoutAsync(Guid userId, string? refreshToken = null)
    {
        try
        {
            if (!string.IsNullOrEmpty(refreshToken))
            {
                // Revoke specific refresh token
                await _refreshTokenService.RevokeTokenAsync(refreshToken);
            }
            else
            {
                // Revoke all user tokens if no specific token provided
                await _refreshTokenService.RevokeAllUserTokensAsync(userId);
            }

            _logger.LogInformation("User logged out: {UserId}", userId);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during logout for user {UserId}", userId);
            return false;
        }
    }

    public async Task<int> RevokeAllUserTokensAsync(Guid userId)
    {
        try
        {
            var count = await _refreshTokenService.RevokeAllUserTokensAsync(userId);
            _logger.LogInformation("Revoked {Count} tokens for user {UserId}", count, userId);
            return count;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error revoking tokens for user {UserId}", userId);
            return 0;
        }
    }

    public async Task<int> CleanupExpiredTokensAsync()
    {
        try
        {
            var count = await _refreshTokenService.CleanupExpiredTokensAsync();
            _logger.LogInformation("Cleaned up {Count} expired tokens", count);
            return count;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during token cleanup");
            return 0;
        }
    }
}