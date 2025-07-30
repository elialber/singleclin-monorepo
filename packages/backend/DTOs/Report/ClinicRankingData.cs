namespace SingleClin.API.DTOs.Report
{
    /// <summary>
    /// Clinic ranking report data
    /// </summary>
    public class ClinicRankingData
    {
        public List<ClinicRankingItem> Rankings { get; set; } = new();
        public ClinicPerformanceMetrics OverallMetrics { get; set; } = new();
        public List<ClinicGrowthData> GrowthLeaders { get; set; } = new();
    }

    /// <summary>
    /// Individual clinic ranking item
    /// </summary>
    public class ClinicRankingItem
    {
        public int Rank { get; set; }
        public int PreviousRank { get; set; }
        public string RankChange { get; set; } = "same"; // up, down, same, new
        public Guid ClinicId { get; set; }
        public string ClinicName { get; set; } = string.Empty;
        public string ClinicType { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public ClinicMetrics Metrics { get; set; } = new();
        public decimal Score { get; set; } // Composite score for ranking
    }

    /// <summary>
    /// Clinic performance metrics
    /// </summary>
    public class ClinicMetrics
    {
        public int TotalTransactions { get; set; }
        public int CreditsProcessed { get; set; }
        public int UniquePatients { get; set; }
        public decimal AverageTransactionValue { get; set; }
        public decimal PatientRetentionRate { get; set; }
        public decimal GrowthRate { get; set; }
        public int DaysActive { get; set; }
        public decimal AverageDailyTransactions { get; set; }
        public TimeSpan AverageServiceTime { get; set; }
        public decimal PatientSatisfactionScore { get; set; } // If available
    }

    /// <summary>
    /// Overall clinic performance metrics
    /// </summary>
    public class ClinicPerformanceMetrics
    {
        public int TotalActiveClinics { get; set; }
        public int NewClinicsThisPeriod { get; set; }
        public decimal AverageTransactionsPerClinic { get; set; }
        public decimal MedianTransactionsPerClinic { get; set; }
        public decimal TopPerformersThreshold { get; set; } // Top 20% threshold
        public Dictionary<string, int> ClinicsByType { get; set; } = new();
    }

    /// <summary>
    /// Clinic growth data
    /// </summary>
    public class ClinicGrowthData
    {
        public Guid ClinicId { get; set; }
        public string ClinicName { get; set; } = string.Empty;
        public decimal GrowthRate { get; set; }
        public int TransactionIncrease { get; set; }
        public int NewPatientsAdded { get; set; }
        public string GrowthCategory { get; set; } = "steady"; // rapid, fast, steady, slow
    }
}