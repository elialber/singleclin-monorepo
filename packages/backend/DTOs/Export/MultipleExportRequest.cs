using SingleClin.API.DTOs.Report;

namespace SingleClin.API.DTOs.Export
{
    /// <summary>
    /// Request model for exporting multiple reports
    /// </summary>
    public class MultipleExportRequest
    {
        public List<ReportType> ReportTypes { get; set; } = new();
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string? TimeZone { get; set; } = "UTC";
        public string? LanguageCode { get; set; } = "pt-BR";
        public ExportOptions Options { get; set; } = new();
    }
}