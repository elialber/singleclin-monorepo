using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using SingleClin.API.Data;
using SingleClin.API.Data.Models;
using SingleClin.API.DTOs.Report;
using System.Diagnostics;

namespace SingleClin.API.Services
{
    /// <summary>
    /// Service for generating various reports
    /// </summary>
    public class ReportService : IReportService
    {
        private readonly ILogger<ReportService> _logger;
        private readonly ApplicationDbContext _context;
        private readonly IMemoryCache _cache;
        private readonly IConfiguration _configuration;

        // Cache settings
        private readonly MemoryCacheEntryOptions _cacheOptions;
        private const string CacheKeyPrefix = "Report_";

        public ReportService(
            ILogger<ReportService> logger,
            ApplicationDbContext context,
            IMemoryCache cache,
            IConfiguration configuration)
        {
            _logger = logger;
            _context = context;
            _cache = cache;
            _configuration = configuration;

            // Configure cache options
            _cacheOptions = new MemoryCacheEntryOptions
            {
                SlidingExpiration = TimeSpan.FromMinutes(15),
                AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(1),
                Priority = CacheItemPriority.Normal
            };
        }

        public async Task<object> GenerateReportAsync(ReportRequest request, CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("Generating report of type {ReportType} for period {StartDate} to {EndDate}", 
                    request.Type, request.StartDate, request.EndDate);

                // Validate request
                if (!request.IsValid())
                {
                    throw new ArgumentException("Invalid report request parameters");
                }

                // Route to specific report generator
                return request.Type switch
                {
                    ReportType.UsageByPeriod => await GenerateUsageReportAsync(request, cancellationToken),
                    ReportType.ClinicRanking => await GenerateClinicRankingAsync(request, cancellationToken),
                    ReportType.TopServices => await GenerateServiceReportAsync(request, cancellationToken),
                    ReportType.PlanUtilization => await GeneratePlanUtilizationAsync(request, cancellationToken),
                    _ => throw new NotImplementedException($"Report type {request.Type} is not implemented yet")
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating report of type {ReportType}", request.Type);
                throw;
            }
        }

        public async Task<ReportResponse<UsageReportData>> GenerateUsageReportAsync(
            ReportRequest request, 
            CancellationToken cancellationToken = default)
        {
            var stopwatch = Stopwatch.StartNew();
            var cacheKey = GenerateCacheKey(request);

            // Try to get from cache
            if (_cache.TryGetValue<ReportResponse<UsageReportData>>(cacheKey, out var cachedReport))
            {
                _logger.LogInformation("Returning cached usage report");
                cachedReport!.FromCache = true;
                return cachedReport;
            }

            try
            {
                _logger.LogInformation("Generating usage report from database");

                // Build base query
                var transactionsQuery = _context.Transactions
                    .AsNoTracking()
                    .Where(t => t.CreatedAt >= request.StartDate && 
                               t.CreatedAt <= request.EndDate);

                // Apply filters
                if (request.ClinicIds?.Any() == true)
                {
                    transactionsQuery = transactionsQuery.Where(t => request.ClinicIds.Contains(t.ClinicId));
                }

                if (request.ServiceTypes?.Any() == true)
                {
                    transactionsQuery = transactionsQuery.Where(t => request.ServiceTypes.Contains(t.ServiceType));
                }

                // Get period data based on aggregation level
                var periodData = await GetUsagePeriodData(transactionsQuery, request, cancellationToken);

                // Get top clinics
                var topClinics = await GetTopClinicsUsage(transactionsQuery, cancellationToken);

                // Get plan distribution
                var planDistribution = await GetPlanDistribution(transactionsQuery, cancellationToken);

                // Calculate trends
                var trend = CalculateUsageTrend(periodData);

                // Build response
                var response = new ReportResponse<UsageReportData>
                {
                    Type = ReportType.UsageByPeriod,
                    Title = "Usage Analysis Report",
                    Description = $"Usage analysis from {request.StartDate:yyyy-MM-dd} to {request.EndDate:yyyy-MM-dd}",
                    Period = new ReportPeriodInfo
                    {
                        StartDate = request.StartDate,
                        EndDate = request.EndDate,
                        Period = request.Period,
                        TimeZone = request.TimeZone
                    },
                    Filters = new ReportFilters
                    {
                        ClinicIds = request.ClinicIds,
                        ServiceTypes = request.ServiceTypes,
                        SortBy = request.SortBy,
                        SortDirection = request.SortDirection
                    },
                    Data = new UsageReportData
                    {
                        Periods = periodData,
                        Trend = trend,
                        TopClinics = topClinics,
                        PlanDistribution = planDistribution
                    },
                    Summary = new ReportSummary
                    {
                        TotalRecords = periodData.Sum(p => p.TotalTransactions),
                        Totals = new Dictionary<string, decimal>
                        {
                            ["TotalTransactions"] = periodData.Sum(p => p.TotalTransactions),
                            ["TotalCreditsUsed"] = periodData.Sum(p => p.CreditsUsed),
                            ["UniquePatients"] = periodData.Select(p => p.UniquePatients).DefaultIfEmpty(0).Max(),
                            ["ActiveClinics"] = topClinics.Count
                        },
                        Averages = new Dictionary<string, decimal>
                        {
                            ["AverageTransactionsPerDay"] = trend.AverageDailyTransactions,
                            ["AverageCreditsPerTransaction"] = periodData.Any() ? 
                                periodData.Average(p => p.AverageCreditsPerTransaction) : 0
                        }
                    },
                    ChartData = GenerateUsageChartData(periodData),
                    ExecutionTimeMs = stopwatch.ElapsedMilliseconds,
                    FromCache = false,
                    CacheExpiresAt = DateTime.UtcNow.Add(_cacheOptions.AbsoluteExpirationRelativeToNow!.Value)
                };

                // Cache the result
                _cache.Set(cacheKey, response, _cacheOptions);

                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating usage report");
                throw;
            }
            finally
            {
                stopwatch.Stop();
            }
        }

        public async Task<ReportResponse<ClinicRankingData>> GenerateClinicRankingAsync(
            ReportRequest request, 
            CancellationToken cancellationToken = default)
        {
            var stopwatch = Stopwatch.StartNew();
            var cacheKey = GenerateCacheKey(request);

            // Try to get from cache
            if (_cache.TryGetValue<ReportResponse<ClinicRankingData>>(cacheKey, out var cachedReport))
            {
                _logger.LogInformation("Returning cached clinic ranking report");
                cachedReport!.FromCache = true;
                return cachedReport;
            }

            try
            {
                _logger.LogInformation("Generating clinic ranking report from database");

                // Get clinic metrics
                var clinicMetrics = await GetClinicMetrics(request, cancellationToken);

                // Calculate rankings
                var rankings = CalculateClinicRankings(clinicMetrics);

                // Get growth leaders
                var growthLeaders = GetGrowthLeaders(clinicMetrics);

                // Calculate overall metrics
                var overallMetrics = CalculateOverallClinicMetrics(clinicMetrics);

                var response = new ReportResponse<ClinicRankingData>
                {
                    Type = ReportType.ClinicRanking,
                    Title = "Clinic Performance Ranking",
                    Description = $"Clinic performance ranking from {request.StartDate:yyyy-MM-dd} to {request.EndDate:yyyy-MM-dd}",
                    Period = new ReportPeriodInfo
                    {
                        StartDate = request.StartDate,
                        EndDate = request.EndDate,
                        Period = request.Period,
                        TimeZone = request.TimeZone
                    },
                    Data = new ClinicRankingData
                    {
                        Rankings = rankings,
                        OverallMetrics = overallMetrics,
                        GrowthLeaders = growthLeaders
                    },
                    Summary = new ReportSummary
                    {
                        TotalRecords = rankings.Count,
                        Totals = new Dictionary<string, decimal>
                        {
                            ["TotalClinics"] = rankings.Count,
                            ["TotalTransactions"] = rankings.Sum(r => r.Metrics.TotalTransactions),
                            ["TotalCreditsProcessed"] = rankings.Sum(r => r.Metrics.CreditsProcessed)
                        }
                    },
                    ChartData = GenerateClinicRankingChartData(rankings.Take(10).ToList()),
                    ExecutionTimeMs = stopwatch.ElapsedMilliseconds,
                    FromCache = false,
                    CacheExpiresAt = DateTime.UtcNow.Add(_cacheOptions.AbsoluteExpirationRelativeToNow!.Value)
                };

                // Apply pagination if needed
                if (request.PageSize < rankings.Count)
                {
                    var paginatedRankings = rankings
                        .Skip((request.Page - 1) * request.PageSize)
                        .Take(request.PageSize)
                        .ToList();

                    response.Data.Rankings = paginatedRankings;
                    response.Pagination = new PaginationInfo
                    {
                        CurrentPage = request.Page,
                        PageSize = request.PageSize,
                        TotalRecords = rankings.Count
                    };
                }

                // Cache the result
                _cache.Set(cacheKey, response, _cacheOptions);

                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating clinic ranking report");
                throw;
            }
            finally
            {
                stopwatch.Stop();
            }
        }

