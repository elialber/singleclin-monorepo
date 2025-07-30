namespace SingleClin.API.DTOs.Report
{
    /// <summary>
    /// Base response for all report types
    /// </summary>
    public class ReportResponse<T> where T : class
    {
        /// <summary>
        /// Report type
        /// </summary>
        public ReportType Type { get; set; }

        /// <summary>
        /// Report title
        /// </summary>
        public string Title { get; set; } = string.Empty;

        /// <summary>
        /// Report description
        /// </summary>
        public string Description { get; set; } = string.Empty;

        /// <summary>
        /// Generation timestamp
        /// </summary>
        public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Report period information
        /// </summary>
        public ReportPeriodInfo Period { get; set; } = new();

        /// <summary>
        /// Applied filters
        /// </summary>
        public ReportFilters Filters { get; set; } = new();

        /// <summary>
        /// Report data
        /// </summary>
        public T Data { get; set; } = null!;

        /// <summary>
        /// Summary statistics
        /// </summary>
        public ReportSummary Summary { get; set; } = new();

        /// <summary>
        /// Chart data for visualization
        /// </summary>
        public ChartData? ChartData { get; set; }

        /// <summary>
        /// Pagination information
        /// </summary>
        public PaginationInfo? Pagination { get; set; }

        /// <summary>
        /// Execution time in milliseconds
        /// </summary>
        public long ExecutionTimeMs { get; set; }

        /// <summary>
        /// Whether data was served from cache
        /// </summary>
        public bool FromCache { get; set; }

        /// <summary>
        /// Cache expiry time
        /// </summary>
        public DateTime? CacheExpiresAt { get; set; }
    }

    /// <summary>
    /// Report period information
    /// </summary>
    public class ReportPeriodInfo
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public ReportPeriod Period { get; set; }
        public int TotalDays => (int)(EndDate - StartDate).TotalDays + 1;
        public string TimeZone { get; set; } = "America/Sao_Paulo";
    }

    /// <summary>
    /// Applied filters summary
    /// </summary>
    public class ReportFilters
    {
        public List<Guid>? ClinicIds { get; set; }
        public List<Guid>? PlanIds { get; set; }
        public List<string>? ServiceTypes { get; set; }
        public string? SortBy { get; set; }
        public string? SortDirection { get; set; }
    }

    /// <summary>
    /// Report summary statistics
    /// </summary>
    public class ReportSummary
    {
        public int TotalRecords { get; set; }
        public Dictionary<string, decimal> Totals { get; set; } = new();
        public Dictionary<string, decimal> Averages { get; set; } = new();
        public Dictionary<string, object> Metrics { get; set; } = new();
    }

    /// <summary>
    /// Chart data for frontend visualization
    /// </summary>
    public class ChartData
    {
        public string ChartType { get; set; } = "line"; // line, bar, pie, radar
        public List<string> Labels { get; set; } = new();
        public List<ChartDataset> Datasets { get; set; } = new();
        public ChartOptions? Options { get; set; }
    }

    /// <summary>
    /// Chart dataset
    /// </summary>
    public class ChartDataset
    {
        public string Label { get; set; } = string.Empty;
        public List<decimal> Data { get; set; } = new();
        public string? BackgroundColor { get; set; }
        public string? BorderColor { get; set; }
        public int BorderWidth { get; set; } = 1;
        public bool Fill { get; set; } = false;
    }

    /// <summary>
    /// Chart display options
    /// </summary>
    public class ChartOptions
    {
        public bool Responsive { get; set; } = true;
        public bool MaintainAspectRatio { get; set; } = false;
        public string? Title { get; set; }
        public Dictionary<string, object>? CustomOptions { get; set; }
    }

    /// <summary>
    /// Pagination information
    /// </summary>
    public class PaginationInfo
    {
        public int CurrentPage { get; set; }
        public int PageSize { get; set; }
        public int TotalRecords { get; set; }
        public int TotalPages => (int)Math.Ceiling((double)TotalRecords / PageSize);
        public bool HasPrevious => CurrentPage > 1;
        public bool HasNext => CurrentPage < TotalPages;
    }
}