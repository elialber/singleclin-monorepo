using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SingleClin.API.DTOs;
using SingleClin.API.DTOs.Report;
using SingleClin.API.Services;
using Swashbuckle.AspNetCore.Annotations;

namespace SingleClin.API.Controllers
{
    /// <summary>
    /// Controller for generating and exporting reports
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ReportsController : BaseController
    {
        private readonly IReportService _reportService;
        private readonly ILogger<ReportsController> _logger;

        public ReportsController(
            IReportService reportService,
            ILogger<ReportsController> logger)
        {
            _reportService = reportService;
            _logger = logger;
        }

        /// <summary>
        /// Get available report types for the current user
        /// </summary>
        /// <returns>List of available report types</returns>
        [HttpGet("types")]
        [SwaggerOperation(
            Summary = "Get available report types",
            Description = "Returns a list of report types available based on user role")]
        [SwaggerResponse(200, "Success", typeof(ResponseWrapper<List<ReportTypeInfo>>))]
        [SwaggerResponse(401, "Unauthorized")]
        public async Task<IActionResult> GetAvailableReportTypes()
        {
            try
            {
                var userRole = GetUserRole() ?? "Unknown";
                var reportTypes = await _reportService.GetAvailableReportTypesAsync(userRole);

                return Ok(ResponseWrapper<List<ReportTypeInfo>>.SuccessResponse(
                    reportTypes,
                    "Report types retrieved successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving report types");
                return StatusCode(500, ResponseWrapper.ErrorResponse(
                    "An error occurred while retrieving report types"));
            }
        }

        /// <summary>
        /// Generate a report
        /// </summary>
        /// <param name="request">Report request parameters</param>
        /// <returns>Generated report data</returns>
        [HttpPost("generate")]
        [Authorize(Policy = "RequireAdminOrClinicOwner")]
        [SwaggerOperation(
            Summary = "Generate a report",
            Description = "Generates a report based on the specified parameters")]
        [SwaggerResponse(200, "Success", typeof(ResponseWrapper<object>))]
        [SwaggerResponse(400, "Bad Request")]
        [SwaggerResponse(401, "Unauthorized")]
        [SwaggerResponse(403, "Forbidden")]
        public async Task<IActionResult> GenerateReport([FromBody] ReportRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ResponseWrapper.ErrorResponse(
                        "Invalid request parameters", 
                        400, 
                        GetModelStateErrors()));
                }

                // Validate date range
                if (!request.IsValid())
                {
                    return BadRequest(ResponseWrapper.ErrorResponse(
                        "Invalid date range. End date must be after start date and not in the future. Maximum range is 1 year."));
                }

                // Check permissions for specific report type
                var userRole = GetUserRole() ?? "Unknown";
                var availableTypes = await _reportService.GetAvailableReportTypesAsync(userRole);
                
                if (!availableTypes.Any(rt => rt.Type == request.Type))
                {
                    return StatusCode(403, ResponseWrapper.ErrorResponse(
                        $"You don't have permission to generate {request.Type} reports"));
                }

                // Apply clinic filter for clinic owners
                if (userRole == "ClinicOwner")
                {
                    var clinicId = GetUserClinicId();
                    if (clinicId.HasValue)
                    {
                        request.ClinicIds = new List<Guid> { clinicId.Value };
                    }
                }

                // Generate report
                var report = await _reportService.GenerateReportAsync(request);

                return Ok(ResponseWrapper<object>.SuccessResponse(
                    report,
                    $"{request.Type} report generated successfully"));
            }
            catch (NotImplementedException ex)
            {
                _logger.LogWarning(ex, "Report type not implemented: {ReportType}", request.Type);
                return StatusCode(501, ResponseWrapper.ErrorResponse(
                    $"Report type {request.Type} is not implemented yet"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating report of type {ReportType}", request.Type);
                return StatusCode(500, ResponseWrapper.ErrorResponse(
                    "An error occurred while generating the report"));
            }
        }

        /// <summary>
        /// Generate usage by period report
        /// </summary>
        /// <param name="request">Report request parameters</param>
        /// <returns>Usage report data</returns>
        [HttpPost("usage")]
        [Authorize(Policy = "RequireAdminOrClinicOwner")]
        [SwaggerOperation(
            Summary = "Generate usage report",
            Description = "Generates a detailed usage analysis report for the specified period")]
        [SwaggerResponse(200, "Success", typeof(ResponseWrapper<ReportResponse<UsageReportData>>))]
        [SwaggerResponse(400, "Bad Request")]
        [SwaggerResponse(401, "Unauthorized")]
        [SwaggerResponse(403, "Forbidden")]
        public async Task<IActionResult> GenerateUsageReport([FromBody] ReportRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ResponseWrapper.ErrorResponse(
                        "Invalid request parameters", 
                        400, 
                        GetModelStateErrors()));
                }

                request.Type = ReportType.UsageByPeriod;

