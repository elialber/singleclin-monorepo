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
            // Implementation similar to above methods
            // This is a placeholder for the service report generation
            throw new NotImplementedException("Service report generation will be implemented in the next iteration");
        }

        public async Task<ReportResponse<PlanUtilizationData>> GeneratePlanUtilizationAsync(
            ReportRequest request, 
            CancellationToken cancellationToken = default)
        {
            // Implementation similar to above methods
            // This is a placeholder for the plan utilization report generation
            throw new NotImplementedException("Plan utilization report generation will be implemented in the next iteration");
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

        #endregion
    }
}