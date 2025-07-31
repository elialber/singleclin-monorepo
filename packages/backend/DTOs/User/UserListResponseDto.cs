namespace SingleClin.API.DTOs.User;

/// <summary>
/// Response DTO for user list endpoint to match frontend expectations
/// </summary>
public class UserListResponseDto
{
    /// <summary>
    /// List of users
    /// </summary>
    public List<UserResponseDto> Data { get; set; } = new();

    /// <summary>
    /// Total number of users
    /// </summary>
    public int Total { get; set; }

    /// <summary>
    /// Current page number
    /// </summary>
    public int Page { get; set; }

    /// <summary>
    /// Items per page
    /// </summary>
    public int Limit { get; set; }
}