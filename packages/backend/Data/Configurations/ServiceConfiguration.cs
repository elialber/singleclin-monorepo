using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SingleClin.API.Data.Models;

namespace SingleClin.API.Data.Configurations;

public class ServiceConfiguration : IEntityTypeConfiguration<Service>
{
    public void Configure(EntityTypeBuilder<Service> builder)
    {
        // Table name
        builder.ToTable("services");

        // Primary key
        builder.HasKey(cs => cs.Id);

        // Properties
        builder.Property(cs => cs.Name)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(cs => cs.Description)
            .HasMaxLength(500);

        builder.Property(cs => cs.Price)
            .IsRequired()
            .HasColumnType("decimal(18,2)");

        builder.Property(cs => cs.Duration)
            .IsRequired();

        builder.Property(cs => cs.Category)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(cs => cs.IsActive)
            .IsRequired()
            .HasDefaultValue(true);

        builder.Property(cs => cs.ImageUrl)
            .HasMaxLength(500);

        // Foreign key relationship with Clinic
        builder.HasOne(cs => cs.Clinic)
            .WithMany(c => c.Services)
            .HasForeignKey(cs => cs.ClinicId)
            .OnDelete(DeleteBehavior.Cascade);

        // Indexes
        builder.HasIndex(cs => cs.ClinicId)
            .HasDatabaseName("ix_services_clinic_id");

        builder.HasIndex(cs => cs.Category)
            .HasDatabaseName("ix_services_category");

        builder.HasIndex(cs => cs.IsActive)
            .HasDatabaseName("ix_services_is_active");
    }
}