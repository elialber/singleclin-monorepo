namespace SingleClin.API.DTOs.Report
{
    /// <summary>
    /// Plan utilization report data
    /// </summary>
    public class PlanUtilizationData
    {
        public List<PlanUtilizationItem> Plans { get; set; } = new();
        public UtilizationSummary Summary { get; set; } = new();
        public List<UtilizationPattern> Patterns { get; set; } = new();
        public PlanEfficiencyMetrics Efficiency { get; set; } = new();
    }

    /// <summary>
    /// Individual plan utilization data
    /// </summary>
    public class PlanUtilizationItem
    {
        public Guid PlanId { get; set; }
        public string PlanName { get; set; } = string.Empty;
        public int TotalCredits { get; set; }
        public decimal Price { get; set; }
        public PlanUsageMetrics Usage { get; set; } = new();
        public PlanEfficiency Efficiency { get; set; } = new();
        public List<UsageByMonth> MonthlyBreakdown { get; set; } = new();
    }

    /// <summary>
    /// Plan usage metrics
    /// </summary>
    public class PlanUsageMetrics
    {
        public int ActiveUsers { get; set; }
        public int TotalUsers { get; set; }
        public decimal ActivationRate => TotalUsers > 0 ? (decimal)ActiveUsers / TotalUsers : 0;
        public int TotalCreditsUsed { get; set; }
        public int TotalCreditsExpired { get; set; }
        public int TotalCreditsAvailable { get; set; }
        public decimal UtilizationRate => TotalCreditsAvailable > 0 ? 
            (decimal)TotalCreditsUsed / TotalCreditsAvailable : 0;
        public decimal AverageCreditsPerUser { get; set; }
        public decimal MedianCreditsPerUser { get; set; }
        public TimeSpan AverageTimeBetweenUses { get; set; }
    }

    /// <summary>
    /// Plan efficiency metrics
    /// </summary>
    public class PlanEfficiency
    {
        public decimal CreditEfficiency { get; set; } // Used vs Expired ratio
        public decimal ValuePerCredit { get; set; } // Price / Credits used
        public decimal ChurnRate { get; set; } // Users who didn't renew
        public decimal RenewalRate { get; set; }
        public int AverageDaysToFullUtilization { get; set; }
        public decimal ROI { get; set; } // Return on investment metric
    }

    /// <summary>
    /// Monthly usage breakdown
    /// </summary>
    public class UsageByMonth
    {
        public int Year { get; set; }
        public int Month { get; set; }
        public string MonthName { get; set; } = string.Empty;
        public int CreditsUsed { get; set; }
        public int ActiveUsers { get; set; }
        public int NewActivations { get; set; }
        public int Expirations { get; set; }
    }

    /// <summary>
    /// Overall utilization summary
    /// </summary>
    public class UtilizationSummary
    {
        public decimal OverallUtilizationRate { get; set; }
        public decimal AverageUtilizationPerPlan { get; set; }
        public string MostEfficientPlan { get; set; } = string.Empty;
        public string LeastEfficientPlan { get; set; } = string.Empty;
        public decimal TotalCreditsWasted { get; set; } // Expired credits
        public decimal WastePercentage { get; set; }
        public Dictionary<string, decimal> UtilizationByPlanType { get; set; } = new();
    }

    /// <summary>
    /// Utilization patterns
    /// </summary>
    public class UtilizationPattern
    {
        public string PatternName { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public List<Guid> AffectedPlans { get; set; } = new();
        public int AffectedUsers { get; set; }
        public string Recommendation { get; set; } = string.Empty;
    }

    /// <summary>
    /// Plan efficiency metrics across all plans
    /// </summary>
    public class PlanEfficiencyMetrics
    {
        public decimal AverageCreditEfficiency { get; set; }
        public decimal OptimalUtilizationThreshold { get; set; } // Recommended target
        public List<string> UnderutilizedPlans { get; set; } = new(); // < 50% utilization
        public List<string> OverutilizedPlans { get; set; } = new(); // Users hitting limits early
        public Dictionary<string, decimal> EfficiencyTrends { get; set; } = new(); // Plan -> Trend
    }
}