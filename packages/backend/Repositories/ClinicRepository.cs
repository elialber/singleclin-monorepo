using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Data.Models;
using SingleClin.API.Data.Models.Enums;

namespace SingleClin.API.Repositories;

/// <summary>
/// Repository implementation for Clinic entity operations
/// </summary>
public class ClinicRepository : IClinicRepository
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<ClinicRepository> _logger;

    public ClinicRepository(ApplicationDbContext context, ILogger<ClinicRepository> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<(IEnumerable<Clinic> Clinics, int TotalCount)> GetAllAsync(
        int pageNumber = 1,
        int pageSize = 10,
        bool? isActive = null,
        ClinicType? type = null,
        string? searchTerm = null,
        string? city = null,
        string? state = null,
        string sortBy = "Name",
        string sortDirection = "asc")
    {
        var query = _context.Clinics.AsQueryable();

        // Apply filters
        if (isActive.HasValue)
        {
            query = query.Where(c => c.IsActive == isActive.Value);
        }

        if (type.HasValue)
        {
            query = query.Where(c => c.Type == type.Value);
        }

        if (!string.IsNullOrWhiteSpace(searchTerm))
        {
            query = query.Where(c => EF.Functions.ILike(c.Name, $"%{searchTerm}%") ||
                                   EF.Functions.ILike(c.Address, $"%{searchTerm}%"));
        }

        if (!string.IsNullOrWhiteSpace(city))
        {
            query = query.Where(c => EF.Functions.ILike(c.Address, $"%{city}%"));
        }

        if (!string.IsNullOrWhiteSpace(state))
        {
            query = query.Where(c => EF.Functions.ILike(c.Address, $"%{state}%"));
        }

        // Get total count for pagination
        int totalCount = await query.CountAsync();

        // Apply dynamic sorting
        query = ApplySorting(query, sortBy, sortDirection);

        // Apply pagination
        var clinics = await query
            .Include(c => c.Images.OrderBy(i => i.DisplayOrder))
            .Include(c => c.Services)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .AsNoTracking()
            .ToListAsync();

        _logger.LogDebug("Retrieved {Count} clinics from database with filters: Active={IsActive}, Type={Type}, Search={SearchTerm}, City={City}, State={State}, SortBy={SortBy}, SortDirection={SortDirection}",
            clinics.Count, isActive, type, searchTerm, city, state, sortBy, sortDirection);

        return (clinics, totalCount);
    }

    public async Task<Clinic?> GetByIdAsync(Guid id)
    {
        var clinic = await _context.Clinics
            .Include(c => c.Transactions)
            .Include(c => c.Images.OrderBy(i => i.DisplayOrder))
            .Include(c => c.Services)
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == id);

        if (clinic == null)
        {
            _logger.LogDebug("Clinic not found with ID: {ClinicId}", id);
        }

        return clinic;
    }

    public async Task<Clinic?> GetByNameAsync(string name)
    {
        var clinic = await _context.Clinics
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Name == name);

        return clinic;
    }

    public async Task<Clinic?> GetByCnpjAsync(string cnpj)
    {
        var clinic = await _context.Clinics
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Cnpj == cnpj);

        return clinic;
    }

    public async Task<IEnumerable<Clinic>> GetActiveAsync()
    {
        try
        {
            // Try to load with services first
            var clinics = await _context.Clinics
                .Include(c => c.Images.OrderBy(i => i.DisplayOrder))
                .Include(c => c.Services)
                .Where(c => c.IsActive)
                .OrderBy(c => c.Name)
                .AsNoTracking()
                .ToListAsync();

            _logger.LogDebug("Retrieved {Count} active clinics with services", clinics.Count);
            return clinics;
        }
        catch (Exception ex)
        {
            // If services include fails (likely due to missing credit_cost column), load without services
            _logger.LogWarning(ex, "Failed to load clinics with services, loading basic clinic data only");

            var clinics = await _context.Clinics
                .Include(c => c.Images.OrderBy(i => i.DisplayOrder))
                .Where(c => c.IsActive)
                .OrderBy(c => c.Name)
                .AsNoTracking()
                .ToListAsync();

            _logger.LogDebug("Retrieved {Count} active clinics without services", clinics.Count);
            return clinics;
        }
    }

    public async Task<Clinic> CreateAsync(Clinic clinic)
    {
        clinic.CreatedAt = DateTime.UtcNow;
        clinic.UpdatedAt = DateTime.UtcNow;

        _context.Clinics.Add(clinic);
        await _context.SaveChangesAsync();

        _logger.LogInformation("Created new clinic: {ClinicName} with ID: {ClinicId}", clinic.Name, clinic.Id);

        return clinic;
    }

    public async Task<Clinic> UpdateAsync(Clinic clinic)
    {
        var existingClinic = await _context.Clinics
            .Include(c => c.Services)
            .FirstOrDefaultAsync(c => c.Id == clinic.Id);
        if (existingClinic == null)
        {
            throw new InvalidOperationException($"Clinic with ID {clinic.Id} not found for update");
        }

        // Update fields
        existingClinic.Name = clinic.Name;
        existingClinic.Type = clinic.Type;
        existingClinic.Address = clinic.Address;
        existingClinic.PhoneNumber = clinic.PhoneNumber;
        existingClinic.Email = clinic.Email;
        existingClinic.Cnpj = clinic.Cnpj;
        existingClinic.IsActive = clinic.IsActive;
        existingClinic.Latitude = clinic.Latitude;
        existingClinic.Longitude = clinic.Longitude;
        existingClinic.UpdatedAt = DateTime.UtcNow;

        // Update services
        if (existingClinic.Services != null)
        {
            // Remove existing services
            _context.ClinicServices.RemoveRange(existingClinic.Services);
        }

        // Add new services
        if (clinic.Services != null && clinic.Services.Any())
        {
            foreach (var service in clinic.Services)
            {
                service.ClinicId = clinic.Id;
                _context.ClinicServices.Add(service);
            }
        }

        await _context.SaveChangesAsync();

        _logger.LogInformation("Updated clinic: {ClinicName} with ID: {ClinicId}", clinic.Name, clinic.Id);

        return existingClinic;
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var clinic = await _context.Clinics.FirstOrDefaultAsync(c => c.Id == id);
        if (clinic == null)
        {
            _logger.LogDebug("Clinic not found for deletion with ID: {ClinicId}", id);
            return false;
        }

        // Soft delete by setting IsActive to false
        clinic.IsActive = false;
        clinic.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        _logger.LogInformation("Soft deleted clinic: {ClinicName} with ID: {ClinicId}", clinic.Name, clinic.Id);

        return true;
    }

    public async Task<bool> NameExistsAsync(string name, Guid? excludeId = null)
    {
        var query = _context.Clinics.Where(c => c.Name == name);

        if (excludeId.HasValue)
        {
            query = query.Where(c => c.Id != excludeId.Value);
        }

        return await query.AnyAsync();
    }

    public async Task<bool> CnpjExistsAsync(string cnpj, Guid? excludeId = null)
    {
        if (string.IsNullOrWhiteSpace(cnpj))
            return false;

        var query = _context.Clinics.Where(c => c.Cnpj == cnpj);

        if (excludeId.HasValue)
        {
            query = query.Where(c => c.Id != excludeId.Value);
        }

        return await query.AnyAsync();
    }

    public async Task<Dictionary<string, int>> GetCountsByStatusAndTypeAsync()
    {
        var counts = new Dictionary<string, int>
        {
            ["Total"] = await _context.Clinics.CountAsync(),
            ["Active"] = await _context.Clinics.CountAsync(c => c.IsActive),
            ["Inactive"] = await _context.Clinics.CountAsync(c => !c.IsActive),
            ["Regular"] = await _context.Clinics.CountAsync(c => c.Type == ClinicType.Regular),
            ["Origin"] = await _context.Clinics.CountAsync(c => c.Type == ClinicType.Origin),
            ["Partner"] = await _context.Clinics.CountAsync(c => c.Type == ClinicType.Partner),
            ["Administrative"] = await _context.Clinics.CountAsync(c => c.Type == ClinicType.Administrative)
        };

        _logger.LogDebug("Retrieved clinic statistics: {Counts}", string.Join(", ", counts.Select(kv => $"{kv.Key}: {kv.Value}")));

        return counts;
    }

    private static IQueryable<Clinic> ApplySorting(IQueryable<Clinic> query, string sortBy, string sortDirection)
    {
        var isDescending = sortDirection.Equals("desc", StringComparison.OrdinalIgnoreCase);

        return sortBy.ToLowerInvariant() switch
        {
            "name" => isDescending ? query.OrderByDescending(c => c.Name) : query.OrderBy(c => c.Name),
            "type" => isDescending ? query.OrderByDescending(c => c.Type) : query.OrderBy(c => c.Type),
            "createdat" => isDescending ? query.OrderByDescending(c => c.CreatedAt) : query.OrderBy(c => c.CreatedAt),
            "updatedat" => isDescending ? query.OrderByDescending(c => c.UpdatedAt) : query.OrderBy(c => c.UpdatedAt),
            "isactive" => isDescending ? query.OrderByDescending(c => c.IsActive) : query.OrderBy(c => c.IsActive),
            "address" => isDescending ? query.OrderByDescending(c => c.Address) : query.OrderBy(c => c.Address),
            _ => query.OrderBy(c => c.Name) // Default sort by name
        };
    }
}