using System.ComponentModel.DataAnnotations;

namespace SingleClin.API.DTOs.Report
{
    /// <summary>
    /// Request parameters for report generation
    /// </summary>
    public class ReportRequest
    {
        /// <summary>
        /// Type of report to generate
        /// </summary>
        [Required]
        public ReportType Type { get; set; }

        /// <summary>
        /// Time period aggregation
        /// </summary>
        [Required]
        public ReportPeriod Period { get; set; } = ReportPeriod.Monthly;

        /// <summary>
        /// Start date for the report
        /// </summary>
        [Required]
        public DateTime StartDate { get; set; }

        /// <summary>
        /// End date for the report
        /// </summary>
        [Required]
        public DateTime EndDate { get; set; }

        /// <summary>
        /// Filter by specific clinic IDs (optional)
        /// </summary>
        public List<Guid>? ClinicIds { get; set; }

        /// <summary>
        /// Filter by specific plan IDs (optional)
        /// </summary>
        public List<Guid>? PlanIds { get; set; }

        /// <summary>
        /// Filter by service types (optional)
        /// </summary>
        public List<string>? ServiceTypes { get; set; }

        /// <summary>
        /// Page number for pagination (1-based)
        /// </summary>
        [Range(1, int.MaxValue)]
        public int Page { get; set; } = 1;

        /// <summary>
        /// Page size for pagination
        /// </summary>
        [Range(1, 1000)]
        public int PageSize { get; set; } = 50;

        /// <summary>
        /// Sort field
        /// </summary>
        public string? SortBy { get; set; }

        /// <summary>
        /// Sort direction (asc/desc)
        /// </summary>
        public string SortDirection { get; set; } = "desc";

        /// <summary>
        /// Include detailed breakdown
        /// </summary>
        public bool IncludeDetails { get; set; } = false;

        /// <summary>
        /// Export format (optional)
        /// </summary>
        public ExportFormat? ExportFormat { get; set; }

        /// <summary>
        /// Timezone for date calculations (IANA timezone)
        /// </summary>
        public string TimeZone { get; set; } = "America/Sao_Paulo";

        /// <summary>
        /// Validate date range
        /// </summary>
        public bool IsValid()
        {
            return StartDate <= EndDate && 
                   EndDate <= DateTime.UtcNow && 
                   (EndDate - StartDate).TotalDays <= 365; // Max 1 year
        }
    }

    /// <summary>
    /// Export format options
    /// </summary>
    public enum ExportFormat
    {
        /// <summary>
        /// JSON format (default)
        /// </summary>
        Json,

        /// <summary>
        /// Excel format (.xlsx)
        /// </summary>
        Excel,

        /// <summary>
        /// PDF format
        /// </summary>
        Pdf,

        /// <summary>
        /// CSV format
        /// </summary>
        Csv
    }
}