        public async Task<ReportResponse<ServiceReportData>> GenerateServiceReportAsync(
            ReportRequest request, 
            CancellationToken cancellationToken = default)
        {
            var stopwatch = Stopwatch.StartNew();
            var cacheKey = GenerateCacheKey(request);

            // Try to get from cache
            if (_cache.TryGetValue<ReportResponse<ServiceReportData>>(cacheKey, out var cachedReport))
            {
                _logger.LogInformation("Returning cached service report");
                cachedReport!.FromCache = true;
                return cachedReport;
            }

            try
            {
                _logger.LogInformation("Generating service report from database");

                // Build base query
                var transactionsQuery = _context.Transactions
                    .AsNoTracking()
                    .Include(t => t.Clinic)
                    .Include(t => t.UserPlan)
                    .ThenInclude(up => up.User)
                    .Where(t => t.CreatedAt >= request.StartDate && 
                               t.CreatedAt <= request.EndDate &&
                               t.Status == Data.Models.Enums.TransactionStatus.Validated);

                // Apply filters
                if (request.ClinicIds?.Any() == true)
                {
                    transactionsQuery = transactionsQuery.Where(t => request.ClinicIds.Contains(t.ClinicId));
                }

                // Get service usage data
                var topServices = await GetTopServicesAsync(transactionsQuery, cancellationToken);

                // Get service distribution
                var distribution = await GetServiceDistributionAsync(transactionsQuery, cancellationToken);

                // Get service trends
                var trends = await GetServiceTrendsAsync(transactionsQuery, request, cancellationToken);

                // Generate insights
                var insights = GenerateServiceInsights(topServices, trends, distribution);

                // Build response
                var response = new ReportResponse<ServiceReportData>
                {
                    Type = ReportType.TopServices,
                    Title = "Service Usage Analysis",
                    Description = $"Service usage analysis from {request.StartDate:yyyy-MM-dd} to {request.EndDate:yyyy-MM-dd}",
                    Period = new ReportPeriodInfo
                    {
                        StartDate = request.StartDate,
                        EndDate = request.EndDate,
                        Period = request.Period,
                        TimeZone = request.TimeZone
                    },
                    Data = new ServiceReportData
                    {
                        TopServices = topServices,
                        Distribution = distribution,
                        Trends = trends,
                        Insights = insights
                    },
                    Summary = new ReportSummary
                    {
                        TotalRecords = topServices.Sum(s => s.UsageCount),
                        Totals = new Dictionary<string, decimal>
                        {
                            ["TotalServices"] = distribution.TotalUniqueServices,
                            ["TotalUsageCount"] = topServices.Sum(s => s.UsageCount),
                            ["TotalCreditsUsed"] = topServices.Sum(s => s.TotalCreditsUsed),
                            ["UniquePatients"] = topServices.Sum(s => s.UniquePatients)
                        },
                        Averages = new Dictionary<string, decimal>
                        {
                            ["AverageCreditsPerService"] = topServices.Any() ? 
                                topServices.Average(s => s.AverageCreditsPerUse) : 0,
                            ["AverageUsagePerService"] = topServices.Any() ? 
                                (decimal)topServices.Average(s => s.UsageCount) : 0
                        }
                    },
                    ChartData = GenerateServiceChartData(topServices.Take(10).ToList()),
                    ExecutionTimeMs = stopwatch.ElapsedMilliseconds,
                    FromCache = false,
                    CacheExpiresAt = DateTime.UtcNow.Add(_cacheOptions.AbsoluteExpirationRelativeToNow!.Value)
                };

                // Cache the result
                _cache.Set(cacheKey, response, _cacheOptions);

                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating service report");
                throw;
            }
            finally
            {
                stopwatch.Stop();
            }
        }

        public async Task<ReportResponse<PlanUtilizationData>> GeneratePlanUtilizationAsync(
            ReportRequest request, 
            CancellationToken cancellationToken = default)
        {
            var stopwatch = Stopwatch.StartNew();
            var cacheKey = GenerateCacheKey(request);

            // Try to get from cache
            if (_cache.TryGetValue<ReportResponse<PlanUtilizationData>>(cacheKey, out var cachedReport))
            {
                _logger.LogInformation("Returning cached plan utilization report");
                cachedReport!.FromCache = true;
                return cachedReport;
            }

            try
            {
                _logger.LogInformation("Generating plan utilization report from database");

                // Get plan utilization data
                var planData = await GetPlanUtilizationDataAsync(request, cancellationToken);

                // Calculate summary metrics
                var summary = CalculateUtilizationSummary(planData);

                // Identify utilization patterns
                var patterns = IdentifyUtilizationPatterns(planData);

                // Calculate efficiency metrics
                var efficiency = CalculatePlanEfficiencyMetrics(planData);

                // Build response
                var response = new ReportResponse<PlanUtilizationData>
                {
                    Type = ReportType.PlanUtilization,
                    Title = "Plan Utilization Analysis",
                    Description = $"Plan utilization analysis from {request.StartDate:yyyy-MM-dd} to {request.EndDate:yyyy-MM-dd}",
                    Period = new ReportPeriodInfo
                    {
                        StartDate = request.StartDate,
                        EndDate = request.EndDate,
                        Period = request.Period,
                        TimeZone = request.TimeZone
                    },
                    Data = new PlanUtilizationData
                    {
                        Plans = planData,
                        Summary = summary,
                        Patterns = patterns,
                        Efficiency = efficiency
                    },
                    Summary = new ReportSummary
                    {
                        TotalRecords = planData.Count,
                        Totals = new Dictionary<string, decimal>
                        {
                            ["TotalPlans"] = planData.Count,
                            ["TotalActiveUsers"] = planData.Sum(p => p.Usage.ActiveUsers),
                            ["TotalCreditsUsed"] = planData.Sum(p => p.Usage.TotalCreditsUsed),
                            ["TotalCreditsWasted"] = planData.Sum(p => p.Usage.TotalCreditsExpired)
                        },
                        Averages = new Dictionary<string, decimal>
                        {
                            ["AverageUtilizationRate"] = summary.OverallUtilizationRate,
                            ["AverageEfficiency"] = efficiency.AverageCreditEfficiency
                        }
                    },
                    ChartData = GeneratePlanUtilizationChartData(planData),
                    ExecutionTimeMs = stopwatch.ElapsedMilliseconds,
                    FromCache = false,
                    CacheExpiresAt = DateTime.UtcNow.Add(_cacheOptions.AbsoluteExpirationRelativeToNow!.Value)
                };

                // Cache the result
                _cache.Set(cacheKey, response, _cacheOptions);

                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating plan utilization report");
                throw;
            }
            finally
            {
                stopwatch.Stop();
            }
        }

