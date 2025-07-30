namespace SingleClin.API.DTOs.Report
{
    /// <summary>
    /// Types of reports available in the system
    /// </summary>
    public enum ReportType
    {
        /// <summary>
        /// Usage analysis by time period (daily, weekly, monthly)
        /// </summary>
        UsageByPeriod,

        /// <summary>
        /// Ranking of clinics by various metrics
        /// </summary>
        ClinicRanking,

        /// <summary>
        /// Most used services analysis
        /// </summary>
        TopServices,

        /// <summary>
        /// Plan utilization rates and efficiency
        /// </summary>
        PlanUtilization,

        /// <summary>
        /// Patient activity and retention analysis
        /// </summary>
        PatientActivity,

        /// <summary>
        /// Revenue and financial metrics
        /// </summary>
        FinancialSummary,

        /// <summary>
        /// Transaction details and patterns
        /// </summary>
        TransactionAnalysis
    }
}