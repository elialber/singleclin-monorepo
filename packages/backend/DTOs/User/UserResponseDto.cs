namespace SingleClin.API.DTOs.User;

/// <summary>
/// User response DTO
/// </summary>
public class UserResponseDto
{
    /// <summary>
    /// User ID
    /// </summary>
    public string Id { get; set; } = string.Empty;

    /// <summary>
    /// User email
    /// </summary>
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// User first name
    /// </summary>
    public string FirstName { get; set; } = string.Empty;

    /// <summary>
    /// User last name
    /// </summary>
    public string LastName { get; set; } = string.Empty;

    /// <summary>
    /// User full name
    /// </summary>
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// User role
    /// </summary>
    public string Role { get; set; } = string.Empty;

    /// <summary>
    /// Whether the user is active
    /// </summary>
    public bool IsActive { get; set; }

    /// <summary>
    /// Whether the user's email is verified
    /// </summary>
    public bool IsEmailVerified { get; set; }

    /// <summary>
    /// User phone number
    /// </summary>
    public string? PhoneNumber { get; set; }

    /// <summary>
    /// Associated clinic ID (for clinic users)
    /// </summary>
    public string? ClinicId { get; set; }

    /// <summary>
    /// When the user was created
    /// </summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// When the user was last updated
    /// </summary>
    public DateTime UpdatedAt { get; set; }
}