        public async Task<byte[]> ExportReportAsync(
            object reportData, 
            ExportFormat format, 
            CancellationToken cancellationToken = default)
        {
            // Implementation for export functionality
            // This will be implemented when we add export services
            throw new NotImplementedException("Export functionality will be implemented in a future task");
        }

        public async Task<List<ReportTypeInfo>> GetAvailableReportTypesAsync(string userRole)
        {
            var reportTypes = new List<ReportTypeInfo>
            {
                new ReportTypeInfo
                {
                    Type = ReportType.UsageByPeriod,
                    Name = "Usage Analysis",
                    Description = "Analyze usage patterns over time periods",
                    RequiredRoles = new List<string> { "Administrator", "ClinicOwner" },
                    AvailableFilters = new List<string> { "Period", "Clinic", "Service Type" },
                    SupportedFormats = new List<ExportFormat> { ExportFormat.Json, ExportFormat.Excel, ExportFormat.Pdf }
                },
                new ReportTypeInfo
                {
                    Type = ReportType.ClinicRanking,
                    Name = "Clinic Performance Ranking",
                    Description = "Rank clinics by various performance metrics",
                    RequiredRoles = new List<string> { "Administrator" },
                    AvailableFilters = new List<string> { "Period", "Clinic Type", "Location" },
                    SupportedFormats = new List<ExportFormat> { ExportFormat.Json, ExportFormat.Excel, ExportFormat.Pdf }
                },
                new ReportTypeInfo
                {
                    Type = ReportType.TopServices,
                    Name = "Top Services Analysis",
                    Description = "Analyze most used services and trends",
                    RequiredRoles = new List<string> { "Administrator", "ClinicOwner" },
                    AvailableFilters = new List<string> { "Period", "Clinic", "Category" },
                    SupportedFormats = new List<ExportFormat> { ExportFormat.Json, ExportFormat.Excel }
                },
                new ReportTypeInfo
                {
                    Type = ReportType.PlanUtilization,
                    Name = "Plan Utilization Analysis",
                    Description = "Analyze plan usage efficiency and patterns",
                    RequiredRoles = new List<string> { "Administrator" },
                    AvailableFilters = new List<string> { "Period", "Plan", "User Segment" },
                    SupportedFormats = new List<ExportFormat> { ExportFormat.Json, ExportFormat.Excel, ExportFormat.Pdf }
                }
            };

            // Filter by role
            return await Task.FromResult(reportTypes
                .Where(rt => rt.RequiredRoles.Contains(userRole))
                .ToList());
        }

        public async Task ClearReportCacheAsync(ReportType? reportType = null)
        {
            if (reportType.HasValue)
            {
                // Clear specific report type cache
                var pattern = $"{CacheKeyPrefix}{reportType.Value}_*";
                _logger.LogInformation("Clearing cache for report type {ReportType}", reportType.Value);
                // Note: IMemoryCache doesn't support pattern-based removal
                // In production, consider using IDistributedCache with Redis
            }
            else
            {
                // Clear all report caches
                _logger.LogInformation("Clearing all report caches");
                // This would require tracking all cache keys or using a distributed cache
            }

            await Task.CompletedTask;
        }

        #region Private Helper Methods

        private string GenerateCacheKey(ReportRequest request)
        {
            var key = $"{CacheKeyPrefix}{request.Type}_{request.StartDate:yyyyMMdd}_{request.EndDate:yyyyMMdd}";
            
            if (request.ClinicIds?.Any() == true)
                key += $"_C{string.Join(",", request.ClinicIds)}";
            
            if (request.ServiceTypes?.Any() == true)
                key += $"_S{string.Join(",", request.ServiceTypes)}";
            
            if (request.PlanIds?.Any() == true)
                key += $"_P{string.Join(",", request.PlanIds)}";

            key += $"_{request.Period}_{request.Page}_{request.PageSize}";

            return key;
        }

        private async Task<List<UsagePeriodData>> GetUsagePeriodData(
            IQueryable<Transaction> query, 
            ReportRequest request, 
            CancellationToken cancellationToken)
        {
            var periodData = new List<UsagePeriodData>();

            // Group by period
            switch (request.Period)
            {
                case ReportPeriod.Daily:
                    var dailyData = await query
                        .GroupBy(t => t.CreatedAt.Date)
                        .Select(g => new
                        {
                            Date = g.Key,
                            TotalTransactions = g.Count(),
                            CreditsUsed = g.Sum(t => t.CreditsUsed),
                            UniquePatients = g.Select(t => t.UserPlan.UserId).Distinct().Count(),
                            ActiveClinics = g.Select(t => t.ClinicId).Distinct().Count()
                        })
                        .OrderBy(x => x.Date)
                        .ToListAsync(cancellationToken);

                    foreach (var item in dailyData)
                    {
                        periodData.Add(new UsagePeriodData
                        {
                            Date = item.Date,
                            PeriodLabel = item.Date.ToString("yyyy-MM-dd"),
                            TotalTransactions = item.TotalTransactions,
                            CreditsUsed = item.CreditsUsed,
                            UniquePatients = item.UniquePatients,
                            ActiveClinics = item.ActiveClinics,
                            AverageCreditsPerTransaction = item.TotalTransactions > 0 ? 
                                (decimal)item.CreditsUsed / item.TotalTransactions : 0
                        });
                    }
                    break;

                case ReportPeriod.Weekly:
                    var weeklyData = await query
                        .GroupBy(t => new { 
                            Year = t.CreatedAt.Year,
                            // Using ISO week calculation for PostgreSQL
                            Week = ((t.CreatedAt.DayOfYear - ((int)t.CreatedAt.DayOfWeek + 6) % 7 + 9) / 7)
                        })
                        .Select(g => new
                        {
                            Year = g.Key.Year,
                            Week = g.Key.Week,
                            TotalTransactions = g.Count(),
                            CreditsUsed = g.Sum(t => t.CreditsUsed),
                            UniquePatients = g.Select(t => t.UserPlan.UserId).Distinct().Count(),
                            ActiveClinics = g.Select(t => t.ClinicId).Distinct().Count(),
                            MinDate = g.Min(t => t.CreatedAt)
                        })
                        .OrderBy(x => x.Year).ThenBy(x => x.Week)
                        .ToListAsync(cancellationToken);

                    foreach (var item in weeklyData)
                    {
                        periodData.Add(new UsagePeriodData
                        {
                            Date = item.MinDate,
                            PeriodLabel = $"{item.Year}-W{item.Week}",
                            TotalTransactions = item.TotalTransactions,
                            CreditsUsed = item.CreditsUsed,
                            UniquePatients = item.UniquePatients,
                            ActiveClinics = item.ActiveClinics,
                            AverageCreditsPerTransaction = item.TotalTransactions > 0 ? 
                                (decimal)item.CreditsUsed / item.TotalTransactions : 0
                        });
                    }
                    break;

                case ReportPeriod.Monthly:
                    var monthlyData = await query
                        .GroupBy(t => new { t.CreatedAt.Year, t.CreatedAt.Month })
                        .Select(g => new
                        {
                            Year = g.Key.Year,
                            Month = g.Key.Month,
                            TotalTransactions = g.Count(),
                            CreditsUsed = g.Sum(t => t.CreditsUsed),
                            UniquePatients = g.Select(t => t.UserPlan.UserId).Distinct().Count(),
                            ActiveClinics = g.Select(t => t.ClinicId).Distinct().Count()
                        })
                        .OrderBy(x => x.Year).ThenBy(x => x.Month)
                        .ToListAsync(cancellationToken);

                    foreach (var item in monthlyData)
                    {
                        var date = new DateTime(item.Year, item.Month, 1);
                        periodData.Add(new UsagePeriodData
                        {
                            Date = date,
                            PeriodLabel = date.ToString("yyyy-MM"),
                            TotalTransactions = item.TotalTransactions,
                            CreditsUsed = item.CreditsUsed,
                            UniquePatients = item.UniquePatients,
                            ActiveClinics = item.ActiveClinics,
                            AverageCreditsPerTransaction = item.TotalTransactions > 0 ? 
                                (decimal)item.CreditsUsed / item.TotalTransactions : 0
                        });
                    }
                    break;

                default:
                    throw new NotImplementedException($"Period {request.Period} not implemented");
            }


            // Calculate growth rates
            for (int i = 1; i < periodData.Count; i++)
            {
                var current = periodData[i];
                var previous = periodData[i - 1];

                if (previous.TotalTransactions > 0)
                {
                    current.GrowthRate = ((decimal)current.TotalTransactions - previous.TotalTransactions) 
                        / previous.TotalTransactions * 100;
                }
            }

            return periodData;
        }

