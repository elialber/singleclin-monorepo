using SingleClin.API.DTOs.Report;
using SingleClin.API.DTOs.Common;

namespace SingleClin.API.DTOs.Export
{
    /// <summary>
    /// Export request model
    /// </summary>
    public class ExportRequest
    {
        public ExportFormat Format { get; set; }
        public ReportType ReportType { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string? TimeZone { get; set; } = "UTC";
        public string? LanguageCode { get; set; } = "pt-BR";
        public ExportOptions Options { get; set; } = new();
    }

    /// <summary>
    /// Export options
    /// </summary>
    public class ExportOptions
    {
        public bool IncludeCharts { get; set; } = true;
        public bool IncludeSummary { get; set; } = true;
        public bool IncludeDetails { get; set; } = true;
        public bool IncludeFilters { get; set; } = true;
        public PaperSize PaperSize { get; set; } = PaperSize.A4;
        public PaperOrientation Orientation { get; set; } = PaperOrientation.Portrait;
    }
}