namespace SingleClin.API.Data.Models.Enums;

/// <summary>
/// Types of clinics in the system
/// </summary>
public enum ClinicType
{
    /// <summary>
    /// Regular clinic
    /// </summary>
    Regular = 0,
    
    /// <summary>
    /// Origin clinic - provides services
    /// </summary>
    Origin = 1,
    
    /// <summary>
    /// Partner clinic - has special agreements
    /// </summary>
    Partner = 2,
    
    /// <summary>
    /// Administrative clinic
    /// </summary>
    Administrative = 3
}