        private async Task<List<UsageByClinic>> GetTopClinicsUsage(
            IQueryable<Transaction> query, 
            CancellationToken cancellationToken)
        {
            var totalTransactions = await query.CountAsync(cancellationToken);

            var clinicData = await query
                .GroupBy(t => new { t.ClinicId, t.Clinic.Name, t.Clinic.Type })
                .Select(g => new UsageByClinic
                {
                    ClinicId = g.Key.ClinicId,
                    ClinicName = g.Key.Name,
                    ClinicType = g.Key.Type.ToString(),
                    TotalTransactions = g.Count(),
                    CreditsUsed = g.Sum(t => t.CreditsUsed),
                    UniquePatients = g.Select(t => t.UserPlan.UserId).Distinct().Count()
                })
                .OrderByDescending(c => c.TotalTransactions)
                .Take(10)
                .ToListAsync(cancellationToken);

            // Calculate market share
            foreach (var clinic in clinicData)
            {
                clinic.MarketShare = totalTransactions > 0 ? 
                    (decimal)clinic.TotalTransactions / totalTransactions * 100 : 0;
            }

            return clinicData;
        }

        private async Task<List<UsageByPlan>> GetPlanDistribution(
            IQueryable<Transaction> query, 
            CancellationToken cancellationToken)
        {
            return await query
                .GroupBy(t => new { t.UserPlan.PlanId, t.UserPlan.Plan.Name })
                .Select(g => new UsageByPlan
                {
                    PlanId = g.Key.PlanId,
                    PlanName = g.Key.Name,
                    ActiveUsers = g.Select(t => t.UserPlan.UserId).Distinct().Count(),
                    TotalCreditsUsed = g.Sum(t => t.CreditsUsed),
                    AverageUsagePerUser = g.Count() > 0 ? 
                        (decimal)g.Sum(t => t.CreditsUsed) / g.Select(t => t.UserPlan.UserId).Distinct().Count() : 0
                })
                .OrderByDescending(p => p.TotalCreditsUsed)
                .ToListAsync(cancellationToken);
        }

        private UsageTrend CalculateUsageTrend(List<UsagePeriodData> periodData)
        {
            if (!periodData.Any())
            {
                return new UsageTrend();
            }

            var totalDays = (periodData.Last().Date - periodData.First().Date).TotalDays + 1;
            var totalTransactions = periodData.Sum(p => p.TotalTransactions);

            var trend = new UsageTrend
            {
                AverageDailyTransactions = totalDays > 0 ? (decimal)totalTransactions / (decimal)totalDays : 0
            };

            // Calculate overall growth rate
            if (periodData.Count >= 2)
            {
                var firstPeriod = periodData.First();
                var lastPeriod = periodData.Last();
                
                if (firstPeriod.TotalTransactions > 0)
                {
                    trend.OverallGrowthRate = ((decimal)lastPeriod.TotalTransactions - firstPeriod.TotalTransactions) 
                        / firstPeriod.TotalTransactions * 100;
                }

                // Determine trend direction
                trend.TrendDirection = trend.OverallGrowthRate switch
                {
                    > 10 => "up",
                    < -10 => "down",
                    _ => "stable"
                };
            }

            // Find peak usage
            var peakDay = periodData.OrderByDescending(p => p.TotalTransactions).FirstOrDefault();
            if (peakDay != null)
            {
                trend.PeakUsageDay = peakDay.TotalTransactions;
                trend.PeakUsageDate = peakDay.Date.ToString("yyyy-MM-dd");
            }

            return trend;
        }

        private ChartData GenerateUsageChartData(List<UsagePeriodData> periodData)
        {
            return new ChartData
            {
                ChartType = "line",
                Labels = periodData.Select(p => p.PeriodLabel).ToList(),
                Datasets = new List<ChartDataset>
                {
                    new ChartDataset
                    {
                        Label = "Transações",
                        Data = periodData.Select(p => (decimal)p.TotalTransactions).ToList(),
                        BorderColor = "#1976d2",
                        BackgroundColor = "rgba(25, 118, 210, 0.1)",
                        Fill = true
                    },
                    new ChartDataset
                    {
                        Label = "Créditos Usados",
                        Data = periodData.Select(p => (decimal)p.CreditsUsed).ToList(),
                        BorderColor = "#388e3c",
                        BackgroundColor = "rgba(56, 142, 60, 0.1)",
                        Fill = true
                    }
                },
                Options = new ChartOptions
                {
                    Responsive = true,
                    MaintainAspectRatio = false,
                    Title = "Tendência de Uso"
                }
            };
        }

        private async Task<List<ClinicRankingItem>> GetClinicMetrics(
            ReportRequest request, 
            CancellationToken cancellationToken)
        {
            var clinicData = await _context.Clinics
                .AsNoTracking()
                .Select(c => new ClinicRankingItem
                {
                    ClinicId = c.Id,
                    ClinicName = c.Name,
                    ClinicType = c.Type.ToString(),
                    Location = c.Address ?? "N/A",
                    Metrics = new ClinicMetrics
                    {
                        TotalTransactions = c.Transactions
                            .Where(t => t.CreatedAt >= request.StartDate && 
                                       t.CreatedAt <= request.EndDate)
                            .Count(),
                        CreditsProcessed = c.Transactions
                            .Where(t => t.CreatedAt >= request.StartDate && 
                                       t.CreatedAt <= request.EndDate)
                            .Sum(t => t.CreditsUsed),
                        UniquePatients = c.Transactions
                            .Where(t => t.CreatedAt >= request.StartDate && 
                                       t.CreatedAt <= request.EndDate)
                            .Select(t => t.UserPlan.UserId)
                            .Distinct()
                            .Count(),
                        DaysActive = (int)(request.EndDate - c.CreatedAt).TotalDays
                    }
                })
                .ToListAsync(cancellationToken);

            // Calculate additional metrics
            foreach (var clinic in clinicData)
            {
                var metrics = clinic.Metrics;
                
                metrics.AverageTransactionValue = metrics.TotalTransactions > 0 ?
                    (decimal)metrics.CreditsProcessed / metrics.TotalTransactions : 0;
                
                metrics.AverageDailyTransactions = metrics.DaysActive > 0 ?
                    (decimal)metrics.TotalTransactions / metrics.DaysActive : 0;

                // Calculate composite score for ranking
                clinic.Score = CalculateClinicScore(metrics);
            }

            return clinicData;
        }

