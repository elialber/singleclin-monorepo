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
    private readonly IFirebaseAuthService _firebaseAuthService;
    private readonly ApplicationDbContext _context;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        UserManager<ApplicationUser> userManager,
        SignInManager<ApplicationUser> signInManager,
        IJwtService jwtService,
        IRefreshTokenService refreshTokenService,
        IFirebaseAuthService firebaseAuthService,
        ApplicationDbContext context,
        IConfiguration configuration,
        ILogger<AuthService> logger)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _jwtService = jwtService;
        _refreshTokenService = refreshTokenService;
        _firebaseAuthService = firebaseAuthService;
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

            // Create user in Firebase
            _logger.LogInformation("=== FIREBASE USER CREATION START ===");
            _logger.LogInformation("Firebase IsConfigured: {IsConfigured}", _firebaseAuthService.IsConfigured);
            _logger.LogInformation("Email: {Email}, FullName: {FullName}", registerDto.Email, registerDto.FullName);

            if (_firebaseAuthService.IsConfigured)
            {
                _logger.LogInformation("Firebase is configured. Attempting to create user...");
                try
                {
                    var firebaseUser = await _firebaseAuthService.CreateUserAsync(
                        registerDto.Email,
                        registerDto.Password,
                        registerDto.FullName,
                        false // Email not verified yet
                    );

                    if (firebaseUser != null)
                    {
                        // Update user with Firebase UID
                        user.FirebaseUid = firebaseUser.Uid;
                        await _userManager.UpdateAsync(user);
                        _logger.LogInformation("✅ SUCCESS: Created user in Firebase - Email: {Email}, UID: {FirebaseUid}",
                            registerDto.Email, firebaseUser.Uid);
                    }
                    else
                    {
                        _logger.LogError("❌ FAILED: CreateUserAsync returned null for email: {Email}", registerDto.Email);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "❌ EXCEPTION: Error creating user in Firebase for email: {Email}", registerDto.Email);
                }
            }
            else
            {
                _logger.LogError("❌ Firebase NOT configured! Cannot create user in Firebase for: {Email}", registerDto.Email);
            }
            _logger.LogInformation("=== FIREBASE USER CREATION END ===");

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
                ExpiresIn = _configuration.GetValue<int>("JWT:AccessTokenExpirationInMinutes", 120) * 60,
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
                ExpiresIn = _configuration.GetValue<int>("JWT:AccessTokenExpirationInMinutes", 120) * 60,
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
                ExpiresIn = _configuration.GetValue<int>("JWT:AccessTokenExpirationInMinutes", 120) * 60,
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

    public async Task<(bool Success, AuthResponseDto? Response, string? Error)> SocialLoginAsync(SocialLoginDto socialLoginDto, string? ipAddress = null)
    {
        try
        {
            // Check if Firebase is configured
            if (!_firebaseAuthService.IsConfigured)
            {
                return (false, null, "Social login is not available. Firebase is not configured.");
            }

            // Verify Firebase ID token
            var firebaseToken = await _firebaseAuthService.VerifyIdTokenAsync(socialLoginDto.IdToken);
            if (firebaseToken == null)
            {
                return (false, null, "Invalid or expired social login token");
            }

            // Extract user information from Firebase token
            var email = firebaseToken.Claims.TryGetValue("email", out var emailClaim) ? emailClaim?.ToString() : null;
            var firebaseUid = firebaseToken.Uid;
            var displayName = firebaseToken.Claims.TryGetValue("name", out var nameClaim) ? nameClaim?.ToString() : socialLoginDto.FullName;
            var emailVerified = firebaseToken.Claims.TryGetValue("email_verified", out var verifiedClaim) &&
                              verifiedClaim?.ToString()?.ToLower() == "true";

            if (string.IsNullOrEmpty(email))
            {
                return (false, null, "Email not provided by social login provider");
            }

            // Check if user already exists
            var existingUser = await _userManager.FindByEmailAsync(email);
            ApplicationUser user;
            bool isNewUser = false;

            if (existingUser != null)
            {
                // User exists - update last login
                user = existingUser;
                user.LastLoginAt = DateTime.UtcNow;

                // Update email confirmed status if verified by social provider
                if (emailVerified && !user.EmailConfirmed)
                {
                    user.EmailConfirmed = true;
                }

                await _userManager.UpdateAsync(user);
            }
            else
            {
                // Create new user
                isNewUser = true;
                user = new ApplicationUser
                {
                    UserName = email,
                    Email = email,
                    FullName = displayName ?? email.Split('@')[0], // Use email prefix if no name provided
                    Role = Data.Enums.UserRole.Patient, // Default role for social login users
                    EmailConfirmed = emailVerified,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    LastLoginAt = DateTime.UtcNow
                };

                // Create user without password
                var createResult = await _userManager.CreateAsync(user);
                if (!createResult.Succeeded)
                {
                    var errors = string.Join(", ", createResult.Errors.Select(e => e.Description));
                    _logger.LogWarning("Social login user creation failed for {Email}: {Errors}", email, errors);
                    return (false, null, $"Failed to create user: {errors}");
                }

                // Add role claim
                await _userManager.AddClaimAsync(user, new System.Security.Claims.Claim("role", user.Role.ToString()));

                // Add external login info
                var loginInfo = new Microsoft.AspNetCore.Identity.ExternalLoginInfo(
                    new System.Security.Claims.ClaimsPrincipal(),
                    socialLoginDto.Provider.ToLower(),
                    firebaseUid,
                    socialLoginDto.Provider);

                await _userManager.AddLoginAsync(user, loginInfo);
            }

            // Generate tokens
            var accessToken = _jwtService.GenerateAccessToken(user);
            var refreshToken = await _refreshTokenService.CreateRefreshTokenAsync(
                user.Id,
                ipAddress,
                socialLoginDto.DeviceInfo);

            _logger.LogInformation("Social login successful for user: {UserId}, Provider: {Provider}, IsNew: {IsNew}",
                user.Id, socialLoginDto.Provider, isNewUser);

            return (true, new AuthResponseDto
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken.Token,
                ExpiresIn = _configuration.GetValue<int>("JWT:AccessTokenExpirationInMinutes", 120) * 60,
                UserId = user.Id,
                Email = user.Email!,
                FullName = user.FullName,
                Role = user.Role,
                ClinicId = user.ClinicId,
                IsFirstLogin = isNewUser
            }, null);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during social login for provider {Provider}", socialLoginDto.Provider);
            return (false, null, "An error occurred during social login");
        }
    }

    public async Task<Dictionary<string, string>> GetUserClaimsAsync(Guid userId)
    {
        var claims = new Dictionary<string, string>();

        try
        {
            // Get user with clinic information
            var user = await _context.Users
                .Include(u => u.Clinic)
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (user == null)
            {
                _logger.LogWarning("User not found: {UserId}", userId);
                return claims;
            }

            // Basic user claims
            claims["userId"] = user.Id.ToString();
            claims["email"] = user.Email ?? "";
            claims["fullName"] = user.FullName ?? "";
            claims["role"] = user.Role.ToString();
            claims["isActive"] = user.IsActive.ToString();
            claims["emailConfirmed"] = user.EmailConfirmed.ToString();

            // Clinic-related claims for clinic users
            if ((user.Role == Data.Enums.UserRole.ClinicOrigin || user.Role == Data.Enums.UserRole.ClinicPartner) && user.ClinicId.HasValue)
            {
                claims["clinicId"] = user.ClinicId.Value.ToString();

                if (user.Clinic != null)
                {
                    claims["clinicName"] = user.Clinic.Name;
                    claims["clinicType"] = user.Clinic.Type.ToString();
                }

                // Add clinic-specific permissions
                var clinicPermissions = GetClinicPermissions(user.Role, user.Clinic?.Type);
                if (clinicPermissions.Any())
                {
                    claims["permissions"] = string.Join(",", clinicPermissions);
                }
            }

            // Add admin permissions for administrators
            if (user.Role == Data.Enums.UserRole.Administrator)
            {
                var adminPermissions = GetAdminPermissions();
                claims["permissions"] = string.Join(",", adminPermissions);
            }

            // Add patient permissions for patients
            if (user.Role == Data.Enums.UserRole.Patient)
            {
                var patientPermissions = GetPatientPermissions();
                claims["permissions"] = string.Join(",", patientPermissions);
            }

            _logger.LogDebug("Retrieved {Count} claims for user: {UserId}", claims.Count, userId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving claims for user: {UserId}", userId);
        }

        return claims;
    }

    private static string[] GetAdminPermissions()
    {
        return new[]
        {
            // User management
            "users.read", "users.write", "users.delete", "users.manage",
            
            // Clinic management
            "clinics.read", "clinics.write", "clinics.delete", "clinics.manage",
            
            // Patient management
            "patients.read", "patients.write", "patients.delete",
            
            // System administration
            "system.configure", "system.monitor", "system.backup", "system.logs",
            
            // Credits and transactions
            "credits.read", "credits.write", "credits.manage",
            "transactions.read", "transactions.write",
            
            // Reports and analytics
            "reports.read", "reports.generate", "analytics.read"
        };
    }

    private static string[] GetClinicPermissions(Data.Enums.UserRole role, Data.Models.Enums.ClinicType? clinicType)
    {
        var basePermissions = new List<string>
        {
            // Basic clinic permissions
            "clinic.profile.read", "clinic.profile.write",
            "qr.validate", "patients.read"
        };

        if (role == Data.Enums.UserRole.ClinicOrigin && clinicType == Data.Models.Enums.ClinicType.Origin)
        {
            // Origin clinics can provide services
            basePermissions.AddRange(new[]
            {
                "services.read", "services.write", "services.provide",
                "qr.generate", "credits.manage", "transactions.read"
            });
        }
        else if (role == Data.Enums.UserRole.ClinicPartner && clinicType == Data.Models.Enums.ClinicType.Partner)
        {
            // Partner clinics have limited permissions
            basePermissions.AddRange(new[]
            {
                "services.read", "qr.validate", "patients.validate"
            });
        }

        return basePermissions.ToArray();
    }

    private static string[] GetPatientPermissions()
    {
        return new[]
        {
            // Patient basic permissions
            "profile.read", "profile.write",
            "credits.read", "credits.use",
            "qr.generate", "qr.view",
            "transactions.read", "services.book"
        };
    }

    public async Task<(bool Success, AuthResponseDto? Response, string? Error)> FirebaseLoginAsync(FirebaseLoginDto firebaseLoginDto, string? ipAddress = null)
    {
        try
        {
            // Validate Firebase token and get user info
            var firebaseToken = await _firebaseAuthService.VerifyIdTokenAsync(firebaseLoginDto.FirebaseToken);
            if (firebaseToken == null)
            {
                return (false, null, "Invalid Firebase token");
            }

            // Get email from token claims
            var email = firebaseToken.Claims.ContainsKey("email") ? firebaseToken.Claims["email"].ToString() : null;
            if (string.IsNullOrEmpty(email))
            {
                return (false, null, "Email not found in Firebase token");
            }

            // Check if user exists in our database
            var user = await _userManager.FindByEmailAsync(email);
            bool isNewUser = false;

            if (user == null)
            {
                // Get additional user info from Firebase if creating new user
                var firebaseUser = await _firebaseAuthService.GetUserAsync(firebaseToken.Uid);

                // Create new user from Firebase data
                isNewUser = true;
                user = new ApplicationUser
                {
                    UserName = email,
                    Email = email,
                    FullName = firebaseUser?.DisplayName ?? email.Split('@')[0],
                    Role = Data.Enums.UserRole.Patient, // Default role for Firebase users
                    EmailConfirmed = firebaseUser?.EmailVerified ?? false,
                    CreatedAt = DateTime.UtcNow,
                    LastLoginAt = DateTime.UtcNow,
                    IsActive = true,
                    FirebaseUid = firebaseToken.Uid
                };

                var createResult = await _userManager.CreateAsync(user);
                if (!createResult.Succeeded)
                {
                    var errors = string.Join(", ", createResult.Errors.Select(e => e.Description));
                    _logger.LogWarning("Failed to create user from Firebase: {Email}, Errors: {Errors}", email, errors);
                    return (false, null, $"Failed to create user: {errors}");
                }

                // Add role claim
                var roleClaim = new System.Security.Claims.Claim("role", user.Role.ToString());
                await _userManager.AddClaimAsync(user, roleClaim);
            }
            else
            {
                // Update existing user
                user.LastLoginAt = DateTime.UtcNow;
                if (string.IsNullOrEmpty(user.FirebaseUid))
                {
                    user.FirebaseUid = firebaseToken.Uid;
                }

                // Get additional info from Firebase if needed
                if (!user.EmailConfirmed)
                {
                    var firebaseUser = await _firebaseAuthService.GetUserAsync(firebaseToken.Uid);
                    if (firebaseUser?.EmailVerified == true)
                    {
                        user.EmailConfirmed = true;
                    }
                }

                await _userManager.UpdateAsync(user);
            }

            // Check if user is active
            if (!user.IsActive)
            {
                _logger.LogWarning("Inactive user attempted to login: {Email}", user.Email);
                return (false, null, "Account is inactive");
            }

            // Generate tokens
            var accessToken = _jwtService.GenerateAccessToken(user);
            var refreshToken = _jwtService.GenerateRefreshToken();
            var expiresIn = Convert.ToInt32(_configuration["JWT:AccessTokenExpirationInMinutes"] ?? "120") * 60; // Convert to seconds

            // Create and store refresh token
            var refreshTokenEntity = await _refreshTokenService.CreateRefreshTokenAsync(
                user.Id,
                ipAddress,
                firebaseLoginDto.DeviceInfo,
                Convert.ToInt32(_configuration["JWT:RefreshTokenExpiresInDays"] ?? "7")
            );

            _logger.LogInformation("Firebase login successful for user: {Email}, IsNewUser: {IsNewUser}", user.Email, isNewUser);

            return (true, new AuthResponseDto
            {
                UserId = user.Id,
                Email = user.Email!,
                FullName = user.FullName ?? "",
                Role = user.Role,
                ClinicId = user.ClinicId,
                AccessToken = accessToken,
                RefreshToken = refreshTokenEntity.Token,
                ExpiresIn = expiresIn,
                IsEmailVerified = user.EmailConfirmed,
                IsFirstLogin = isNewUser
            }, null);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during Firebase login");
            return (false, null, "An error occurred during Firebase login");
        }
    }
}