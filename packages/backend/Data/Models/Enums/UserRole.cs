namespace SingleClin.API.Data.Models.Enums;

/// <summary>
/// User roles in the system
/// </summary>
public enum UserRole
{
    /// <summary>
    /// Patient user - can purchase and use plans
    /// </summary>
    Patient = 0,

    /// <summary>
    /// Clinic user - can validate QR codes
    /// </summary>
    Clinic = 1,

    /// <summary>
    /// Clinic origin - special clinic type
    /// </summary>
    ClinicOrigin = 2,

    /// <summary>
    /// Clinic partner - partner clinic type
    /// </summary>
    ClinicPartner = 3,

    /// <summary>
    /// System administrator
    /// </summary>
    Admin = 4
}