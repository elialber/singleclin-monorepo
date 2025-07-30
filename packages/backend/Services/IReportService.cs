using SingleClin.API.DTOs.Report;

namespace SingleClin.API.Services
{
    /// <summary>
    /// Interface for report generation service
    /// </summary>
    public interface IReportService
    {
        /// <summary>
        /// Generate a report based on the request parameters
        /// </summary>
        /// <param name="request">Report request parameters</param>
        /// <param name="cancellationToken">Cancellation token</param>
        /// <returns>Report response with data</returns>
        Task<object> GenerateReportAsync(ReportRequest request, CancellationToken cancellationToken = default);

        /// <summary>
        /// Generate usage by period report
        /// </summary>
        Task<ReportResponse<UsageReportData>> GenerateUsageReportAsync(
            ReportRequest request, 
            CancellationToken cancellationToken = default);

        /// <summary>
        /// Generate clinic ranking report
        /// </summary>
        Task<ReportResponse<ClinicRankingData>> GenerateClinicRankingAsync(
            ReportRequest request, 
            CancellationToken cancellationToken = default);

        /// <summary>
        /// Generate top services report
        /// </summary>
        Task<ReportResponse<ServiceReportData>> GenerateServiceReportAsync(
            ReportRequest request, 
            CancellationToken cancellationToken = default);

        /// <summary>
        /// Generate plan utilization report
        /// </summary>
        Task<ReportResponse<PlanUtilizationData>> GeneratePlanUtilizationAsync(
            ReportRequest request, 
            CancellationToken cancellationToken = default);

        /// <summary>
        /// Export report to specified format
        /// </summary>
        /// <param name="reportData">Report data to export</param>
        /// <param name="format">Export format</param>
        /// <param name="cancellationToken">Cancellation token</param>
        /// <returns>File content as byte array</returns>
        Task<byte[]> ExportReportAsync(
            object reportData, 
            ExportFormat format, 
            CancellationToken cancellationToken = default);

        /// <summary>
        /// Get available report types for user
        /// </summary>
        /// <param name="userRole">User role</param>
        /// <returns>List of available report types</returns>
        Task<List<ReportTypeInfo>> GetAvailableReportTypesAsync(string userRole);

        /// <summary>
        /// Clear cached report data
        /// </summary>
        /// <param name="reportType">Optional report type to clear</param>
        Task ClearReportCacheAsync(ReportType? reportType = null);
    }

    /// <summary>
    /// Report type information
    /// </summary>
    public class ReportTypeInfo
    {
        public ReportType Type { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public List<string> RequiredRoles { get; set; } = new();
        public List<string> AvailableFilters { get; set; } = new();
        public List<ExportFormat> SupportedFormats { get; set; } = new();
    }
}