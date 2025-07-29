using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SingleClin.API.Data.Models;

namespace SingleClin.API.Data.Configurations;

public class PlanConfiguration : IEntityTypeConfiguration<Plan>
{
    public void Configure(EntityTypeBuilder<Plan> builder)
    {
        // Primary key
        builder.HasKey(p => p.Id);
        
        // Indexes
        builder.HasIndex(p => p.IsActive);
        builder.HasIndex(p => p.DisplayOrder);
        builder.HasIndex(p => p.IsFeatured);
        
        // Properties
        builder.Property(p => p.Name)
            .IsRequired()
            .HasMaxLength(255);
            
        builder.Property(p => p.Description)
            .HasMaxLength(1000);
            
        builder.Property(p => p.Credits)
            .IsRequired();
            
        builder.Property(p => p.Price)
            .IsRequired()
            .HasPrecision(10, 2);
            
        builder.Property(p => p.OriginalPrice)
            .HasPrecision(10, 2);
            
        builder.Property(p => p.ValidityDays)
            .IsRequired()
            .HasDefaultValue(365);
            
        builder.Property(p => p.IsActive)
            .IsRequired()
            .HasDefaultValue(true);
            
        builder.Property(p => p.DisplayOrder)
            .IsRequired()
            .HasDefaultValue(0);
            
        builder.Property(p => p.IsFeatured)
            .IsRequired()
            .HasDefaultValue(false);
            
        // Relationships
        builder.HasMany(p => p.UserPlans)
            .WithOne(up => up.Plan)
            .HasForeignKey(up => up.PlanId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}