using OfficeOpenXml;
using OfficeOpenXml.Drawing.Chart;
using OfficeOpenXml.Style;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using SingleClin.API.DTOs.Export;
using SingleClin.API.DTOs.Report;
using SingleClin.API.DTOs.Common;
using System.Globalization;
using System.Reflection;

namespace SingleClin.API.Services
{
    /// <summary>
    /// Service for exporting reports to various formats
    /// </summary>
    public class ExportService : IExportService
    {
        private readonly ILogger<ExportService> _logger;
        private readonly Dictionary<string, CultureInfo> _cultures;

        public ExportService(ILogger<ExportService> logger)
        {
            _logger = logger;
            _cultures = new Dictionary<string, CultureInfo>
            {
                ["pt-BR"] = new CultureInfo("pt-BR"),
                ["en-US"] = new CultureInfo("en-US"),
                ["es-ES"] = new CultureInfo("es-ES")
            };

            // Set EPPlus license context
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;

            // Configure QuestPDF
            QuestPDF.Settings.License = LicenseType.Community;
        }

        public async Task<ExportResponse> ExportToExcelAsync<T>(
            ReportResponse<T> reportData,
            ExportRequest request,
            CancellationToken cancellationToken = default) where T : class
        {
            try
            {
                using var package = new ExcelPackage();
                var worksheet = package.Workbook.Worksheets.Add(GetReportTitle(request.ReportType));

                // Add header with logo and title
                AddExcelHeader(worksheet, request);

                // Add filters information
                if (request.Options.IncludeFilters)
                {
                    AddExcelFilters(worksheet, request, 4);
                }

                // Add report data based on type
                var startRow = request.Options.IncludeFilters ? 8 : 4;
                var dataEndRow = AddReportDataToExcel(worksheet, reportData, request, startRow);

                // Add charts if requested
                if (request.Options.IncludeCharts && reportData.ChartData != null)
                {
                    AddExcelCharts(worksheet, reportData.ChartData, dataEndRow + 2);
                }

                // Format worksheet
                FormatExcelWorksheet(worksheet);

                // Generate file
                var fileContent = await package.GetAsByteArrayAsync(cancellationToken);
                var fileName = GenerateFileName(request, "xlsx");

                return new ExportResponse
                {
                    Success = true,
                    FileName = fileName,
                    ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    FileContent = fileContent,
                    FileSize = fileContent.Length,
                    Metadata = new Dictionary<string, string>
                    {
                        ["ReportType"] = request.ReportType.ToString(),
                        ["GeneratedAt"] = DateTime.UtcNow.ToString("O"),
                        ["Format"] = "Excel"
                    }
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error exporting report to Excel");
                return new ExportResponse
                {
                    Success = false,
                    Warnings = new List<string> { ex.Message }
                };
            }
        }

        public Task<ExportResponse> ExportToPdfAsync<T>(
            ReportResponse<T> reportData,
            ExportRequest request,
            CancellationToken cancellationToken = default) where T : class
        {
            try
            {
                var document = Document.Create(container =>
                {
                    container.Page(page =>
                    {
                        // Configure page based on options
                        ConfigurePdfPage(page, request.Options);

                        page.Header().Element(ComposeHeader);
                        page.Content().Element(ComposeContent);
                        page.Footer().AlignCenter().Text(x =>
                        {
                            x.Span("Página ");
                            x.CurrentPageNumber();
                            x.Span(" de ");
                            x.TotalPages();
                        });

                        void ComposeHeader(IContainer container)
                        {
                            container.Row(row =>
                            {
                                row.RelativeItem().Column(column =>
                                {
                                    column.Item().Text("SingleClin")
                                        .SemiBold().FontSize(20).FontColor("#1976D2");
                                    column.Item().Text(GetReportTitle(request.ReportType))
                                        .FontSize(16);
                                    column.Item().Text($"Período: {request.StartDate:dd/MM/yyyy} - {request.EndDate:dd/MM/yyyy}")
                                        .FontSize(12).FontColor(Colors.Grey.Darken2);
                                });

                                row.ConstantItem(100).Height(50).Placeholder();
                            });
                        }

                        void ComposeContent(IContainer container)
                        {
                            container.PaddingVertical(1, Unit.Centimetre).Column(column =>
                            {
                                // Add summary if requested
                                if (request.Options.IncludeSummary && reportData.Summary != null)
                                {
                                    column.Item().Element(ComposeSummary);
                                    column.Item().PageBreak();
                                }

                                // Add main content
                                column.Item().Element(ComposeMainContent);

                                // Add details if requested
                                if (request.Options.IncludeDetails)
                                {
                                    column.Item().PageBreak();
                                    column.Item().Element(ComposeDetails);
                                }
                            });
                        }

                        void ComposeSummary(IContainer container)
                        {
                            container.Column(column =>
                            {
                                column.Item().Text("Resumo Executivo").FontSize(14).SemiBold();
                                column.Item().PaddingTop(10).Text(GenerateSummaryText(reportData));
                            });
                        }

                        void ComposeMainContent(IContainer container)
                        {
                            container.Column(column =>
                            {
                                // Add data based on report type
                                AddPdfReportData(column, reportData, request);
                            });
                        }

                        void ComposeDetails(IContainer container)
                        {
                            container.Column(column =>
                            {
                                column.Item().Text("Detalhes").FontSize(14).SemiBold();
                                // Add detailed data tables
                                AddPdfDetailedData(column, reportData, request);
                            });
                        }
                    });
                });

                var pdf = document.GeneratePdf();
                var fileName = GenerateFileName(request, "pdf");

                var response = new ExportResponse
                {
                    Success = true,
                    FileName = fileName,
                    ContentType = "application/pdf",
                    FileContent = pdf,
                    FileSize = pdf.Length,
                    Metadata = new Dictionary<string, string>
                    {
                        ["ReportType"] = request.ReportType.ToString(),
                        ["GeneratedAt"] = DateTime.UtcNow.ToString("O"),
                        ["Format"] = "PDF"
                    }
                };

                return Task.FromResult(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error exporting report to PDF");
                var failureResponse = new ExportResponse
                {
                    Success = false,
                    Warnings = new List<string> { ex.Message }
                };

                return Task.FromResult(failureResponse);
            }
        }

        public async Task<ExportResponse> ExportMultipleToExcelAsync(
            Dictionary<string, object> reports,
            ExportRequest request,
            CancellationToken cancellationToken = default)
        {
            try
            {
                using var package = new ExcelPackage();

                foreach (var report in reports)
                {
                    var worksheet = package.Workbook.Worksheets.Add(report.Key);

                    // Use reflection to handle generic report data
                    var reportType = report.Value.GetType();
                    if (reportType.IsGenericType && reportType.GetGenericTypeDefinition() == typeof(ReportResponse<>))
                    {
                        var method = GetType().GetMethod(nameof(AddReportDataToExcel), BindingFlags.NonPublic | BindingFlags.Instance);
                        var genericMethod = method?.MakeGenericMethod(reportType.GetGenericArguments()[0]);
                        genericMethod?.Invoke(this, new object[] { worksheet, report.Value, request, 4 });
                    }

                    FormatExcelWorksheet(worksheet);
                }

                var fileContent = await package.GetAsByteArrayAsync(cancellationToken);
                var fileName = $"relatorio_completo_{DateTime.UtcNow:yyyyMMdd_HHmmss}.xlsx";

                return new ExportResponse
                {
                    Success = true,
                    FileName = fileName,
                    ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    FileContent = fileContent,
                    FileSize = fileContent.Length,
                    Metadata = new Dictionary<string, string>
                    {
                        ["ReportCount"] = reports.Count.ToString(),
                        ["GeneratedAt"] = DateTime.UtcNow.ToString("O"),
                        ["Format"] = "Excel"
                    }
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error exporting multiple reports to Excel");
                return new ExportResponse
                {
                    Success = false,
                    Warnings = new List<string> { ex.Message }
                };
            }
        }

        private void AddExcelHeader(ExcelWorksheet worksheet, ExportRequest request)
        {
            worksheet.Cells["A1:F1"].Merge = true;
            worksheet.Cells["A1"].Value = "SingleClin";
            worksheet.Cells["A1"].Style.Font.Size = 20;
            worksheet.Cells["A1"].Style.Font.Bold = true;
            worksheet.Cells["A1"].Style.Font.Color.SetColor(System.Drawing.Color.FromArgb(25, 118, 210));

            worksheet.Cells["A2:F2"].Merge = true;
            worksheet.Cells["A2"].Value = GetReportTitle(request.ReportType);
            worksheet.Cells["A2"].Style.Font.Size = 16;
        }

        private void AddExcelFilters(ExcelWorksheet worksheet, ExportRequest request, int startRow)
        {
            worksheet.Cells[$"A{startRow}"].Value = "Filtros Aplicados:";
            worksheet.Cells[$"A{startRow}"].Style.Font.Bold = true;

            worksheet.Cells[$"A{startRow + 1}"].Value = "Período:";
            worksheet.Cells[$"B{startRow + 1}"].Value = $"{request.StartDate:dd/MM/yyyy} - {request.EndDate:dd/MM/yyyy}";

            worksheet.Cells[$"A{startRow + 2}"].Value = "Fuso Horário:";
            worksheet.Cells[$"B{startRow + 2}"].Value = request.TimeZone;
        }

        private int AddReportDataToExcel<T>(
            ExcelWorksheet worksheet,
            ReportResponse<T> reportData,
            ExportRequest request,
            int startRow) where T : class
        {
            var currentRow = startRow;

            // Add data based on report type
            switch (request.ReportType)
            {
                case ReportType.TopServices:
                    if (reportData.Data is ServiceReportData serviceData)
                    {
                        currentRow = AddServiceReportToExcel(worksheet, serviceData, currentRow);
                    }
                    break;

                case ReportType.PlanUtilization:
                    if (reportData.Data is PlanUtilizationData planData)
                    {
                        currentRow = AddPlanUtilizationToExcel(worksheet, planData, currentRow);
                    }
                    break;

                    // Add other report types as needed
            }

            return currentRow;
        }

        private int AddServiceReportToExcel(ExcelWorksheet worksheet, ServiceReportData data, int startRow)
        {
            var currentRow = startRow;

            // Add header
            worksheet.Cells[$"A{currentRow}"].Value = "Top Serviços";
            worksheet.Cells[$"A{currentRow}:F{currentRow}"].Style.Font.Bold = true;
            worksheet.Cells[$"A{currentRow}:F{currentRow}"].Style.Fill.PatternType = ExcelFillStyle.Solid;
            worksheet.Cells[$"A{currentRow}:F{currentRow}"].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightGray);
            currentRow++;

            // Add column headers
            worksheet.Cells[$"A{currentRow}"].Value = "Serviço";
            worksheet.Cells[$"B{currentRow}"].Value = "Categoria";
            worksheet.Cells[$"C{currentRow}"].Value = "Uso Total";
            worksheet.Cells[$"D{currentRow}"].Value = "Créditos Usados";
            worksheet.Cells[$"E{currentRow}"].Value = "Market Share (%)";
            worksheet.Cells[$"F{currentRow}"].Value = "Crescimento (%)";
            currentRow++;

            // Add data
            foreach (var service in data.TopServices)
            {
                worksheet.Cells[$"A{currentRow}"].Value = service.ServiceName;
                worksheet.Cells[$"B{currentRow}"].Value = service.Category;
                worksheet.Cells[$"C{currentRow}"].Value = service.UsageCount;
                worksheet.Cells[$"D{currentRow}"].Value = service.TotalCreditsUsed;
                worksheet.Cells[$"E{currentRow}"].Value = service.MarketShare;
                worksheet.Cells[$"E{currentRow}"].Style.Numberformat.Format = "0.00%";
                worksheet.Cells[$"F{currentRow}"].Value = service.GrowthRate;
                worksheet.Cells[$"F{currentRow}"].Style.Numberformat.Format = "0.00%";
                currentRow++;
            }

            // Add totals
            currentRow++;
            worksheet.Cells[$"A{currentRow}"].Value = "TOTAL";
            worksheet.Cells[$"A{currentRow}"].Style.Font.Bold = true;
            worksheet.Cells[$"C{currentRow}"].Formula = $"SUM(C{startRow + 2}:C{currentRow - 2})";
            worksheet.Cells[$"D{currentRow}"].Formula = $"SUM(D{startRow + 2}:D{currentRow - 2})";

            return currentRow + 2;
        }

        private int AddPlanUtilizationToExcel(ExcelWorksheet worksheet, PlanUtilizationData data, int startRow)
        {
            var currentRow = startRow;

            // Add summary section
            worksheet.Cells[$"A{currentRow}"].Value = "Resumo de Utilização";
            worksheet.Cells[$"A{currentRow}:D{currentRow}"].Style.Font.Bold = true;
            worksheet.Cells[$"A{currentRow}:D{currentRow}"].Style.Fill.PatternType = ExcelFillStyle.Solid;
            worksheet.Cells[$"A{currentRow}:D{currentRow}"].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightBlue);
            currentRow++;

            worksheet.Cells[$"A{currentRow}"].Value = "Taxa Geral de Utilização:";
            worksheet.Cells[$"B{currentRow}"].Value = data.Summary.OverallUtilizationRate;
            worksheet.Cells[$"B{currentRow}"].Style.Numberformat.Format = "0.00%";
            currentRow++;

            worksheet.Cells[$"A{currentRow}"].Value = "Créditos Desperdiçados:";
            worksheet.Cells[$"B{currentRow}"].Value = data.Summary.TotalCreditsWasted;
            currentRow++;

            currentRow += 2;

            // Add plan details header
            worksheet.Cells[$"A{currentRow}"].Value = "Detalhes por Plano";
            worksheet.Cells[$"A{currentRow}:H{currentRow}"].Style.Font.Bold = true;
            worksheet.Cells[$"A{currentRow}:H{currentRow}"].Style.Fill.PatternType = ExcelFillStyle.Solid;
            worksheet.Cells[$"A{currentRow}:H{currentRow}"].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightGray);
            currentRow++;

            // Add column headers
            worksheet.Cells[$"A{currentRow}"].Value = "Plano";
            worksheet.Cells[$"B{currentRow}"].Value = "Créditos Total";
            worksheet.Cells[$"C{currentRow}"].Value = "Preço";
            worksheet.Cells[$"D{currentRow}"].Value = "Usuários Ativos";
            worksheet.Cells[$"E{currentRow}"].Value = "Taxa Utilização";
            worksheet.Cells[$"F{currentRow}"].Value = "Eficiência";
            worksheet.Cells[$"G{currentRow}"].Value = "Taxa Renovação";
            worksheet.Cells[$"H{currentRow}"].Value = "ROI";
            currentRow++;

            // Add data
            foreach (var plan in data.Plans)
            {
                worksheet.Cells[$"A{currentRow}"].Value = plan.PlanName;
                worksheet.Cells[$"B{currentRow}"].Value = plan.TotalCredits;
                worksheet.Cells[$"C{currentRow}"].Value = plan.Price;
                worksheet.Cells[$"C{currentRow}"].Style.Numberformat.Format = "R$ #,##0.00";
                worksheet.Cells[$"D{currentRow}"].Value = plan.Usage.ActiveUsers;
                worksheet.Cells[$"E{currentRow}"].Value = plan.Usage.UtilizationRate;
                worksheet.Cells[$"E{currentRow}"].Style.Numberformat.Format = "0.00%";
                worksheet.Cells[$"F{currentRow}"].Value = plan.Efficiency.CreditEfficiency;
                worksheet.Cells[$"F{currentRow}"].Style.Numberformat.Format = "0.00%";
                worksheet.Cells[$"G{currentRow}"].Value = plan.Efficiency.RenewalRate;
                worksheet.Cells[$"G{currentRow}"].Style.Numberformat.Format = "0.00%";
                worksheet.Cells[$"H{currentRow}"].Value = plan.Efficiency.ROI;
                worksheet.Cells[$"H{currentRow}"].Style.Numberformat.Format = "0.00%";
                currentRow++;
            }

            return currentRow + 2;
        }

