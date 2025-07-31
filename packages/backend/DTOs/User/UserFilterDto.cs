namespace SingleClin.API.DTOs.User;

/// <summary>
/// DTO for filtering users
/// </summary>
public class UserFilterDto
{
    /// <summary>
    /// Search term (searches in name, email, phone)
    /// </summary>
    public string? Search { get; set; }

    /// <summary>
    /// Filter by role
    /// </summary>
    public string? Role { get; set; }

    /// <summary>
    /// Filter by active status
    /// </summary>
    public bool? IsActive { get; set; }

    /// <summary>
    /// Filter by email verification status
    /// </summary>
    public bool? IsEmailVerified { get; set; }

    /// <summary>
    /// Filter by clinic ID
    /// </summary>
    public Guid? ClinicId { get; set; }

    /// <summary>
    /// Filter by creation date (after)
    /// </summary>
    public DateTime? CreatedAfter { get; set; }

    /// <summary>
    /// Filter by creation date (before)
    /// </summary>
    public DateTime? CreatedBefore { get; set; }

    /// <summary>
    /// Sort by field
    /// </summary>
    public string SortBy { get; set; } = "fullName";

    /// <summary>
    /// Sort order
    /// </summary>
    public string SortOrder { get; set; } = "asc";

    /// <summary>
    /// Page number (1-based)
    /// </summary>
    public int Page { get; set; } = 1;

    /// <summary>
    /// Items per page
    /// </summary>
    public int Limit { get; set; } = 10;
}