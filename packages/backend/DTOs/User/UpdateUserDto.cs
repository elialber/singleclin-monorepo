using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.User;

/// <summary>
/// DTO for updating user information
/// </summary>
public class UpdateUserDto
{
    /// <summary>
    /// User first name
    /// </summary>
    [MinLength(2)]
    public string? FirstName { get; set; }

    /// <summary>
    /// User last name
    /// </summary>
    [MinLength(2)]
    public string? LastName { get; set; }

    /// <summary>
    /// User full name (alternative to FirstName + LastName)
    /// </summary>
    [MinLength(2)]
    public string? FullName { get; set; }

    /// <summary>
    /// User email address
    /// </summary>
    [EmailAddress]
    public string? Email { get; set; }

    /// <summary>
    /// User phone number
    /// </summary>
    [Phone]
    public string? PhoneNumber { get; set; }

    /// <summary>
    /// Whether the user is active
    /// </summary>
    public bool? IsActive { get; set; }

    /// <summary>
    /// User role (only administrators can change)
    /// </summary>
    public string? Role { get; set; }

    /// <summary>
    /// Associated clinic ID
    /// </summary>
    public Guid? ClinicId { get; set; }
}