using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Data.Models;
using SingleClin.API.Data.Models.Enums;
using SingleClin.API.DTOs.Transaction;
using System.Linq.Expressions;

namespace SingleClin.API.Repositories;

/// <summary>
/// Repository for transaction data access operations
/// </summary>
public class TransactionRepository : ITransactionRepository
{
    private readonly AppDbContext _context;
    private readonly ILogger<TransactionRepository> _logger;

    public TransactionRepository(AppDbContext context, ILogger<TransactionRepository> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<TransactionListResponseDto> GetTransactionsAsync(TransactionFilterDto filter)
    {
        try
        {
            var query = _context.Transactions
                .Include(t => t.UserPlan)
                    .ThenInclude(up => up.User)
                .Include(t => t.UserPlan)
                    .ThenInclude(up => up.Plan)
                .Include(t => t.Clinic)
                .AsQueryable();

            // Apply filters
            query = ApplyFilters(query, filter);

            // Get total count before pagination
            var totalCount = await query.CountAsync();

            // Apply sorting
            query = ApplySorting(query, filter.SortBy, filter.SortOrder);

            // Apply pagination
            var skip = (filter.Page - 1) * filter.Limit;
            var transactions = await query
                .Skip(skip)
                .Take(filter.Limit)
                .Select(t => new TransactionResponseDto
                {
                    Id = t.Id,
                    Code = t.Code,
                    PatientId = t.UserPlan.UserId,
                    PatientName = $"{t.UserPlan.User.FirstName} {t.UserPlan.User.LastName}".Trim(),
                    PatientEmail = t.UserPlan.User.Email,
                    ClinicId = t.ClinicId,
                    ClinicName = t.Clinic.Name,
                    PlanId = t.UserPlan.PlanId,
                    PlanName = t.UserPlan.Plan.Name,
                    UserPlanId = t.UserPlanId,
                    Status = t.Status,
                    CreditsUsed = t.CreditsUsed,
                    ServiceDescription = t.ServiceDescription,
                    ServiceType = t.ServiceType,
                    Amount = t.Amount,
                    CreatedAt = t.CreatedAt,
                    ValidationDate = t.ValidationDate,
                    ValidatedBy = t.ValidatedBy,
                    ValidationNotes = t.ValidationNotes,
                    CancellationDate = t.CancellationDate,
                    CancellationReason = t.CancellationReason,
                    Latitude = t.Latitude,
                    Longitude = t.Longitude,
                    IpAddress = t.IpAddress,
                    UserAgent = t.UserAgent,
                    QRToken = t.QRToken,
                    UpdatedAt = t.UpdatedAt
                })
                .ToListAsync();

            var totalPages = (int)Math.Ceiling((double)totalCount / filter.Limit);

            return new TransactionListResponseDto
            {
                Data = transactions,
                Total = totalCount,
                Page = filter.Page,
                Limit = filter.Limit,
                TotalPages = totalPages,
                HasNextPage = filter.Page < totalPages,
                HasPreviousPage = filter.Page > 1
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting transactions with filters: {@Filter}", filter);
            throw;
        }
    }

    public async Task<Transaction?> GetTransactionByIdAsync(Guid id)
    {
        try
        {
            return await _context.Transactions
                .Include(t => t.UserPlan)
                    .ThenInclude(up => up.User)
                .Include(t => t.UserPlan)
                    .ThenInclude(up => up.Plan)
                .Include(t => t.Clinic)
                .FirstOrDefaultAsync(t => t.Id == id);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting transaction by ID: {TransactionId}", id);
            throw;
        }
    }

    public async Task<Transaction> CreateTransactionAsync(Transaction transaction)
    {
        try
        {
            _context.Transactions.Add(transaction);
            await _context.SaveChangesAsync();

            // Load related entities for complete object
            await _context.Entry(transaction)
                .Reference(t => t.UserPlan)
                .LoadAsync();
            await _context.Entry(transaction.UserPlan)
                .Reference(up => up.User)
                .LoadAsync();
            await _context.Entry(transaction.UserPlan)
                .Reference(up => up.Plan)
                .LoadAsync();
            await _context.Entry(transaction)
                .Reference(t => t.Clinic)
                .LoadAsync();

            return transaction;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating transaction: {@Transaction}", transaction);
            throw;
        }
    }

    public async Task<Transaction> UpdateTransactionAsync(Transaction transaction)
    {
        try
        {
            transaction.UpdatedAt = DateTime.UtcNow;
            _context.Transactions.Update(transaction);
            await _context.SaveChangesAsync();
            return transaction;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating transaction: {TransactionId}", transaction.Id);
            throw;
        }
    }

    public async Task<TransactionListResponseDto> GetClinicTransactionsAsync(Guid clinicId, int page, int pageSize)
    {
        try
        {
            var filter = new TransactionFilterDto
            {
                ClinicId = clinicId,
                Page = page,
                Limit = pageSize,
                SortBy = "CreatedAt",
                SortOrder = "desc"
            };

            return await GetTransactionsAsync(filter);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting clinic transactions: {ClinicId}", clinicId);
            throw;
        }
    }

    public async Task<TransactionListResponseDto> GetPatientTransactionsAsync(Guid patientId, int page, int pageSize)
    {
        try
        {
            var filter = new TransactionFilterDto
            {
                PatientId = patientId,
                Page = page,
                Limit = pageSize,
                SortBy = "CreatedAt",
                SortOrder = "desc"
            };

            return await GetTransactionsAsync(filter);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting patient transactions: {PatientId}", patientId);
            throw;
        }
    }

    public async Task<DashboardMetricsDto> GetDashboardMetricsAsync(DateTime? startDate, DateTime? endDate)
    {
        try
        {
            var query = _context.Transactions
                .Include(t => t.UserPlan)
                    .ThenInclude(up => up.Plan)
                .Include(t => t.Clinic)
                .AsQueryable();

            // Apply date filters if provided
            if (startDate.HasValue)
                query = query.Where(t => t.CreatedAt >= startDate.Value);
            if (endDate.HasValue)
                query = query.Where(t => t.CreatedAt <= endDate.Value);

            var transactions = await query.ToListAsync();
            var currentMonth = DateTime.UtcNow.AddDays(-30);

            // Calculate metrics
            var metrics = new DashboardMetricsDto
            {
                TotalTransactions = transactions.Count,
                TotalRevenue = transactions.Sum(t => t.Amount),
                TransactionsThisMonth = transactions.Count(t => t.CreatedAt >= currentMonth),
                RevenueThisMonth = transactions.Where(t => t.CreatedAt >= currentMonth).Sum(t => t.Amount),
                ActivePatients = transactions.Select(t => t.UserPlan.UserId).Distinct().Count(),
                ActiveClinics = transactions.Select(t => t.ClinicId).Distinct().Count(),
                ActivePlans = transactions.Select(t => t.UserPlan.PlanId).Distinct().Count(),
                AverageTransactionAmount = transactions.Any() ? transactions.Average(t => t.Amount) : 0,
                AverageCreditsPerTransaction = transactions.Any() ? transactions.Average(t => t.CreditsUsed) : 0
            };

            // Most used plan
            var mostUsedPlan = transactions
                .GroupBy(t => new { t.UserPlan.PlanId, t.UserPlan.Plan.Name })
                .OrderByDescending(g => g.Count())
                .FirstOrDefault();

            if (mostUsedPlan != null)
            {
                metrics.MostUsedPlan = new MostUsedPlanDto
                {
                    Id = mostUsedPlan.Key.PlanId,
                    Name = mostUsedPlan.Key.Name,
                    TransactionCount = mostUsedPlan.Count(),
                    TotalRevenue = mostUsedPlan.Sum(t => t.Amount)
                };
            }

            // Top clinic
            var topClinic = transactions
                .GroupBy(t => new { t.ClinicId, t.Clinic.Name })
                .OrderByDescending(g => g.Count())
                .FirstOrDefault();

            if (topClinic != null)
            {
                metrics.TopClinic = new TopClinicDto
                {
                    Id = topClinic.Key.ClinicId,
                    Name = topClinic.Key.Name,
                    TransactionCount = topClinic.Count(),
                    TotalRevenue = topClinic.Sum(t => t.Amount)
                };
            }

            // Status distribution
            metrics.StatusDistribution = transactions
                .GroupBy(t => t.Status)
                .Select(g => new StatusDistributionDto
                {
                    Status = g.Key.ToString(),
                    Count = g.Count(),
                    Percentage = transactions.Count > 0 ? (double)g.Count() / transactions.Count * 100 : 0
                })
                .ToList();

            // Monthly trends (last 12 months)
            var twelveMonthsAgo = DateTime.UtcNow.AddMonths(-12);
            var monthlyData = await _context.Transactions
                .Where(t => t.CreatedAt >= twelveMonthsAgo)
                .GroupBy(t => new { Year = t.CreatedAt.Year, Month = t.CreatedAt.Month })
                .Select(g => new MonthlyTrendDto
                {
                    Month = $"{g.Key.Year:0000}-{g.Key.Month:00}",
                    TransactionCount = g.Count(),
                    Revenue = g.Sum(t => t.Amount),
                    CreditsUsed = g.Sum(t => t.CreditsUsed)
                })
                .OrderBy(m => m.Month)
                .ToListAsync();

            metrics.MonthlyTrends = monthlyData;

            return metrics;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting dashboard metrics");
            throw;
        }
    }

    public async Task<List<Transaction>> GetTransactionsForExportAsync(TransactionFilterDto filter)
    {
        try
        {
            var query = _context.Transactions
                .Include(t => t.UserPlan)
                    .ThenInclude(up => up.User)
                .Include(t => t.UserPlan)
                    .ThenInclude(up => up.Plan)
                .Include(t => t.Clinic)
                .AsQueryable();

            // Apply filters
            query = ApplyFilters(query, filter);

            // Apply sorting
            query = ApplySorting(query, filter.SortBy, filter.SortOrder);

            return await query.ToListAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting transactions for export: {@Filter}", filter);
            throw;
        }
    }

    public async Task<bool> CanCancelTransactionAsync(Guid transactionId)
    {
        try
        {
            var transaction = await _context.Transactions
                .FirstOrDefaultAsync(t => t.Id == transactionId);

            if (transaction == null)
                return false;

            // Can cancel if status is Validated and not already cancelled
            return transaction.Status == TransactionStatus.Validated;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking if transaction can be cancelled: {TransactionId}", transactionId);
            throw;
        }
    }

    public async Task<object> GetTransactionStatisticsAsync(DateTime startDate, DateTime endDate)
    {
        try
        {
            var transactions = await _context.Transactions
                .Include(t => t.UserPlan)
                    .ThenInclude(up => up.Plan)
                .Include(t => t.Clinic)
                .Where(t => t.CreatedAt >= startDate && t.CreatedAt <= endDate)
                .ToListAsync();

            return new
            {
                TotalTransactions = transactions.Count,
                TotalRevenue = transactions.Sum(t => t.Amount),
                TotalCreditsUsed = transactions.Sum(t => t.CreditsUsed),
                AverageAmount = transactions.Any() ? transactions.Average(t => t.Amount) : 0,
                ByStatus = transactions.GroupBy(t => t.Status)
                    .Select(g => new { Status = g.Key.ToString(), Count = g.Count() })
                    .ToList(),
                ByClinic = transactions.GroupBy(t => new { t.ClinicId, t.Clinic.Name })
                    .Select(g => new { ClinicName = g.Key.Name, Count = g.Count(), Revenue = g.Sum(t => t.Amount) })
                    .OrderByDescending(c => c.Count)
                    .Take(10)
                    .ToList(),
                ByPlan = transactions.GroupBy(t => new { t.UserPlan.PlanId, t.UserPlan.Plan.Name })
                    .Select(g => new { PlanName = g.Key.Name, Count = g.Count(), Revenue = g.Sum(t => t.Amount) })
                    .OrderByDescending(p => p.Count)
                    .Take(10)
                    .ToList()
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting transaction statistics from {StartDate} to {EndDate}", startDate, endDate);
            throw;
        }
    }

    private IQueryable<Transaction> ApplyFilters(IQueryable<Transaction> query, TransactionFilterDto filter)
    {
        // Search filter
        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var searchLower = filter.Search.ToLower();
            query = query.Where(t =>
                t.Code.ToLower().Contains(searchLower) ||
                ($"{t.UserPlan.User.FirstName} {t.UserPlan.User.LastName}").ToLower().Contains(searchLower) ||
                t.UserPlan.User.Email.ToLower().Contains(searchLower) ||
                t.Clinic.Name.ToLower().Contains(searchLower) ||
                t.UserPlan.Plan.Name.ToLower().Contains(searchLower) ||
                (t.ServiceDescription != null && t.ServiceDescription.ToLower().Contains(searchLower)));
        }

        // Patient filter
        if (filter.PatientId.HasValue)
        {
            query = query.Where(t => t.UserPlan.UserId == filter.PatientId.Value);
        }

        // Clinic filter
        if (filter.ClinicId.HasValue)
        {
            query = query.Where(t => t.ClinicId == filter.ClinicId.Value);
        }

        // Plan filter
        if (filter.PlanId.HasValue)
        {
            query = query.Where(t => t.UserPlan.PlanId == filter.PlanId.Value);
        }

        // Status filter
        if (filter.Status.HasValue)
        {
            query = query.Where(t => t.Status == filter.Status.Value);
        }

        // Date filters
        if (filter.StartDate.HasValue)
        {
            query = query.Where(t => t.CreatedAt >= filter.StartDate.Value);
        }

        if (filter.EndDate.HasValue)
        {
            query = query.Where(t => t.CreatedAt <= filter.EndDate.Value);
        }

        // Validation date filters
        if (filter.ValidationStartDate.HasValue)
        {
            query = query.Where(t => t.ValidationDate != null && t.ValidationDate >= filter.ValidationStartDate.Value);
        }

        if (filter.ValidationEndDate.HasValue)
        {
            query = query.Where(t => t.ValidationDate != null && t.ValidationDate <= filter.ValidationEndDate.Value);
        }

        // Amount filters
        if (filter.MinAmount.HasValue)
        {
            query = query.Where(t => t.Amount >= filter.MinAmount.Value);
        }

        if (filter.MaxAmount.HasValue)
        {
            query = query.Where(t => t.Amount <= filter.MaxAmount.Value);
        }

        // Credits filters
        if (filter.MinCredits.HasValue)
        {
            query = query.Where(t => t.CreditsUsed >= filter.MinCredits.Value);
        }

        if (filter.MaxCredits.HasValue)
        {
            query = query.Where(t => t.CreditsUsed <= filter.MaxCredits.Value);
        }

        // Service type filter
        if (!string.IsNullOrWhiteSpace(filter.ServiceType))
        {
            query = query.Where(t => t.ServiceType == filter.ServiceType);
        }

        // Include/exclude cancelled transactions
        if (!filter.IncludeCancelled)
        {
            query = query.Where(t => t.Status != TransactionStatus.Cancelled);
        }

        return query;
    }

    private IQueryable<Transaction> ApplySorting(IQueryable<Transaction> query, string? sortBy, string? sortOrder)
    {
        var isDescending = sortOrder?.ToLower() == "desc";

        return (sortBy?.ToLower()) switch
        {
            "code" => isDescending ? query.OrderByDescending(t => t.Code) : query.OrderBy(t => t.Code),
            "patientname" => isDescending ? query.OrderByDescending(t => t.UserPlan.User.FirstName + " " + t.UserPlan.User.LastName) : query.OrderBy(t => t.UserPlan.User.FirstName + " " + t.UserPlan.User.LastName),
            "clinicname" => isDescending ? query.OrderByDescending(t => t.Clinic.Name) : query.OrderBy(t => t.Clinic.Name),
            "planname" => isDescending ? query.OrderByDescending(t => t.UserPlan.Plan.Name) : query.OrderBy(t => t.UserPlan.Plan.Name),
            "status" => isDescending ? query.OrderByDescending(t => t.Status) : query.OrderBy(t => t.Status),
            "creditsused" => isDescending ? query.OrderByDescending(t => t.CreditsUsed) : query.OrderBy(t => t.CreditsUsed),
            "amount" => isDescending ? query.OrderByDescending(t => t.Amount) : query.OrderBy(t => t.Amount),
            "validationdate" => isDescending ? query.OrderByDescending(t => t.ValidationDate) : query.OrderBy(t => t.ValidationDate),
            "updatedat" => isDescending ? query.OrderByDescending(t => t.UpdatedAt) : query.OrderBy(t => t.UpdatedAt),
            _ => isDescending ? query.OrderByDescending(t => t.CreatedAt) : query.OrderBy(t => t.CreatedAt) // Default to CreatedAt
        };
    }
}