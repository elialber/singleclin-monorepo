using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SingleClin.API.Data.Models;

namespace SingleClin.API.Data.Configurations;

public class ClinicConfiguration : IEntityTypeConfiguration<Clinic>
{
    public void Configure(EntityTypeBuilder<Clinic> builder)
    {
        // Primary key
        builder.HasKey(c => c.Id);
        
        // Indexes
        builder.HasIndex(c => c.Cnpj)
            .IsUnique()
            .HasFilter("cnpj IS NOT NULL");
            
        builder.HasIndex(c => c.IsActive);
        
        builder.HasIndex(c => new { c.Latitude, c.Longitude })
            .HasFilter("latitude IS NOT NULL AND longitude IS NOT NULL");
            
        // Properties
        builder.Property(c => c.Name)
            .IsRequired()
            .HasMaxLength(255);
            
        builder.Property(c => c.Type)
            .IsRequired()
            .HasConversion<int>();
            
        builder.Property(c => c.Address)
            .IsRequired()
            .HasMaxLength(500);
            
        builder.Property(c => c.PhoneNumber)
            .HasMaxLength(20);
            
        builder.Property(c => c.Email)
            .HasMaxLength(255);
            
        builder.Property(c => c.Cnpj)
            .HasMaxLength(18); // Format: 00.000.000/0000-00
            
        builder.Property(c => c.Latitude)
            .HasPrecision(10, 8);
            
        builder.Property(c => c.Longitude)
            .HasPrecision(11, 8);
            
        // Relationships
        builder.HasMany(c => c.Transactions)
            .WithOne(t => t.Clinic)
            .HasForeignKey(t => t.ClinicId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}