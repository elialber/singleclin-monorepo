namespace SingleClin.API.DTOs.Report
{
    /// <summary>
    /// Usage report data structure
    /// </summary>
    public class UsageReportData
    {
        public List<UsagePeriodData> Periods { get; set; } = new();
        public UsageTrend Trend { get; set; } = new();
        public List<UsageByClinic> TopClinics { get; set; } = new();
        public List<UsageByPlan> PlanDistribution { get; set; } = new();
    }

    /// <summary>
    /// Usage data for a specific period
    /// </summary>
    public class UsagePeriodData
    {
        public DateTime Date { get; set; }
        public string PeriodLabel { get; set; } = string.Empty;
        public int TotalTransactions { get; set; }
        public int CreditsUsed { get; set; }
        public int UniquePatients { get; set; }
        public int ActiveClinics { get; set; }
        public decimal AverageCreditsPerTransaction { get; set; }
        public decimal GrowthRate { get; set; } // Compared to previous period
    }

    /// <summary>
    /// Usage trend analysis
    /// </summary>
    public class UsageTrend
    {
        public decimal OverallGrowthRate { get; set; }
        public string TrendDirection { get; set; } = "stable"; // up, down, stable
        public decimal AverageDailyTransactions { get; set; }
        public decimal PeakUsageDay { get; set; }
        public string PeakUsageDate { get; set; } = string.Empty;
        public Dictionary<string, decimal> WeekdayDistribution { get; set; } = new();
    }

    /// <summary>
    /// Usage by clinic
    /// </summary>
    public class UsageByClinic
    {
        public Guid ClinicId { get; set; }
        public string ClinicName { get; set; } = string.Empty;
        public string ClinicType { get; set; } = string.Empty;
        public int TotalTransactions { get; set; }
        public int CreditsUsed { get; set; }
        public int UniquePatients { get; set; }
        public decimal MarketShare { get; set; } // Percentage of total usage
    }

    /// <summary>
    /// Usage by plan
    /// </summary>
    public class UsageByPlan
    {
        public Guid PlanId { get; set; }
        public string PlanName { get; set; } = string.Empty;
        public int ActiveUsers { get; set; }
        public int TotalCreditsUsed { get; set; }
        public int TotalCreditsAvailable { get; set; }
        public decimal UtilizationRate { get; set; } // Used/Available
        public decimal AverageUsagePerUser { get; set; }
    }
}