namespace SingleClin.API.DTOs.Report
{
    /// <summary>
    /// Time period granularity for reports
    /// </summary>
    public enum ReportPeriod
    {
        /// <summary>
        /// Daily aggregation
        /// </summary>
        Daily,

        /// <summary>
        /// Weekly aggregation
        /// </summary>
        Weekly,

        /// <summary>
        /// Monthly aggregation
        /// </summary>
        Monthly,

        /// <summary>
        /// Quarterly aggregation
        /// </summary>
        Quarterly,

        /// <summary>
        /// Yearly aggregation
        /// </summary>
        Yearly,

        /// <summary>
        /// Custom date range without aggregation
        /// </summary>
        Custom
    }
}