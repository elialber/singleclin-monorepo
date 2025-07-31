using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.User;

/// <summary>
/// DTO for toggling user status
/// </summary>
public class ToggleStatusDto
{
    /// <summary>
    /// New active status
    /// </summary>
    [Required]
    public bool IsActive { get; set; }
}