namespace SingleClin.API.Data.Enums;

/// <summary>
/// User roles in the system
/// </summary>
public enum UserRole
{
    /// <summary>
    /// Patient user who can use credits and generate QR codes
    /// </summary>
    Patient = 0,

    /// <summary>
    /// Origin clinic that provides services and validates QR codes
    /// </summary>
    ClinicOrigin = 1,

    /// <summary>
    /// Partner clinic that can validate QR codes but not provide services
    /// </summary>
    ClinicPartner = 2,

    /// <summary>
    /// System administrator with full access
    /// </summary>
    Administrator = 3
}