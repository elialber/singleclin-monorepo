using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SingleClin.API.Data.Models;

namespace SingleClin.API.Data.Configurations;

/// <summary>
/// Base configuration for entities that implement IEntity
/// </summary>
public abstract class BaseEntityConfiguration<TEntity> : IEntityTypeConfiguration<TEntity>
    where TEntity : class, IEntity
{
    public virtual void Configure(EntityTypeBuilder<TEntity> builder)
    {
        // Configure primary key
        builder.HasKey(e => e.Id);

        // Configure Id property
        builder.Property(e => e.Id)
            .ValueGeneratedOnAdd()
            .IsRequired();

        // Configure timestamps
        builder.Property(e => e.CreatedAt)
            .IsRequired()
            .HasDefaultValueSql("CURRENT_TIMESTAMP");

        builder.Property(e => e.UpdatedAt)
            .IsRequired()
            .HasDefaultValueSql("CURRENT_TIMESTAMP");

        // Create index on CreatedAt for performance
        builder.HasIndex(e => e.CreatedAt)
            .HasDatabaseName($"idx_{typeof(TEntity).Name.ToLower()}_created_at");

        // Apply additional configurations from derived classes
        ConfigureEntity(builder);
    }

    /// <summary>
    /// Override this method to add entity-specific configurations
    /// </summary>
    protected abstract void ConfigureEntity(EntityTypeBuilder<TEntity> builder);
}