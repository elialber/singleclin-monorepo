namespace SingleClin.API.DTOs.Transaction;

/// <summary>
/// DTO for transaction dashboard metrics
/// </summary>
public class DashboardMetricsDto
{
    /// <summary>
    /// Total number of transactions in the system
    /// </summary>
    public int TotalTransactions { get; set; }

    /// <summary>
    /// Total revenue from all transactions
    /// </summary>
    public decimal TotalRevenue { get; set; }

    /// <summary>
    /// Number of transactions this month
    /// </summary>
    public int TransactionsThisMonth { get; set; }

    /// <summary>
    /// Revenue this month
    /// </summary>
    public decimal RevenueThisMonth { get; set; }

    /// <summary>
    /// Number of active patients (with transactions)
    /// </summary>
    public int ActivePatients { get; set; }

    /// <summary>
    /// Number of active clinics (with transactions)
    /// </summary>
    public int ActiveClinics { get; set; }

    /// <summary>
    /// Number of active plans (with transactions)
    /// </summary>
    public int ActivePlans { get; set; }

    /// <summary>
    /// Average transaction amount
    /// </summary>
    public decimal AverageTransactionAmount { get; set; }

    /// <summary>
    /// Average credits used per transaction
    /// </summary>
    public double AverageCreditsPerTransaction { get; set; }

    /// <summary>
    /// Most used plan information
    /// </summary>
    public MostUsedPlanDto? MostUsedPlan { get; set; }

    /// <summary>
    /// Top performing clinic
    /// </summary>
    public TopClinicDto? TopClinic { get; set; }

    /// <summary>
    /// Transaction status distribution
    /// </summary>
    public List<StatusDistributionDto> StatusDistribution { get; set; } = new();

    /// <summary>
    /// Monthly trends (last 12 months)
    /// </summary>
    public List<MonthlyTrendDto> MonthlyTrends { get; set; } = new();
}

/// <summary>
/// Most used plan information
/// </summary>
public class MostUsedPlanDto
{
    /// <summary>
    /// Plan ID
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// Plan name
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Number of transactions
    /// </summary>
    public int TransactionCount { get; set; }

    /// <summary>
    /// Total revenue from this plan
    /// </summary>
    public decimal TotalRevenue { get; set; }
}

/// <summary>
/// Top performing clinic information
/// </summary>
public class TopClinicDto
{
    /// <summary>
    /// Clinic ID
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// Clinic name
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Number of transactions
    /// </summary>
    public int TransactionCount { get; set; }

    /// <summary>
    /// Total revenue from this clinic
    /// </summary>
    public decimal TotalRevenue { get; set; }
}

/// <summary>
/// Transaction status distribution
/// </summary>
public class StatusDistributionDto
{
    /// <summary>
    /// Transaction status
    /// </summary>
    public string Status { get; set; } = string.Empty;

    /// <summary>
    /// Number of transactions with this status
    /// </summary>
    public int Count { get; set; }

    /// <summary>
    /// Percentage of total transactions
    /// </summary>
    public double Percentage { get; set; }
}

/// <summary>
/// Monthly trend data
/// </summary>
public class MonthlyTrendDto
{
    /// <summary>
    /// Month and year (YYYY-MM)
    /// </summary>
    public string Month { get; set; } = string.Empty;

    /// <summary>
    /// Number of transactions in the month
    /// </summary>
    public int TransactionCount { get; set; }

    /// <summary>
    /// Total revenue in the month
    /// </summary>
    public decimal Revenue { get; set; }

    /// <summary>
    /// Total credits used in the month
    /// </summary>
    public int CreditsUsed { get; set; }
}