namespace SingleClin.API.DTOs.Report
{
    /// <summary>
    /// Service usage report data
    /// </summary>
    public class ServiceReportData
    {
        public List<ServiceUsageItem> TopServices { get; set; } = new();
        public ServiceDistribution Distribution { get; set; } = new();
        public List<ServiceTrend> Trends { get; set; } = new();
        public ServiceInsights Insights { get; set; } = new();
    }

    /// <summary>
    /// Individual service usage data
    /// </summary>
    public class ServiceUsageItem
    {
        public string ServiceType { get; set; } = string.Empty;
        public string ServiceName { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public int UsageCount { get; set; }
        public int TotalCreditsUsed { get; set; }
        public decimal AverageCreditsPerUse { get; set; }
        public decimal MarketShare { get; set; } // Percentage of total services
        public int UniquePatients { get; set; }
        public List<string> TopClinics { get; set; } = new(); // Top 3 clinics using this service
        public decimal GrowthRate { get; set; }
    }

    /// <summary>
    /// Service distribution analysis
    /// </summary>
    public class ServiceDistribution
    {
        public Dictionary<string, int> ByCategory { get; set; } = new();
        public Dictionary<string, decimal> CategoryPercentages { get; set; } = new();
        public Dictionary<string, int> ByPriceRange { get; set; } = new();
        public int TotalUniqueServices { get; set; }
        public decimal ConcentrationIndex { get; set; } // How concentrated usage is (0-1)
    }

    /// <summary>
    /// Service usage trends
    /// </summary>
    public class ServiceTrend
    {
        public string ServiceType { get; set; } = string.Empty;
        public List<TrendPoint> TrendData { get; set; } = new();
        public string TrendDirection { get; set; } = "stable";
        public decimal ProjectedGrowth { get; set; } // Next period projection
    }

    /// <summary>
    /// Trend data point
    /// </summary>
    public class TrendPoint
    {
        public DateTime Date { get; set; }
        public int Count { get; set; }
        public decimal Value { get; set; }
    }

    /// <summary>
    /// Service insights and recommendations
    /// </summary>
    public class ServiceInsights
    {
        public List<string> EmergingServices { get; set; } = new(); // High growth services
        public List<string> DecliningServices { get; set; } = new();
        public Dictionary<string, decimal> SeasonalPatterns { get; set; } = new(); // Service -> Seasonality score
        public List<ServiceCorrelation> Correlations { get; set; } = new(); // Services often used together
        public List<string> Recommendations { get; set; } = new();
    }

    /// <summary>
    /// Service correlation data
    /// </summary>
    public class ServiceCorrelation
    {
        public string Service1 { get; set; } = string.Empty;
        public string Service2 { get; set; } = string.Empty;
        public decimal CorrelationScore { get; set; } // 0-1
        public int CoOccurrences { get; set; }
    }
}