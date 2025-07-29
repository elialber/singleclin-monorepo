using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SingleClin.API.Data.Models;

namespace SingleClin.API.Data.Configurations;

/// <summary>
/// Entity configuration for ApplicationUser
/// </summary>
public class ApplicationUserConfiguration : IEntityTypeConfiguration<ApplicationUser>
{
    public void Configure(EntityTypeBuilder<ApplicationUser> builder)
    {
        // Configure the Role enum to be stored as a string
        builder.Property(e => e.Role)
            .HasConversion<string>()
            .HasMaxLength(50)
            .IsRequired();

        // Configure FullName
        builder.Property(e => e.FullName)
            .HasMaxLength(200)
            .IsRequired();

        // Configure ClinicId
        builder.Property(e => e.ClinicId)
            .IsRequired(false);

        // Configure relationships
        builder.HasOne(e => e.Clinic)
            .WithMany()
            .HasForeignKey(e => e.ClinicId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasMany(e => e.RefreshTokens)
            .WithOne(e => e.User)
            .HasForeignKey(e => e.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Add indexes
        builder.HasIndex(e => e.Email)
            .IsUnique();

        builder.HasIndex(e => e.Role);
        builder.HasIndex(e => e.ClinicId);
        builder.HasIndex(e => new { e.Role, e.ClinicId });
    }
}