        private void AddExcelCharts(ExcelWorksheet worksheet, ChartData chartData, int startRow)
        {
            if (chartData.ChartType == "bar" && chartData.Datasets.Any())
            {
                var chart = worksheet.Drawings.AddChart("chart1", eChartType.ColumnClustered);
                chart.SetPosition(startRow, 0, 0, 0);
                chart.SetSize(600, 400);

                var dataset = chartData.Datasets.First();
                var endRow = startRow + dataset.Data.Count - 1;

                // Add data to hidden cells for chart
                for (int i = 0; i < chartData.Labels.Count; i++)
                {
                    worksheet.Cells[$"Z{startRow + i}"].Value = chartData.Labels[i];
                    worksheet.Cells[$"AA{startRow + i}"].Value = dataset.Data[i];
                }

                var series = chart.Series.Add(
                    worksheet.Cells[$"AA{startRow}:AA{endRow}"],
                    worksheet.Cells[$"Z{startRow}:Z{endRow}"]
                );
                series.Header = dataset.Label;

                chart.Title.Text = chartData.Options?.Title ?? "Gráfico";
            }
        }

        private void FormatExcelWorksheet(ExcelWorksheet worksheet)
        {
            // Auto-fit columns
            worksheet.Cells[worksheet.Dimension.Address].AutoFitColumns();

            // Add borders
            var dataRange = worksheet.Cells[worksheet.Dimension.Address];
            dataRange.Style.Border.Top.Style = ExcelBorderStyle.Thin;
            dataRange.Style.Border.Left.Style = ExcelBorderStyle.Thin;
            dataRange.Style.Border.Right.Style = ExcelBorderStyle.Thin;
            dataRange.Style.Border.Bottom.Style = ExcelBorderStyle.Thin;

            // Set print area
            worksheet.PrinterSettings.PrintArea = worksheet.Cells[worksheet.Dimension.Address];
            worksheet.PrinterSettings.FitToPage = true;
            worksheet.PrinterSettings.FitToWidth = 1;
            worksheet.PrinterSettings.FitToHeight = 0;
        }