                // Apply clinic filter for clinic owners
                var userRole = GetUserRole();
                if (userRole == "ClinicOwner")
                {
                    var clinicId = GetUserClinicId();
                    if (clinicId.HasValue)
                    {
                        request.ClinicIds = new List<Guid> { clinicId.Value };
                    }
                }

                var report = await _reportService.GenerateUsageReportAsync(request);

                return Ok(ResponseWrapper<ReportResponse<UsageReportData>>.SuccessResponse(
                    report,
                    "Usage report generated successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating usage report");
                return StatusCode(500, ResponseWrapper.ErrorResponse(
                    "An error occurred while generating the usage report"));
            }
        }

        /// <summary>
        /// Generate clinic ranking report
        /// </summary>
        /// <param name="request">Report request parameters</param>
        /// <returns>Clinic ranking data</returns>
        [HttpPost("clinic-ranking")]
        [Authorize(Roles = "Administrator")]
        [SwaggerOperation(
            Summary = "Generate clinic ranking report",
            Description = "Generates a performance ranking of all clinics")]
        [SwaggerResponse(200, "Success", typeof(ResponseWrapper<ReportResponse<ClinicRankingData>>))]
        [SwaggerResponse(400, "Bad Request")]
        [SwaggerResponse(401, "Unauthorized")]
        [SwaggerResponse(403, "Forbidden")]
        public async Task<IActionResult> GenerateClinicRankingReport([FromBody] ReportRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ResponseWrapper.ErrorResponse(
                        "Invalid request parameters", 
                        400, 
                        GetModelStateErrors()));
                }

                request.Type = ReportType.ClinicRanking;
                var report = await _reportService.GenerateClinicRankingAsync(request);

                return Ok(ResponseWrapper<ReportResponse<ClinicRankingData>>.SuccessResponse(
                    report,
                    "Clinic ranking report generated successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating clinic ranking report");
                return StatusCode(500, ResponseWrapper.ErrorResponse(
                    "An error occurred while generating the clinic ranking report"));
            }
        }

        /// <summary>
        /// Export a report to specified format
        /// </summary>
        /// <param name="request">Report request with export format</param>
        /// <returns>File download</returns>
        [HttpPost("export")]
        [Authorize(Policy = "RequireAdminOrClinicOwner")]
        [SwaggerOperation(
            Summary = "Export a report",
            Description = "Generates and exports a report in the specified format")]
        [SwaggerResponse(200, "Success - File download")]
        [SwaggerResponse(400, "Bad Request")]
        [SwaggerResponse(401, "Unauthorized")]
        [SwaggerResponse(501, "Not Implemented")]
        public async Task<IActionResult> ExportReport([FromBody] ReportRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ResponseWrapper.ErrorResponse(
                        "Invalid request parameters", 
                        400, 
                        GetModelStateErrors()));
                }

                if (!request.ExportFormat.HasValue)
                {
                    return BadRequest(ResponseWrapper.ErrorResponse(
                        "Export format is required"));
                }

                // Generate report first
                var reportData = await _reportService.GenerateReportAsync(request);

                // Export to requested format
                var fileContent = await _reportService.ExportReportAsync(
                    reportData, 
                    request.ExportFormat.Value);

                // Determine content type and file extension
                var (contentType, extension) = request.ExportFormat.Value switch
                {
                    ExportFormat.Excel => ("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "xlsx"),
                    ExportFormat.Pdf => ("application/pdf", "pdf"),
                    ExportFormat.Csv => ("text/csv", "csv"),
                    _ => ("application/json", "json")
                };

                var fileName = $"{request.Type}_Report_{DateTime.UtcNow:yyyyMMdd_HHmmss}.{extension}";

                return File(fileContent, contentType, fileName);
            }
            catch (NotImplementedException)
            {
                return StatusCode(501, ResponseWrapper.ErrorResponse(
                    "Export functionality is not implemented yet"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error exporting report");
                return StatusCode(500, ResponseWrapper.ErrorResponse(
                    "An error occurred while exporting the report"));
            }
        }

        /// <summary>
        /// Clear report cache
        /// </summary>
        /// <param name="reportType">Optional report type to clear</param>
        /// <returns>Success response</returns>
        [HttpDelete("cache")]
        [Authorize(Roles = "Administrator")]
        [SwaggerOperation(
            Summary = "Clear report cache",
            Description = "Clears cached report data")]
        [SwaggerResponse(200, "Success")]
        [SwaggerResponse(401, "Unauthorized")]
        [SwaggerResponse(403, "Forbidden")]
        public async Task<IActionResult> ClearCache([FromQuery] ReportType? reportType = null)
        {
            try
            {
                await _reportService.ClearReportCacheAsync(reportType);

                var message = reportType.HasValue 
                    ? $"Cache cleared for {reportType.Value} reports"
                    : "All report caches cleared";

                return Ok(ResponseWrapper.SuccessResponse(message));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error clearing report cache");
                return StatusCode(500, ResponseWrapper.ErrorResponse(
                    "An error occurred while clearing the cache"));
            }
        }
    }
}