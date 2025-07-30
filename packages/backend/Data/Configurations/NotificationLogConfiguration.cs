using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SingleClin.API.Data.Models;
using System.Text.Json;

namespace SingleClin.API.Data.Configurations
{
    public class NotificationLogConfiguration : IEntityTypeConfiguration<NotificationLog>
    {
        public void Configure(EntityTypeBuilder<NotificationLog> builder)
        {
            builder.ToTable("notification_logs");

            builder.HasKey(n => n.Id);

            builder.Property(n => n.Type)
                .IsRequired()
                .HasMaxLength(50);

            builder.Property(n => n.Channel)
                .IsRequired()
                .HasMaxLength(50);

            builder.Property(n => n.Subject)
                .IsRequired()
                .HasMaxLength(200);

            builder.Property(n => n.Message)
                .IsRequired()
                .HasMaxLength(1000);

            builder.Property(n => n.Recipient)
                .IsRequired()
                .HasMaxLength(200);

            builder.Property(n => n.ErrorMessage)
                .HasMaxLength(500);

            builder.Property(n => n.ExternalMessageId)
                .HasMaxLength(100);

            // Configure the Metadata property as JSON
            builder.Property(n => n.Metadata)
                .HasConversion(
                    v => v == null ? null : JsonSerializer.Serialize(v, (JsonSerializerOptions?)null),
                    v => v == null ? null : JsonSerializer.Deserialize<Dictionary<string, object>>(v, (JsonSerializerOptions?)null))
                .HasColumnType("jsonb");

            // Configure the relationship with ApplicationUser
            builder.HasOne(n => n.User)
                .WithMany()
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            // Create index on UserId and Type for faster queries
            builder.HasIndex(n => new { n.UserId, n.Type })
                .HasDatabaseName("IX_notification_logs_user_type");

            // Create index on SentAt for time-based queries
            builder.HasIndex(n => n.SentAt)
                .HasDatabaseName("IX_notification_logs_sent_at");
        }
    }
}