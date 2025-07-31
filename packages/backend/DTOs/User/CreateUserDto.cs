using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.User;

/// <summary>
/// DTO for creating a new user
/// </summary>
public class CreateUserDto
{
    /// <summary>
    /// User email
    /// </summary>
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// User first name
    /// </summary>
    [Required]
    [MinLength(2)]
    public string FirstName { get; set; } = string.Empty;

    /// <summary>
    /// User last name
    /// </summary>
    [Required]
    [MinLength(2)]
    public string LastName { get; set; } = string.Empty;

    /// <summary>
    /// User role
    /// </summary>
    [Required]
    public string Role { get; set; } = string.Empty;

    /// <summary>
    /// User phone number
    /// </summary>
    [Phone]
    public string? PhoneNumber { get; set; }

    /// <summary>
    /// Associated clinic ID (for clinic users)
    /// </summary>
    public Guid? ClinicId { get; set; }

    /// <summary>
    /// User password
    /// </summary>
    [Required]
    [MinLength(6)]
    public string Password { get; set; } = string.Empty;
}