using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SingleClin.API.Data.Models;

namespace SingleClin.API.Data.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        // Table name is handled by AppDbContext convention
        
        // Primary key
        builder.HasKey(u => u.Id);
        
        // Indexes
        builder.HasIndex(u => u.Email)
            .IsUnique();
            
        builder.HasIndex(u => u.FirebaseUid)
            .IsUnique()
            .HasFilter("firebase_uid IS NOT NULL");
            
        // Properties
        builder.Property(u => u.Email)
            .IsRequired()
            .HasMaxLength(255);
            
        builder.Property(u => u.DisplayName)
            .HasMaxLength(255);
            
        builder.Property(u => u.PhoneNumber)
            .HasMaxLength(20);
            
        builder.Property(u => u.FirebaseUid)
            .HasMaxLength(128);
            
        builder.Property(u => u.Role)
            .IsRequired()
            .HasConversion<int>();
            
        // Relationships
        builder.HasMany(u => u.UserPlans)
            .WithOne(up => up.User)
            .HasForeignKey(up => up.UserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}