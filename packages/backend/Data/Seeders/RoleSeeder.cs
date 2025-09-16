using Microsoft.AspNetCore.Identity;
using SingleClin.API.Data.Models;
using SingleClin.API.Data.Enums;

namespace SingleClin.API.Data.Seeders;

/// <summary>
/// Seeder for creating default roles in the system
/// </summary>
public static class RoleSeeder
{
    /// <summary>
    /// Seeds the default roles into the database
    /// </summary>
    public static async Task SeedRolesAsync(IServiceProvider serviceProvider)
    {
        var roleManager = serviceProvider.GetRequiredService<RoleManager<IdentityRole<Guid>>>();
        var logger = serviceProvider.GetRequiredService<ILogger<Program>>();

        var roles = new[]
        {
            new { Name = UserRole.Patient.ToString(), Description = "Patient user who can use credits and generate QR codes" },
            new { Name = UserRole.ClinicOrigin.ToString(), Description = "Origin clinic that provides services and validates QR codes" },
            new { Name = UserRole.ClinicPartner.ToString(), Description = "Partner clinic that can validate QR codes but not provide services" },
            new { Name = UserRole.Administrator.ToString(), Description = "System administrator with full access" }
        };

        foreach (var roleInfo in roles)
        {
            var roleExists = await roleManager.RoleExistsAsync(roleInfo.Name);
            if (!roleExists)
            {
                var role = new IdentityRole<Guid>
                {
                    Name = roleInfo.Name,
                    NormalizedName = roleInfo.Name.ToUpper()
                };

                var result = await roleManager.CreateAsync(role);
                if (result.Succeeded)
                {
                    logger.LogInformation("Created role: {RoleName}", roleInfo.Name);
                }
                else
                {
                    logger.LogError("Failed to create role: {RoleName}. Errors: {Errors}",
                        roleInfo.Name, string.Join(", ", result.Errors.Select(e => e.Description)));
                }
            }
            else
            {
                logger.LogDebug("Role already exists: {RoleName}", roleInfo.Name);
            }
        }
    }

    /// <summary>
    /// Seeds default admin user if it doesn't exist
    /// </summary>
    public static async Task SeedDefaultAdminAsync(IServiceProvider serviceProvider)
    {
        var userManager = serviceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var configuration = serviceProvider.GetRequiredService<IConfiguration>();
        var logger = serviceProvider.GetRequiredService<ILogger<Program>>();

        var adminEmail = configuration["DefaultAdmin:Email"];
        var adminPassword = configuration["DefaultAdmin:Password"];

        if (string.IsNullOrEmpty(adminEmail) || string.IsNullOrEmpty(adminPassword))
        {
            logger.LogWarning("Default admin credentials not configured. Skipping admin seeding.");
            return;
        }

        var existingAdmin = await userManager.FindByEmailAsync(adminEmail);
        if (existingAdmin == null)
        {
            var adminUser = new ApplicationUser
            {
                UserName = adminEmail,
                Email = adminEmail,
                FullName = "System Administrator",
                Role = UserRole.Administrator,
                EmailConfirmed = true,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            var result = await userManager.CreateAsync(adminUser, adminPassword);
            if (result.Succeeded)
            {
                // Add role claim
                await userManager.AddClaimAsync(adminUser, new System.Security.Claims.Claim("role", UserRole.Administrator.ToString()));

                // Add admin permissions claim
                var permissions = new[]
                {
                    "users.read", "users.write", "users.delete",
                    "clinics.read", "clinics.write", "clinics.delete",
                    "patients.read", "patients.write", "patients.delete",
                    "system.configure", "system.monitor", "system.backup"
                };

                await userManager.AddClaimAsync(adminUser, new System.Security.Claims.Claim("permissions", string.Join(",", permissions)));

                logger.LogInformation("Created default admin user: {Email}", adminEmail);
            }
            else
            {
                logger.LogError("Failed to create default admin user. Errors: {Errors}",
                    string.Join(", ", result.Errors.Select(e => e.Description)));
            }
        }
        else
        {
            logger.LogDebug("Default admin user already exists: {Email}", adminEmail);
        }
    }
}