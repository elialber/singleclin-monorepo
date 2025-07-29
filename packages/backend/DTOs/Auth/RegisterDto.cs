using System.ComponentModel.DataAnnotations;
using SingleClin.API.Data.Enums;

namespace SingleClin.API.DTOs.Auth;

/// <summary>
/// Data transfer object for user registration
/// </summary>
public class RegisterDto
{
    /// <summary>
    /// User's email address
    /// </summary>
    [Required(ErrorMessage = "Email is required")]
    [EmailAddress(ErrorMessage = "Invalid email format")]
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// User's password
    /// </summary>
    [Required(ErrorMessage = "Password is required")]
    [MinLength(8, ErrorMessage = "Password must be at least 8 characters long")]
    [RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$",
        ErrorMessage = "Password must contain at least one uppercase letter, one lowercase letter, one number and one special character")]
    public string Password { get; set; } = string.Empty;

    /// <summary>
    /// Confirm password
    /// </summary>
    [Required(ErrorMessage = "Password confirmation is required")]
    [Compare(nameof(Password), ErrorMessage = "Passwords do not match")]
    public string ConfirmPassword { get; set; } = string.Empty;

    /// <summary>
    /// User's full name
    /// </summary>
    [Required(ErrorMessage = "Full name is required")]
    [MinLength(3, ErrorMessage = "Full name must be at least 3 characters long")]
    [MaxLength(200, ErrorMessage = "Full name cannot exceed 200 characters")]
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// User's role in the system
    /// </summary>
    [Required(ErrorMessage = "Role is required")]
    public UserRole Role { get; set; } = UserRole.Patient;

    /// <summary>
    /// Clinic name (required for clinic users)
    /// </summary>
    [MaxLength(200, ErrorMessage = "Clinic name cannot exceed 200 characters")]
    public string? ClinicName { get; set; }

    /// <summary>
    /// Validates if clinic name is required based on role
    /// </summary>
    public bool IsValid()
    {
        if ((Role == UserRole.ClinicOrigin || Role == UserRole.ClinicPartner) && string.IsNullOrWhiteSpace(ClinicName))
        {
            return false;
        }
        return true;
    }
}