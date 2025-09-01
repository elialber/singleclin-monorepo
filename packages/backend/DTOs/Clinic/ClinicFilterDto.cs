using System.ComponentModel.DataAnnotations;
using SingleClin.API.Data.Models.Enums;

namespace SingleClin.API.DTOs.Clinic;

/// <summary>
/// Data transfer object for filtering clinics
/// </summary>
public class ClinicFilterDto
{
    /// <summary>
    /// Page number (1-based)
    /// </summary>
    [Range(1, int.MaxValue, ErrorMessage = "Page number must be greater than 0")]
    public int PageNumber { get; set; } = 1;

    /// <summary>
    /// Number of items per page
    /// </summary>
    [Range(1, 100, ErrorMessage = "Page size must be between 1 and 100")]
    public int PageSize { get; set; } = 10;

    /// <summary>
    /// Filter by active status
    /// </summary>
    public bool? IsActive { get; set; }

    /// <summary>
    /// Filter by clinic type
    /// </summary>
    public ClinicType? Type { get; set; }

    /// <summary>
    /// Search term for name or address
    /// </summary>
    [StringLength(100, ErrorMessage = "Search term cannot exceed 100 characters")]
    public string? SearchTerm { get; set; }

    /// <summary>
    /// Filter by city (part of address)
    /// </summary>
    [StringLength(100, ErrorMessage = "City filter cannot exceed 100 characters")]
    public string? City { get; set; }

    /// <summary>
    /// Filter by state (part of address)
    /// </summary>
    [StringLength(2, ErrorMessage = "State filter must be 2 characters")]
    public string? State { get; set; }

    /// <summary>
    /// Sort field
    /// </summary>
    public string SortBy { get; set; } = "Name";

    /// <summary>
    /// Sort direction (asc or desc)
    /// </summary>
    public string SortDirection { get; set; } = "asc";
}