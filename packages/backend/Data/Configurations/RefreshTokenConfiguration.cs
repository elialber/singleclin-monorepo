using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SingleClin.API.Data.Models;

namespace SingleClin.API.Data.Configurations;

/// <summary>
/// Entity configuration for RefreshToken
/// </summary>
public class RefreshTokenConfiguration : IEntityTypeConfiguration<RefreshToken>
{
    public void Configure(EntityTypeBuilder<RefreshToken> builder)
    {
        // Configure table name
        builder.ToTable("refresh_tokens");

        // Configure Token
        builder.Property(e => e.Token)
            .HasMaxLength(500)
            .IsRequired();

        // Configure DeviceInfo
        builder.Property(e => e.DeviceInfo)
            .HasMaxLength(500);

        // Configure IpAddress
        builder.Property(e => e.IpAddress)
            .HasMaxLength(45); // Supports IPv6

        // Configure indexes
        builder.HasIndex(e => e.Token)
            .IsUnique();

        builder.HasIndex(e => e.UserId);
        builder.HasIndex(e => e.ExpiresAt);
        builder.HasIndex(e => new { e.UserId, e.IsRevoked });

        // Configure computed property to be ignored
        builder.Ignore(e => e.IsActive);
    }
}