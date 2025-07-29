using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SingleClin.API.Data.Models;

namespace SingleClin.API.Data.Configurations;

public class UserPlanConfiguration : IEntityTypeConfiguration<UserPlan>
{
    public void Configure(EntityTypeBuilder<UserPlan> builder)
    {
        // Primary key
        builder.HasKey(up => up.Id);
        
        // Indexes
        builder.HasIndex(up => new { up.UserId, up.IsActive });
        builder.HasIndex(up => up.ExpirationDate);
        builder.HasIndex(up => up.PaymentTransactionId)
            .IsUnique()
            .HasFilter("payment_transaction_id IS NOT NULL");
            
        // Properties
        builder.Property(up => up.Credits)
            .IsRequired();
            
        builder.Property(up => up.CreditsRemaining)
            .IsRequired();
            
        builder.Property(up => up.AmountPaid)
            .IsRequired()
            .HasPrecision(10, 2);
            
        builder.Property(up => up.ExpirationDate)
            .IsRequired();
            
        builder.Property(up => up.IsActive)
            .IsRequired()
            .HasDefaultValue(true);
            
        builder.Property(up => up.PaymentMethod)
            .HasMaxLength(50);
            
        builder.Property(up => up.PaymentTransactionId)
            .HasMaxLength(255);
            
        builder.Property(up => up.Notes)
            .HasMaxLength(1000);
            
        // Relationships
        builder.HasOne(up => up.User)
            .WithMany(u => u.UserPlans)
            .HasForeignKey(up => up.UserId)
            .OnDelete(DeleteBehavior.Restrict);
            
        builder.HasOne(up => up.Plan)
            .WithMany(p => p.UserPlans)
            .HasForeignKey(up => up.PlanId)
            .OnDelete(DeleteBehavior.Restrict);
            
        builder.HasMany(up => up.Transactions)
            .WithOne(t => t.UserPlan)
            .HasForeignKey(t => t.UserPlanId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}