        private decimal CalculateClinicScore(ClinicMetrics metrics)
        {
            // Weighted scoring algorithm
            var weights = new Dictionary<string, decimal>
            {
                ["transactions"] = 0.3m,
                ["credits"] = 0.2m,
                ["patients"] = 0.2m,
                ["avgTransaction"] = 0.15m,
                ["dailyAvg"] = 0.15m
            };

            var score = 
                (metrics.TotalTransactions * weights["transactions"]) +
                (metrics.CreditsProcessed * weights["credits"] / 100) + // Normalize by dividing by 100
                (metrics.UniquePatients * weights["patients"]) +
                (metrics.AverageTransactionValue * weights["avgTransaction"]) +
                (metrics.AverageDailyTransactions * weights["dailyAvg"] * 10); // Scale up

            return Math.Round(score, 2);
        }

        private List<ClinicRankingItem> CalculateClinicRankings(List<ClinicRankingItem> clinicData)
        {
            // Sort by score descending
            var ranked = clinicData
                .OrderByDescending(c => c.Score)
                .ThenByDescending(c => c.Metrics.TotalTransactions)
                .ToList();

            // Assign ranks
            for (int i = 0; i < ranked.Count; i++)
            {
                ranked[i].Rank = i + 1;
                ranked[i].PreviousRank = i + 1; // For now, same as current
                ranked[i].RankChange = "same";
            }

            return ranked;
        }

        private List<ClinicGrowthData> GetGrowthLeaders(List<ClinicRankingItem> clinicData)
        {
            return clinicData
                .Where(c => c.Metrics.GrowthRate > 0)
                .OrderByDescending(c => c.Metrics.GrowthRate)
                .Take(5)
                .Select(c => new ClinicGrowthData
                {
                    ClinicId = c.ClinicId,
                    ClinicName = c.ClinicName,
                    GrowthRate = c.Metrics.GrowthRate,
                    TransactionIncrease = 0, // Would need previous period data
                    NewPatientsAdded = 0, // Would need previous period data
                    GrowthCategory = c.Metrics.GrowthRate switch
                    {
                        > 50 => "rapid",
                        > 25 => "fast",
                        > 10 => "steady",
                        _ => "slow"
                    }
                })
                .ToList();
        }

        private ClinicPerformanceMetrics CalculateOverallClinicMetrics(List<ClinicRankingItem> clinicData)
        {
            var activeClinicData = clinicData.Where(c => c.Metrics.TotalTransactions > 0).ToList();

            var metrics = new ClinicPerformanceMetrics
            {
                TotalActiveClinics = activeClinicData.Count,
                NewClinicsThisPeriod = 0, // Would need to check creation dates
                AverageTransactionsPerClinic = activeClinicData.Any() ?
                    (decimal)activeClinicData.Average(c => c.Metrics.TotalTransactions) : 0,
                MedianTransactionsPerClinic = activeClinicData.Any() ?
                    activeClinicData.OrderBy(c => c.Metrics.TotalTransactions)
                        .ElementAt(activeClinicData.Count / 2).Metrics.TotalTransactions : 0
            };

            // Calculate top performers threshold (top 20%)
            if (activeClinicData.Any())
            {
                var topIndex = Math.Max(1, (int)(activeClinicData.Count * 0.2));
                metrics.TopPerformersThreshold = activeClinicData
                    .OrderByDescending(c => c.Metrics.TotalTransactions)
                    .ElementAt(topIndex - 1)
                    .Metrics.TotalTransactions;
            }

            // Count by type
            metrics.ClinicsByType = clinicData
                .GroupBy(c => c.ClinicType)
                .ToDictionary(g => g.Key, g => g.Count());

            return metrics;
        }

        private ChartData GenerateClinicRankingChartData(List<ClinicRankingItem> topClinics)
        {
            return new ChartData
            {
                ChartType = "bar",
                Labels = topClinics.Select(c => c.ClinicName).ToList(),
                Datasets = new List<ChartDataset>
                {
                    new ChartDataset
                    {
                        Label = "Transações",
                        Data = topClinics.Select(c => (decimal)c.Metrics.TotalTransactions).ToList(),
                        BackgroundColor = "#1976d2",
                        BorderColor = "#0d47a1",
                        BorderWidth = 1
                    },
                    new ChartDataset
                    {
                        Label = "Créditos Processados",
                        Data = topClinics.Select(c => (decimal)c.Metrics.CreditsProcessed).ToList(),
                        BackgroundColor = "#388e3c",
                        BorderColor = "#1b5e20",
                        BorderWidth = 1
                    }
                },
                Options = new ChartOptions
                {
                    Responsive = true,
                    MaintainAspectRatio = false,
                    Title = "Top 10 Clínicas por Performance"
                }
            };
        }

        private async Task<List<ServiceUsageItem>> GetTopServicesAsync(
            IQueryable<Transaction> query, 
            CancellationToken cancellationToken)
        {
            var totalTransactions = await query.CountAsync(cancellationToken);

            var serviceData = await query
                .Where(t => !string.IsNullOrEmpty(t.ServiceType))
                .GroupBy(t => t.ServiceType)
                .Select(g => new
                {
                    ServiceType = g.Key,
                    UsageCount = g.Count(),
                    TotalCreditsUsed = g.Sum(t => t.CreditsUsed),
                    UniquePatients = g.Select(t => t.UserPlan.UserId).Distinct().Count(),
                    TopClinics = g.GroupBy(t => new { t.ClinicId, t.Clinic.Name })
                        .OrderByDescending(cg => cg.Count())
                        .Take(3)
                        .Select(cg => cg.Key.Name)
                        .ToList()
                })
                .OrderByDescending(s => s.UsageCount)
                .ToListAsync(cancellationToken);

            // Calculate market share and growth
            var result = serviceData.Select(s => new ServiceUsageItem
            {
                ServiceType = s.ServiceType!,
                ServiceName = GetServiceDisplayName(s.ServiceType!),
                Category = GetServiceCategory(s.ServiceType!),
                UsageCount = s.UsageCount,
                TotalCreditsUsed = s.TotalCreditsUsed,
                AverageCreditsPerUse = s.UsageCount > 0 ? (decimal)s.TotalCreditsUsed / s.UsageCount : 0,
                MarketShare = totalTransactions > 0 ? (decimal)s.UsageCount / totalTransactions * 100 : 0,
                UniquePatients = s.UniquePatients,
                TopClinics = s.TopClinics,
                GrowthRate = 0 // TODO: Calculate based on previous period
            }).ToList();

            return result;
        }

