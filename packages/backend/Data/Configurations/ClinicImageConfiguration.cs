using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SingleClin.API.Data.Models;

namespace SingleClin.API.Data.Configurations;

/// <summary>
/// Entity Framework configuration for ClinicImage entity
/// </summary>
public class ClinicImageConfiguration : IEntityTypeConfiguration<ClinicImage>
{
    public void Configure(EntityTypeBuilder<ClinicImage> builder)
    {
        // Note: Table name is auto-converted to snake_case (clinic_images) by ApplicationDbContext
        // Do NOT use builder.ToTable() to avoid overriding the convention

        // Primary key
        builder.HasKey(ci => ci.Id);

        // Properties
        builder.Property(ci => ci.Id)
            .IsRequired()
            .ValueGeneratedOnAdd();

        builder.Property(ci => ci.ClinicId)
            .IsRequired();

        builder.Property(ci => ci.ImageUrl)
            .IsRequired()
            .HasMaxLength(2048);

        builder.Property(ci => ci.FileName)
            .IsRequired()
            .HasMaxLength(500);

        builder.Property(ci => ci.StorageFileName)
            .IsRequired()
            .HasMaxLength(500);

        builder.Property(ci => ci.Size)
            .IsRequired();

        builder.Property(ci => ci.ContentType)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(ci => ci.AltText)
            .HasMaxLength(500);

        builder.Property(ci => ci.Description)
            .HasMaxLength(1000);

        builder.Property(ci => ci.DisplayOrder)
            .IsRequired()
            .HasDefaultValue(0);

        builder.Property(ci => ci.IsFeatured)
            .IsRequired()
            .HasDefaultValue(false);

        builder.Property(ci => ci.CreatedAt)
            .IsRequired()
            .HasDefaultValueSql("CURRENT_TIMESTAMP");

        builder.Property(ci => ci.UpdatedAt)
            .IsRequired()
            .HasDefaultValueSql("CURRENT_TIMESTAMP");

        // Relationships
        builder.HasOne(ci => ci.Clinic)
            .WithMany(c => c.Images)
            .HasForeignKey(ci => ci.ClinicId)
            .OnDelete(DeleteBehavior.Cascade);

        // Indexes
        builder.HasIndex(ci => ci.ClinicId)
            .HasDatabaseName("IX_ClinicImages_ClinicId");

        builder.HasIndex(ci => new { ci.ClinicId, ci.DisplayOrder })
            .HasDatabaseName("IX_ClinicImages_ClinicId_DisplayOrder");

        builder.HasIndex(ci => new { ci.ClinicId, ci.IsFeatured })
            .HasDatabaseName("IX_ClinicImages_ClinicId_IsFeatured")
            .HasFilter("is_featured = true");

        builder.HasIndex(ci => ci.StorageFileName)
            .HasDatabaseName("IX_ClinicImages_StorageFileName")
            .IsUnique();
    }
}