        private void ConfigurePdfPage(PageDescriptor page, ExportOptions options)
        {
            switch (options.PaperSize)
            {
                case PaperSize.A3:
                    page.Size(options.Orientation == PaperOrientation.Portrait ? PageSizes.A3 : PageSizes.A3.Landscape());
                    break;
                case PaperSize.Letter:
                    page.Size(options.Orientation == PaperOrientation.Portrait ? PageSizes.Letter : PageSizes.Letter.Landscape());
                    break;
                case PaperSize.Legal:
                    page.Size(options.Orientation == PaperOrientation.Portrait ? PageSizes.Legal : PageSizes.Legal.Landscape());
                    break;
                default:
                    page.Size(options.Orientation == PaperOrientation.Portrait ? PageSizes.A4 : PageSizes.A4.Landscape());
                    break;
            }

            page.Margin(2, Unit.Centimetre);
            page.PageColor(Colors.White);
            page.DefaultTextStyle(x => x.FontSize(10));
        }

        private void AddPdfReportData(ColumnDescriptor column, object reportData, ExportRequest request)
        {
            // Implementation based on report type
            column.Item().Text($"Report data for {request.ReportType}");
            // Add specific formatting based on report type
        }

        private void AddPdfDetailedData(ColumnDescriptor column, object reportData, ExportRequest request)
        {
            // Implementation based on report type
            column.Item().Text("Detailed data tables");
            // Add tables with detailed information
        }

        private string GenerateSummaryText(object reportData)
        {
            // Generate executive summary based on report data
            return "Este relatório apresenta uma análise detalhada dos dados solicitados...";
        }

        private string GetReportTitle(ReportType reportType)
        {
            return reportType switch
            {
                ReportType.UsageByPeriod => "Análise de Uso por Período",
                ReportType.ClinicRanking => "Ranking de Clínicas",
                ReportType.TopServices => "Serviços Mais Utilizados",
                ReportType.PlanUtilization => "Utilização de Planos",
                ReportType.PatientActivity => "Atividade de Pacientes",
                ReportType.FinancialSummary => "Resumo Financeiro",
                ReportType.TransactionAnalysis => "Análise de Transações",
                _ => "Relatório"
            };
        }

        private string GenerateFileName(ExportRequest request, string extension)
        {
            var timestamp = DateTime.UtcNow.ToString("yyyyMMdd_HHmmss");
            var reportName = request.ReportType.ToString().ToLower();
            return $"relatorio_{reportName}_{timestamp}.{extension}";
        }
    }
}
