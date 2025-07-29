using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Data.Models;

namespace SingleClin.API.Repositories;

/// <summary>
/// Repository implementation for Plan entity operations
/// </summary>
public class PlanRepository : IPlanRepository
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<PlanRepository> _logger;

    public PlanRepository(ApplicationDbContext context, ILogger<PlanRepository> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<(IEnumerable<Plan> Plans, int TotalCount)> GetAllAsync(
        int pageNumber = 1, 
        int pageSize = 10, 
        bool? isActive = null, 
        string? searchTerm = null, 
        decimal? minPrice = null, 
        decimal? maxPrice = null)
    {
        var query = _context.Plans.AsQueryable();

        // Apply filters
        if (isActive.HasValue)
        {
            query = query.Where(p => p.IsActive == isActive.Value);
        }

        if (!string.IsNullOrWhiteSpace(searchTerm))
        {
            query = query.Where(p => EF.Functions.ILike(p.Name, $"%{searchTerm}%") || 
                                   EF.Functions.ILike(p.Description ?? "", $"%{searchTerm}%"));
        }

        if (minPrice.HasValue)
        {
            query = query.Where(p => p.Price >= minPrice.Value);
        }

        if (maxPrice.HasValue)
        {
            query = query.Where(p => p.Price <= maxPrice.Value);
        }

        // Get total count for pagination
        int totalCount = await query.CountAsync();

        // Apply pagination and ordering
        var plans = await query
            .OrderBy(p => p.DisplayOrder)
            .ThenBy(p => p.Name)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .AsNoTracking()
            .ToListAsync();

        _logger.LogDebug("Retrieved {Count} plans from database with filters: Active={IsActive}, Search={SearchTerm}, MinPrice={MinPrice}, MaxPrice={MaxPrice}", 
            plans.Count, isActive, searchTerm, minPrice, maxPrice);

        return (plans, totalCount);
    }

    public async Task<Plan?> GetByIdAsync(Guid id)
    {
        var plan = await _context.Plans
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == id);

        if (plan == null)
        {
            _logger.LogDebug("Plan not found with ID: {PlanId}", id);
        }

        return plan;
    }

    public async Task<Plan?> GetByNameAsync(string name)
    {
        var plan = await _context.Plans
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Name == name);

        return plan;
    }

    public async Task<IEnumerable<Plan>> GetActiveAsync()
    {
        var plans = await _context.Plans
            .Where(p => p.IsActive)
            .OrderBy(p => p.DisplayOrder)
            .ThenBy(p => p.Name)
            .AsNoTracking()
            .ToListAsync();

        _logger.LogDebug("Retrieved {Count} active plans", plans.Count);

        return plans;
    }

    public async Task<Plan> CreateAsync(Plan plan)
    {
        plan.CreatedAt = DateTime.UtcNow;
        plan.UpdatedAt = DateTime.UtcNow;

        _context.Plans.Add(plan);
        await _context.SaveChangesAsync();

        _logger.LogInformation("Created new plan: {PlanName} with ID: {PlanId}", plan.Name, plan.Id);

        return plan;
    }

    public async Task<Plan> UpdateAsync(Plan plan)
    {
        var existingPlan = await _context.Plans.FirstOrDefaultAsync(p => p.Id == plan.Id);
        if (existingPlan == null)
        {
            throw new InvalidOperationException($"Plan with ID {plan.Id} not found for update");
        }

        // Update fields
        existingPlan.Name = plan.Name;
        existingPlan.Description = plan.Description;
        existingPlan.Credits = plan.Credits;
        existingPlan.Price = plan.Price;
        existingPlan.OriginalPrice = plan.OriginalPrice;
        existingPlan.ValidityDays = plan.ValidityDays;
        existingPlan.IsActive = plan.IsActive;
        existingPlan.DisplayOrder = plan.DisplayOrder;
        existingPlan.IsFeatured = plan.IsFeatured;
        existingPlan.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        _logger.LogInformation("Updated plan: {PlanName} with ID: {PlanId}", existingPlan.Name, existingPlan.Id);

        return existingPlan;
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var plan = await _context.Plans.FirstOrDefaultAsync(p => p.Id == id);
        if (plan == null)
        {
            _logger.LogWarning("Attempted to delete non-existent plan with ID: {PlanId}", id);
            return false;
        }

        // Soft delete by setting IsActive to false
        plan.IsActive = false;
        plan.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        _logger.LogInformation("Soft deleted plan: {PlanName} with ID: {PlanId}", plan.Name, plan.Id);

        return true;
    }

    public async Task<bool> NameExistsAsync(string name, Guid? excludeId = null)
    {
        var query = _context.Plans.Where(p => p.Name == name);

        if (excludeId.HasValue)
        {
            query = query.Where(p => p.Id != excludeId.Value);
        }

        return await query.AnyAsync();
    }

    public async Task<Dictionary<string, int>> GetCountsByStatusAsync()
    {
        var counts = await _context.Plans
            .GroupBy(p => p.IsActive)
            .Select(g => new { IsActive = g.Key, Count = g.Count() })
            .ToListAsync();

        var result = new Dictionary<string, int>
        {
            ["Active"] = counts.FirstOrDefault(c => c.IsActive)?.Count ?? 0,
            ["Inactive"] = counts.FirstOrDefault(c => !c.IsActive)?.Count ?? 0,
            ["Total"] = counts.Sum(c => c.Count)
        };

        // Add featured plans count
        result["Featured"] = await _context.Plans.CountAsync(p => p.IsFeatured && p.IsActive);

        return result;
    }
}