        private async Task<ServiceDistribution> GetServiceDistributionAsync(
            IQueryable<Transaction> query, 
            CancellationToken cancellationToken)
        {
            var services = await query
                .Where(t => !string.IsNullOrEmpty(t.ServiceType))
                .Select(t => t.ServiceType)
                .Distinct()
                .ToListAsync(cancellationToken);

            var categoryCounts = services
                .GroupBy(s => GetServiceCategory(s!))
                .ToDictionary(g => g.Key, g => g.Count());

            var totalServices = services.Count;
            var categoryPercentages = categoryCounts
                .ToDictionary(kv => kv.Key, kv => totalServices > 0 ? (decimal)kv.Value / totalServices * 100 : 0);

            // Calculate concentration index (simplified Herfindahl index)
            var serviceUsageCounts = await query
                .Where(t => !string.IsNullOrEmpty(t.ServiceType))
                .GroupBy(t => t.ServiceType)
                .Select(g => g.Count())
                .ToListAsync(cancellationToken);

            var totalUsage = serviceUsageCounts.Sum();
            var concentrationIndex = 0m;
            if (totalUsage > 0)
            {
                foreach (var count in serviceUsageCounts)
                {
                    var marketShare = (decimal)count / totalUsage;
                    concentrationIndex += marketShare * marketShare;
                }
            }

            return new ServiceDistribution
            {
                ByCategory = categoryCounts,
                CategoryPercentages = categoryPercentages,
                ByPriceRange = new Dictionary<string, int>(), // TODO: Implement if price data available
                TotalUniqueServices = totalServices,
                ConcentrationIndex = concentrationIndex
            };
        }

        private async Task<List<ServiceTrend>> GetServiceTrendsAsync(
            IQueryable<Transaction> query, 
            ReportRequest request,
            CancellationToken cancellationToken)
        {
            // Get top 5 services for trend analysis
            var topServices = await query
                .Where(t => !string.IsNullOrEmpty(t.ServiceType))
                .GroupBy(t => t.ServiceType)
                .OrderByDescending(g => g.Count())
                .Take(5)
                .Select(g => g.Key)
                .ToListAsync(cancellationToken);

            var trends = new List<ServiceTrend>();

            foreach (var service in topServices)
            {
                var trendData = await GetServiceTrendData(query, service!, request, cancellationToken);
                
                // Calculate trend direction
                var trendDirection = "stable";
                var projectedGrowth = 0m;

                if (trendData.Count >= 2)
                {
                    var firstHalf = trendData.Take(trendData.Count / 2).Average(t => t.Count);
                    var secondHalf = trendData.Skip(trendData.Count / 2).Average(t => t.Count);
                    
                    if (secondHalf > firstHalf * 1.1)
                        trendDirection = "up";
                    else if (secondHalf < firstHalf * 0.9)
                        trendDirection = "down";

                    // Simple linear projection
                    if (trendData.Count >= 3)
                    {
                        var lastThree = trendData.TakeLast(3).Select(t => t.Count).ToList();
                        var avgGrowth = (lastThree[2] - lastThree[0]) / 2.0m;
                        projectedGrowth = (decimal)(lastThree[2] + avgGrowth);
                    }
                }

                trends.Add(new ServiceTrend
                {
                    ServiceType = service!,
                    TrendData = trendData,
                    TrendDirection = trendDirection,
                    ProjectedGrowth = projectedGrowth
                });
            }

            return trends;
        }

        private async Task<List<TrendPoint>> GetServiceTrendData(
            IQueryable<Transaction> query,
            string serviceType,
            ReportRequest request,
            CancellationToken cancellationToken)
        {
            var serviceQuery = query.Where(t => t.ServiceType == serviceType);

            // Group by period based on request
            switch (request.Period)
            {
                case ReportPeriod.Daily:
                    return await serviceQuery
                        .GroupBy(t => t.CreatedAt.Date)
                        .Select(g => new TrendPoint
                        {
                            Date = g.Key,
                            Count = g.Count(),
                            Value = g.Sum(t => t.CreditsUsed)
                        })
                        .OrderBy(t => t.Date)
                        .ToListAsync(cancellationToken);

                case ReportPeriod.Weekly:
                    var weeklyData = await serviceQuery
                        .GroupBy(t => new 
                        { 
                            Year = t.CreatedAt.Year,
                            Week = ((t.CreatedAt.DayOfYear - ((int)t.CreatedAt.DayOfWeek + 6) % 7 + 9) / 7)
                        })
                        .Select(g => new
                        {
                            Year = g.Key.Year,
                            Week = g.Key.Week,
                            Count = g.Count(),
                            Value = g.Sum(t => t.CreditsUsed),
                            MinDate = g.Min(t => t.CreatedAt)
                        })
                        .ToListAsync(cancellationToken);

                    return weeklyData.Select(d => new TrendPoint
                    {
                        Date = d.MinDate,
                        Count = d.Count,
                        Value = d.Value
                    }).OrderBy(t => t.Date).ToList();

                case ReportPeriod.Monthly:
                default:
                    return await serviceQuery
                        .GroupBy(t => new { t.CreatedAt.Year, t.CreatedAt.Month })
                        .Select(g => new TrendPoint
                        {
                            Date = new DateTime(g.Key.Year, g.Key.Month, 1),
                            Count = g.Count(),
                            Value = g.Sum(t => t.CreditsUsed)
                        })
                        .OrderBy(t => t.Date)
                        .ToListAsync(cancellationToken);
            }
        }

        private ServiceInsights GenerateServiceInsights(
            List<ServiceUsageItem> topServices, 
            List<ServiceTrend> trends,
            ServiceDistribution distribution)
        {
            var insights = new ServiceInsights();

            // Identify emerging services (high growth rate)
            insights.EmergingServices = topServices
                .Where(s => s.GrowthRate > 20)
                .OrderByDescending(s => s.GrowthRate)
                .Take(3)
                .Select(s => s.ServiceType)
                .ToList();

            // Identify declining services
            insights.DecliningServices = topServices
                .Where(s => s.GrowthRate < -10)
                .OrderBy(s => s.GrowthRate)
                .Take(3)
                .Select(s => s.ServiceType)
                .ToList();

            // Calculate seasonality scores (simplified)
            foreach (var trend in trends)
            {
                if (trend.TrendData.Count >= 4)
                {
                    var variance = CalculateVariance(trend.TrendData.Select(t => (double)t.Count).ToList());
                    var mean = trend.TrendData.Average(t => t.Count);
                    var seasonalityScore = mean > 0 ? (decimal)(variance / mean) : 0;
                    insights.SeasonalPatterns[trend.ServiceType] = seasonalityScore;
                }
            }

            // Generate recommendations
            insights.Recommendations = GenerateServiceRecommendations(topServices, distribution, insights);

            return insights;
        }

        private List<string> GenerateServiceRecommendations(
            List<ServiceUsageItem> topServices,
            ServiceDistribution distribution,
            ServiceInsights insights)
        {
            var recommendations = new List<string>();

            // High concentration recommendation
            if (distribution.ConcentrationIndex > 0.5m)
            {
                recommendations.Add("Service usage is highly concentrated. Consider promoting underutilized services.");
            }

            // Emerging services recommendation
            if (insights.EmergingServices.Any())
            {
                recommendations.Add($"Services showing high growth: {string.Join(", ", insights.EmergingServices.Take(3))}. Consider increasing capacity.");
            }

            // Declining services recommendation
            if (insights.DecliningServices.Any())
            {
                recommendations.Add($"Services showing decline: {string.Join(", ", insights.DecliningServices.Take(3))}. Review service quality or pricing.");
            }

            // Efficiency recommendation
            var highCreditServices = topServices.Where(s => s.AverageCreditsPerUse > 5).ToList();
            if (highCreditServices.Any())
            {
                recommendations.Add($"High-credit services: {string.Join(", ", highCreditServices.Take(3).Select(s => s.ServiceType))}. Monitor for appropriate usage.");
            }

            return recommendations;
        }

