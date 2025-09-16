namespace SingleClin.API.Data.Models;

/// <summary>
/// Base interface for all entities in the system
/// </summary>
public interface IEntity
{
    /// <summary>
    /// Unique identifier for the entity
    /// </summary>
    Guid Id { get; set; }

    /// <summary>
    /// Date and time when the entity was created
    /// </summary>
    DateTime CreatedAt { get; set; }

    /// <summary>
    /// Date and time when the entity was last updated
    /// </summary>
    DateTime UpdatedAt { get; set; }
}