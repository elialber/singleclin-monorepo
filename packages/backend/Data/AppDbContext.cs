using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using SingleClin.API.Data.Models;
using System.Linq.Expressions;

namespace SingleClin.API.Data;

/// <summary>
/// Main database context for the SingleClin application
/// </summary>
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    /// <summary>
    /// Users in the system (separate from ApplicationUser Identity)
    /// </summary>
    public DbSet<User> Users => Set<User>();
    
    /// <summary>
    /// Available plans for purchase
    /// </summary>
    public DbSet<Plan> Plans => Set<Plan>();
    
    /// <summary>
    /// User purchased plans
    /// </summary>
    public DbSet<UserPlan> UserPlans => Set<UserPlan>();
    
    /// <summary>
    /// Transactions (credit usage)
    /// </summary>
    public DbSet<Transaction> Transactions => Set<Transaction>();
    

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Apply snake_case naming convention
        foreach (var entity in modelBuilder.Model.GetEntityTypes())
        {
            // Convert table names to snake_case
            entity.SetTableName(ToSnakeCase(entity.GetTableName()));

            // Convert column names to snake_case
            foreach (var property in entity.GetProperties())
            {
                property.SetColumnName(ToSnakeCase(property.GetColumnName()));
            }

            // Convert key names to snake_case
            foreach (var key in entity.GetKeys())
            {
                key.SetName(ToSnakeCase(key.GetName()));
            }

            // Convert foreign key names to snake_case
            foreach (var key in entity.GetForeignKeys())
            {
                key.SetConstraintName(ToSnakeCase(key.GetConstraintName()));
            }

            // Convert index names to snake_case
            foreach (var index in entity.GetIndexes())
            {
                index.SetDatabaseName(ToSnakeCase(index.GetDatabaseName()));
            }
        }

        // Apply specific configurations only for AppDbContext entities
        // NOTE: We explicitly avoid ApplicationUser configurations to prevent conflicts
        // with ApplicationDbContext which handles Identity entities
    }

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        OnBeforeSaving();
        return await base.SaveChangesAsync(cancellationToken);
    }

    public override int SaveChanges()
    {
        OnBeforeSaving();
        return base.SaveChanges();
    }

    private void OnBeforeSaving()
    {
        var entries = ChangeTracker.Entries<IEntity>();
        var utcNow = DateTime.UtcNow;

        foreach (var entry in entries)
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    entry.Entity.CreatedAt = utcNow;
                    entry.Entity.UpdatedAt = utcNow;
                    break;

                case EntityState.Modified:
                    entry.Entity.UpdatedAt = utcNow;
                    // Ensure CreatedAt is not modified
                    entry.Property(nameof(IEntity.CreatedAt)).IsModified = false;
                    break;
            }
        }
    }

    private static string ToSnakeCase(string input)
    {
        if (string.IsNullOrEmpty(input))
            return input;

        var startUnderscores = System.Text.RegularExpressions.Regex.Match(input, @"^_+");
        return startUnderscores + System.Text.RegularExpressions.Regex.Replace(input, @"([a-z0-9])([A-Z])", "$1_$2").ToLower();
    }
}