        private async Task<List<PlanUtilizationItem>> GetPlanUtilizationDataAsync(
            ReportRequest request,
            CancellationToken cancellationToken)
        {
            var plans = await _context.Plans
                .AsNoTracking()
                .Include(p => p.UserPlans)
                .ThenInclude(up => up.Transactions)
                .Where(p => p.IsActive)
                .ToListAsync(cancellationToken);

            var utilizationData = new List<PlanUtilizationItem>();

            foreach (var plan in plans)
            {
                var userPlans = plan.UserPlans
                    .Where(up => up.CreatedAt <= request.EndDate);

                var activeUserPlans = userPlans
                    .Where(up => up.Transactions.Any(t => 
                        t.CreatedAt >= request.StartDate && 
                        t.CreatedAt <= request.EndDate));

                var transactions = userPlans
                    .SelectMany(up => up.Transactions)
                    .Where(t => t.CreatedAt >= request.StartDate && 
                               t.CreatedAt <= request.EndDate);

                var totalCreditsUsed = transactions.Sum(t => t.CreditsUsed);
                var totalCreditsAvailable = userPlans.Sum(up => up.Credits);
                var totalCreditsExpired = userPlans
                    .Where(up => up.ExpiresAt < DateTime.UtcNow && up.ExpiresAt >= request.StartDate)
                    .Sum(up => up.CreditsRemaining);

                // Calculate monthly breakdown
                var monthlyBreakdown = await GetMonthlyBreakdown(plan.Id, request, cancellationToken);

                // Calculate average time between uses
                var transactionDates = transactions
                    .OrderBy(t => t.CreatedAt)
                    .Select(t => t.CreatedAt)
                    .ToList();

                var avgTimeBetweenUses = TimeSpan.Zero;
                if (transactionDates.Count > 1)
                {
                    var totalTime = TimeSpan.Zero;
                    for (int i = 1; i < transactionDates.Count; i++)
                    {
                        totalTime += transactionDates[i] - transactionDates[i - 1];
                    }
                    avgTimeBetweenUses = TimeSpan.FromMilliseconds(totalTime.TotalMilliseconds / (transactionDates.Count - 1));
                }

                var usage = new PlanUsageMetrics
                {
                    ActiveUsers = activeUserPlans.Count(),
                    TotalUsers = userPlans.Count(),
                    TotalCreditsUsed = totalCreditsUsed,
                    TotalCreditsExpired = totalCreditsExpired,
                    TotalCreditsAvailable = totalCreditsAvailable,
                    AverageCreditsPerUser = activeUserPlans.Any() ? 
                        (decimal)totalCreditsUsed / activeUserPlans.Count() : 0,
                    AverageTimeBetweenUses = avgTimeBetweenUses
                };

                // Calculate efficiency metrics
                var efficiency = CalculatePlanEfficiency(plan, userPlans.ToList(), usage);

                utilizationData.Add(new PlanUtilizationItem
                {
                    PlanId = plan.Id,
                    PlanName = plan.Name,
                    TotalCredits = plan.Credits,
                    Price = plan.Price,
                    Usage = usage,
                    Efficiency = efficiency,
                    MonthlyBreakdown = monthlyBreakdown
                });
            }

            return utilizationData;
        }

        private PlanEfficiency CalculatePlanEfficiency(Plan plan, List<UserPlan> userPlans, PlanUsageMetrics usage)
        {
            var efficiency = new PlanEfficiency();

            // Credit efficiency (used vs expired)
            var totalCreditsIssued = usage.TotalCreditsUsed + usage.TotalCreditsExpired + 
                                   userPlans.Where(up => up.ExpiresAt > DateTime.UtcNow).Sum(up => up.CreditsRemaining);
            
            efficiency.CreditEfficiency = totalCreditsIssued > 0 ? 
                (decimal)usage.TotalCreditsUsed / totalCreditsIssued * 100 : 0;

            // Value per credit
            efficiency.ValuePerCredit = usage.TotalCreditsUsed > 0 ? 
                plan.Price / usage.TotalCreditsUsed : 0;

            // Churn rate (simplified - users who didn't renew)
            var expiredUserPlans = userPlans.Where(up => up.ExpiresAt < DateTime.UtcNow).ToList();
            if (expiredUserPlans.Any())
            {
                var renewedCount = expiredUserPlans.Count(up => 
                    userPlans.Any(up2 => up2.UserId == up.UserId && up2.CreatedAt > up.ExpiresAt));
                
                efficiency.RenewalRate = (decimal)renewedCount / expiredUserPlans.Count * 100;
                efficiency.ChurnRate = 100 - efficiency.RenewalRate;
            }

            // Average days to full utilization
            var fullyUtilizedPlans = userPlans
                .Where(up => up.CreditsRemaining == 0)
                .ToList();

            if (fullyUtilizedPlans.Any())
            {
                var totalDays = fullyUtilizedPlans
                    .Select(up => (up.UpdatedAt - up.CreatedAt).TotalDays)
                    .Average();
                
                efficiency.AverageDaysToFullUtilization = (int)totalDays;
            }

            // ROI calculation (simplified)
            efficiency.ROI = efficiency.CreditEfficiency * efficiency.RenewalRate / 100;

            return efficiency;
        }

        private async Task<List<UsageByMonth>> GetMonthlyBreakdown(
            Guid planId,
            ReportRequest request,
            CancellationToken cancellationToken)
        {
            var monthlyData = await _context.Transactions
                .AsNoTracking()
                .Where(t => t.UserPlan.PlanId == planId &&
                           t.CreatedAt >= request.StartDate &&
                           t.CreatedAt <= request.EndDate)
                .GroupBy(t => new { t.CreatedAt.Year, t.CreatedAt.Month })
                .Select(g => new UsageByMonth
                {
                    Year = g.Key.Year,
                    Month = g.Key.Month,
                    MonthName = new DateTime(g.Key.Year, g.Key.Month, 1).ToString("MMMM"),
                    CreditsUsed = g.Sum(t => t.CreditsUsed),
                    ActiveUsers = g.Select(t => t.UserPlan.UserId).Distinct().Count()
                })
                .OrderBy(m => m.Year).ThenBy(m => m.Month)
                .ToListAsync(cancellationToken);

            return monthlyData;
        }

        private UtilizationSummary CalculateUtilizationSummary(List<PlanUtilizationItem> planData)
        {
            var summary = new UtilizationSummary();

            if (!planData.Any())
                return summary;

            // Overall utilization rate
            var totalCreditsUsed = planData.Sum(p => p.Usage.TotalCreditsUsed);
            var totalCreditsAvailable = planData.Sum(p => p.Usage.TotalCreditsAvailable);
            summary.OverallUtilizationRate = totalCreditsAvailable > 0 ? 
                (decimal)totalCreditsUsed / totalCreditsAvailable * 100 : 0;

            // Average utilization per plan
            summary.AverageUtilizationPerPlan = planData.Average(p => p.Usage.UtilizationRate * 100);

            // Most/least efficient plans
            var orderedByEfficiency = planData.OrderByDescending(p => p.Efficiency.CreditEfficiency).ToList();
            summary.MostEfficientPlan = orderedByEfficiency.FirstOrDefault()?.PlanName ?? "N/A";
            summary.LeastEfficientPlan = orderedByEfficiency.LastOrDefault()?.PlanName ?? "N/A";

            // Waste metrics
            summary.TotalCreditsWasted = planData.Sum(p => p.Usage.TotalCreditsExpired);
            var totalCreditsIssued = totalCreditsUsed + summary.TotalCreditsWasted + 
                                   planData.Sum(p => p.Usage.TotalCreditsAvailable - p.Usage.TotalCreditsUsed);
            summary.WastePercentage = totalCreditsIssued > 0 ? 
                summary.TotalCreditsWasted / totalCreditsIssued * 100 : 0;

            // Utilization by plan type
            summary.UtilizationByPlanType = planData
                .GroupBy(p => p.TotalCredits <= 10 ? "Basic" : p.TotalCredits <= 50 ? "Standard" : "Premium")
                .ToDictionary(g => g.Key, g => g.Average(p => p.Usage.UtilizationRate * 100));

            return summary;
        }

