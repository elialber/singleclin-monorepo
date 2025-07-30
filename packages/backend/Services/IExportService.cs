using SingleClin.API.DTOs.Export;
using SingleClin.API.DTOs.Report;

namespace SingleClin.API.Services
{
    /// <summary>
    /// Service for exporting reports to various formats
    /// </summary>
    public interface IExportService
    {
        /// <summary>
        /// Export report to Excel format
        /// </summary>
        Task<ExportResponse> ExportToExcelAsync<T>(
            ReportResponse<T> reportData,
            ExportRequest request,
            CancellationToken cancellationToken = default) where T : class;

        /// <summary>
        /// Export report to PDF format
        /// </summary>
        Task<ExportResponse> ExportToPdfAsync<T>(
            ReportResponse<T> reportData,
            ExportRequest request,
            CancellationToken cancellationToken = default) where T : class;

        /// <summary>
        /// Export multiple reports to a single Excel file with multiple sheets
        /// </summary>
        Task<ExportResponse> ExportMultipleToExcelAsync(
            Dictionary<string, object> reports,
            ExportRequest request,
            CancellationToken cancellationToken = default);
    }
}