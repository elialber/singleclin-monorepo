using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SingleClin.API.Data.Models;
using SingleClin.API.Data.Models.Enums;

namespace SingleClin.API.Data.Configurations;

public class TransactionConfiguration : IEntityTypeConfiguration<Transaction>
{
    public void Configure(EntityTypeBuilder<Transaction> builder)
    {
        // Primary key
        builder.HasKey(t => t.Id);
        
        // Indexes
        builder.HasIndex(t => t.Code)
            .IsUnique();
            
        builder.HasIndex(t => t.Status);
        builder.HasIndex(t => t.CreatedAt);
        builder.HasIndex(t => new { t.UserPlanId, t.Status });
        builder.HasIndex(t => new { t.ClinicId, t.Status, t.CreatedAt });
        
        // Properties
        builder.Property(t => t.Code)
            .IsRequired()
            .HasMaxLength(50);
            
        builder.Property(t => t.Status)
            .IsRequired()
            .HasConversion<int>()
            .HasDefaultValue(TransactionStatus.Pending);
            
        builder.Property(t => t.CreditsUsed)
            .IsRequired();
            
        builder.Property(t => t.ServiceDescription)
            .IsRequired()
            .HasMaxLength(500);
            
        builder.Property(t => t.ValidatedBy)
            .HasMaxLength(255);
            
        builder.Property(t => t.ValidationNotes)
            .HasMaxLength(1000);
            
        builder.Property(t => t.IpAddress)
            .HasMaxLength(45); // Supports IPv6
            
        builder.Property(t => t.UserAgent)
            .HasMaxLength(500);
            
        builder.Property(t => t.Latitude)
            .HasPrecision(10, 8);
            
        builder.Property(t => t.Longitude)
            .HasPrecision(11, 8);
            
        builder.Property(t => t.CancellationReason)
            .HasMaxLength(500);
            
        // Relationships
        builder.HasOne(t => t.UserPlan)
            .WithMany(up => up.Transactions)
            .HasForeignKey(t => t.UserPlanId)
            .OnDelete(DeleteBehavior.Restrict);
            
        builder.HasOne(t => t.Clinic)
            .WithMany(c => c.Transactions)
            .HasForeignKey(t => t.ClinicId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}