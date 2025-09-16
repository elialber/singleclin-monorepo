using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace SingleClin.API.Data.Interceptors;

/// <summary>
/// Interceptor for logging database operations in development
/// </summary>
public class AuditingInterceptor : SaveChangesInterceptor
{
    private readonly ILogger<AuditingInterceptor> _logger;

    public AuditingInterceptor(ILogger<AuditingInterceptor> logger)
    {
        _logger = logger;
    }

    public override InterceptionResult<int> SavingChanges(
        DbContextEventData eventData,
        InterceptionResult<int> result)
    {
        if (eventData.Context != null)
        {
            LogChanges(eventData.Context);
        }

        return base.SavingChanges(eventData, result);
    }

    public override async ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData,
        InterceptionResult<int> result,
        CancellationToken cancellationToken = default)
    {
        if (eventData.Context != null)
        {
            LogChanges(eventData.Context);
        }

        return await base.SavingChangesAsync(eventData, result, cancellationToken);
    }

    private void LogChanges(DbContext context)
    {
        var entries = context.ChangeTracker.Entries()
            .Where(e => e.State == EntityState.Added ||
                       e.State == EntityState.Modified ||
                       e.State == EntityState.Deleted)
            .ToList();

        foreach (var entry in entries)
        {
            var entityName = entry.Metadata.ClrType.Name;
            var state = entry.State.ToString();

            _logger.LogInformation(
                "Entity {EntityName} was {State}. Key: {Key}",
                entityName,
                state,
                GetPrimaryKeyValue(entry));

            // Log property changes for modified entities
            if (entry.State == EntityState.Modified)
            {
                var modifiedProperties = entry.Properties
                    .Where(p => p.IsModified)
                    .Select(p => new { p.Metadata.Name, p.OriginalValue, p.CurrentValue })
                    .ToList();

                foreach (var prop in modifiedProperties)
                {
                    _logger.LogDebug(
                        "Property {PropertyName} changed from {OriginalValue} to {CurrentValue}",
                        prop.Name,
                        prop.OriginalValue,
                        prop.CurrentValue);
                }
            }
        }
    }

    private static object GetPrimaryKeyValue(EntityEntry entry)
    {
        var keyProperties = entry.Metadata.FindPrimaryKey()?.Properties;
        if (keyProperties == null || !keyProperties.Any())
            return "Unknown";

        var keyValues = keyProperties
            .Select(p => entry.Property(p.Name).CurrentValue)
            .ToArray();

        return keyValues.Length == 1 ? keyValues[0] : string.Join(", ", keyValues);
    }
}