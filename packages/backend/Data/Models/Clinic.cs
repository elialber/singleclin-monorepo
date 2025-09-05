using SingleClin.API.Data.Models.Enums;

namespace SingleClin.API.Data.Models;

/// <summary>
/// Represents a clinic in the system
/// </summary>
public class Clinic : BaseEntity
{
    /// <summary>
    /// Clinic name
    /// </summary>
    public string Name { get; set; } = string.Empty;
    
    /// <summary>
    /// Type of clinic
    /// </summary>
    public ClinicType Type { get; set; }
    
    /// <summary>
    /// Clinic address
    /// </summary>
    public string Address { get; set; } = string.Empty;
    
    /// <summary>
    /// Clinic phone number
    /// </summary>
    public string? PhoneNumber { get; set; }
    
    /// <summary>
    /// Clinic email
    /// </summary>
    public string? Email { get; set; }
    
    /// <summary>
    /// Clinic CNPJ (Brazilian company registration)
    /// </summary>
    public string? Cnpj { get; set; }
    
    /// <summary>
    /// Indicates if the clinic is active
    /// </summary>
    public bool IsActive { get; set; } = true;
    
    /// <summary>
    /// Latitude coordinate
    /// </summary>
    public double? Latitude { get; set; }
    
    /// <summary>
    /// Longitude coordinate
    /// </summary>
    public double? Longitude { get; set; }
    
    /// <summary>
    /// URL da imagem/logo da clínica (DEPRECATED - use Images collection)
    /// </summary>
    [Obsolete("Use Images collection instead. Will be removed in future version.")]
    public string? ImageUrl { get; set; }
    
    /// <summary>
    /// Nome do arquivo da imagem no storage (DEPRECATED - use Images collection)
    /// </summary>
    [Obsolete("Use Images collection instead. Will be removed in future version.")]
    public string? ImageFileName { get; set; }
    
    /// <summary>
    /// Tamanho da imagem em bytes (DEPRECATED - use Images collection)
    /// </summary>
    [Obsolete("Use Images collection instead. Will be removed in future version.")]
    public long? ImageSize { get; set; }
    
    /// <summary>
    /// Tipo MIME da imagem (DEPRECATED - use Images collection)
    /// </summary>
    [Obsolete("Use Images collection instead. Will be removed in future version.")]
    public string? ImageContentType { get; set; }
    
    /// <summary>
    /// Collection of images associated with this clinic
    /// </summary>
    public ICollection<ClinicImage> Images { get; set; } = new List<ClinicImage>();
    
    /// <summary>
    /// Transactions processed by this clinic
    /// </summary>
    public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
}