        private List<UtilizationPattern> IdentifyUtilizationPatterns(List<PlanUtilizationItem> planData)
        {
            var patterns = new List<UtilizationPattern>();

            // Pattern 1: Underutilization
            var underutilizedPlans = planData.Where(p => p.Usage.UtilizationRate < 0.5m).ToList();
            if (underutilizedPlans.Any())
            {
                patterns.Add(new UtilizationPattern
                {
                    PatternName = "Underutilization",
                    Description = "Plans with less than 50% credit utilization",
                    AffectedPlans = underutilizedPlans.Select(p => p.PlanId).ToList(),
                    AffectedUsers = underutilizedPlans.Sum(p => p.Usage.TotalUsers),
                    Recommendation = "Consider smaller plan options or usage reminders"
                });
            }

            // Pattern 2: Early depletion
            var earlyDepletionPlans = planData.Where(p => 
                p.Efficiency.AverageDaysToFullUtilization > 0 && 
                p.Efficiency.AverageDaysToFullUtilization < 20).ToList();
            
            if (earlyDepletionPlans.Any())
            {
                patterns.Add(new UtilizationPattern
                {
                    PatternName = "Early Depletion",
                    Description = "Plans exhausted in less than 20 days",
                    AffectedPlans = earlyDepletionPlans.Select(p => p.PlanId).ToList(),
                    AffectedUsers = earlyDepletionPlans.Sum(p => p.Usage.ActiveUsers),
                    Recommendation = "Consider larger plan options or usage limits"
                });
            }

            // Pattern 3: Inactive users
            var inactivePlans = planData.Where(p => 
                p.Usage.ActivationRate < 0.7m && p.Usage.TotalUsers > 10).ToList();
            
            if (inactivePlans.Any())
            {
                patterns.Add(new UtilizationPattern
                {
                    PatternName = "Low Activation",
                    Description = "Plans with less than 70% user activation",
                    AffectedPlans = inactivePlans.Select(p => p.PlanId).ToList(),
                    AffectedUsers = inactivePlans.Sum(p => p.Usage.TotalUsers - p.Usage.ActiveUsers),
                    Recommendation = "Implement onboarding campaigns or activation incentives"
                });
            }

            // Pattern 4: High churn
            var highChurnPlans = planData.Where(p => p.Efficiency.ChurnRate > 30).ToList();
            if (highChurnPlans.Any())
            {
                patterns.Add(new UtilizationPattern
                {
                    PatternName = "High Churn",
                    Description = "Plans with more than 30% churn rate",
                    AffectedPlans = highChurnPlans.Select(p => p.PlanId).ToList(),
                    AffectedUsers = highChurnPlans.Sum(p => p.Usage.TotalUsers),
                    Recommendation = "Review plan value proposition and user satisfaction"
                });
            }

            return patterns;
        }

        private PlanEfficiencyMetrics CalculatePlanEfficiencyMetrics(List<PlanUtilizationItem> planData)
        {
            var metrics = new PlanEfficiencyMetrics();

            if (!planData.Any())
                return metrics;

            // Average credit efficiency
            metrics.AverageCreditEfficiency = planData.Average(p => p.Efficiency.CreditEfficiency);

            // Optimal utilization threshold (based on data)
            var efficientPlans = planData
                .Where(p => p.Efficiency.RenewalRate > 70 && p.Efficiency.ChurnRate < 20)
                .ToList();
            
            metrics.OptimalUtilizationThreshold = efficientPlans.Any() ? 
                efficientPlans.Average(p => p.Usage.UtilizationRate * 100) : 75m;

            // Underutilized plans
            metrics.UnderutilizedPlans = planData
                .Where(p => p.Usage.UtilizationRate < 0.5m)
                .Select(p => p.PlanName)
                .ToList();

            // Overutilized plans
            metrics.OverutilizedPlans = planData
                .Where(p => p.Efficiency.AverageDaysToFullUtilization > 0 && 
                           p.Efficiency.AverageDaysToFullUtilization < 15)
                .Select(p => p.PlanName)
                .ToList();

            // Efficiency trends (simplified - comparing to previous metrics if available)
            metrics.EfficiencyTrends = planData
                .ToDictionary(p => p.PlanName, p => 
                    p.Efficiency.CreditEfficiency > metrics.AverageCreditEfficiency ? 1m : -1m);

            return metrics;
        }

        private ChartData GenerateServiceChartData(List<ServiceUsageItem> topServices)
        {
            return new ChartData
            {
                ChartType = "bar",
                Labels = topServices.Select(s => s.ServiceName).ToList(),
                Datasets = new List<ChartDataset>
                {
                    new ChartDataset
                    {
                        Label = "Uso do Serviço",
                        Data = topServices.Select(s => (decimal)s.UsageCount).ToList(),
                        BackgroundColor = "#2196f3",
                        BorderColor = "#1976d2",
                        BorderWidth = 1
                    },
                    new ChartDataset
                    {
                        Label = "Créditos Utilizados",
                        Data = topServices.Select(s => (decimal)s.TotalCreditsUsed).ToList(),
                        BackgroundColor = "#4caf50",
                        BorderColor = "#388e3c",
                        BorderWidth = 1
                    }
                },
                Options = new ChartOptions
                {
                    Responsive = true,
                    MaintainAspectRatio = false,
                    Title = "Top Serviços por Utilização"
                }
            };
        }

        private ChartData GeneratePlanUtilizationChartData(List<PlanUtilizationItem> planData)
        {
            return new ChartData
            {
                ChartType = "doughnut",
                Labels = planData.Select(p => p.PlanName).ToList(),
                Datasets = new List<ChartDataset>
                {
                    new ChartDataset
                    {
                        Label = "Taxa de Utilização",
                        Data = planData.Select(p => Math.Round(p.Usage.UtilizationRate * 100, 2)).ToList(),
                        BackgroundColor = GenerateColors(planData.Count),
                        BorderColor = "#ffffff",
                        BorderWidth = 2
                    }
                },
                Options = new ChartOptions
                {
                    Responsive = true,
                    MaintainAspectRatio = false,
                    Title = "Utilização de Planos (%)"
                }
            };
        }

        private string GetServiceDisplayName(string serviceType)
        {
            // Map internal service types to display names
            return serviceType switch
            {
                "consultation" => "Consulta",
                "exam" => "Exame",
                "procedure" => "Procedimento",
                "therapy" => "Terapia",
                _ => serviceType
            };
        }

        private string GetServiceCategory(string serviceType)
        {
            // Categorize services
            return serviceType switch
            {
                "consultation" => "Consultas",
                "exam" or "lab_test" => "Exames",
                "procedure" or "surgery" => "Procedimentos",
                "therapy" or "physiotherapy" => "Terapias",
                _ => "Outros"
            };
        }

        private double CalculateVariance(List<double> values)
        {
            if (values.Count < 2)
                return 0;

            var mean = values.Average();
            var variance = values.Sum(v => Math.Pow(v - mean, 2)) / values.Count;
            return variance;
        }

        private List<string> GenerateColors(int count)
        {
            var colors = new[]
            {
                "#2196f3", "#4caf50", "#ff9800", "#f44336", "#9c27b0",
                "#00bcd4", "#8bc34a", "#ffc107", "#e91e63", "#673ab7"
            };

            var result = new List<string>();
            for (int i = 0; i < count; i++)
            {
                result.Add(colors[i % colors.Length]);
            }
            return result;
        }

        #endregion
    }
}