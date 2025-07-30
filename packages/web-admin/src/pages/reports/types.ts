export enum ReportType {
  UsageByPeriod = 0,
  ClinicRanking = 1,
  TopServices = 2,
  PlanUtilization = 3,
  PatientActivity = 4,
  FinancialSummary = 5,
  TransactionAnalysis = 6,
}

export enum ReportPeriod {
  Daily = 0,
  Weekly = 1,
  Monthly = 2,
  Quarterly = 3,
  Yearly = 4,
}

export interface ReportRequest {
  type: ReportType
  period: ReportPeriod
  startDate: string
  endDate: string
  clinicIds?: string[]
  planIds?: string[]
  serviceTypes?: string[]
  page?: number
  pageSize?: number
  sortBy?: string
  sortDirection?: 'asc' | 'desc'
  includeDetails?: boolean
  timeZone?: string
}

export interface ReportResponse<T> {
  type: ReportType
  title: string
  description: string
  generatedAt: string
  period: ReportPeriodInfo
  filters: ReportFilters
  data: T
  summary: ReportSummary
  chartData?: ChartData
  pagination?: PaginationInfo
  executionTimeMs: number
  fromCache: boolean
  cacheExpiresAt?: string
}

export interface ReportPeriodInfo {
  startDate: string
  endDate: string
  period: ReportPeriod
  totalDays: number
  timeZone: string
}

export interface ReportFilters {
  clinicIds?: string[]
  planIds?: string[]
  serviceTypes?: string[]
  sortBy?: string
  sortDirection?: string
}

export interface ReportSummary {
  totalRecords: number
  totals: Record<string, number>
  averages: Record<string, number>
  metrics: Record<string, unknown>
}

export interface ChartData {
  chartType: 'line' | 'bar' | 'pie' | 'radar'
  labels: string[]
  datasets: ChartDataset[]
  options?: ChartOptions
}

export interface ChartDataset {
  label: string
  data: number[]
  backgroundColor?: string | string[]
  borderColor?: string | string[]
  borderWidth?: number
  fill?: boolean
}

export interface ChartOptions {
  responsive?: boolean
  maintainAspectRatio?: boolean
  title?: string
  customOptions?: Record<string, unknown>
}

export interface PaginationInfo {
  currentPage: number
  pageSize: number
  totalRecords: number
  totalPages: number
  hasPrevious: boolean
  hasNext: boolean
}

export interface UsageReportData {
  dailyUsage: UsageDataPoint[]
  weeklyUsage: UsageDataPoint[]
  monthlyUsage: UsageDataPoint[]
  topClinics: ClinicUsage[]
  topServices: ServiceUsage[]
  peakHours: HourlyUsage[]
}

export interface UsageDataPoint {
  date: string
  transactionCount: number
  creditsUsed: number
  uniquePatients: number
  uniqueClinics: number
}

export interface ClinicUsage {
  clinicId: string
  clinicName: string
  clinicType: string
  transactionCount: number
  creditsUsed: number
  uniquePatients: number
  averageCreditsPerTransaction: number
}

export interface ServiceUsage {
  serviceType: string
  count: number
  percentage: number
}

export interface HourlyUsage {
  hour: number
  count: number
  percentage: number
}

export interface ServiceReportData {
  topServices: ServiceUsageItem[]
  distribution: ServiceDistribution
  trends: ServiceTrend[]
  insights: ServiceInsights
}

export interface ServiceUsageItem {
  serviceType: string
  serviceName: string
  category: string
  usageCount: number
  totalCreditsUsed: number
  averageCreditsPerUse: number
  marketShare: number
  uniquePatients: number
  topClinics: string[]
  growthRate: number
}

export interface ServiceDistribution {
  byCategory: Record<string, number>
  categoryPercentages: Record<string, number>
  byPriceRange: Record<string, number>
  totalUniqueServices: number
  concentrationIndex: number
}

export interface ServiceTrend {
  serviceType: string
  trendData: TrendPoint[]
  trendDirection: string
  projectedGrowth: number
}

export interface TrendPoint {
  date: string
  count: number
  value: number
}

export interface ServiceInsights {
  emergingServices: string[]
  decliningServices: string[]
  seasonalPatterns: Record<string, number>
  correlations: ServiceCorrelation[]
  recommendations: string[]
}

export interface ServiceCorrelation {
  service1: string
  service2: string
  correlationScore: number
  coOccurrences: number
}

export interface PlanUtilizationData {
  plans: PlanUtilizationItem[]
  summary: UtilizationSummary
  patterns: UtilizationPattern[]
  efficiency: PlanEfficiencyMetrics
}

export interface PlanUtilizationItem {
  planId: string
  planName: string
  totalCredits: number
  price: number
  usage: PlanUsageMetrics
  efficiency: PlanEfficiency
  monthlyBreakdown: UsageByMonth[]
}

export interface PlanUsageMetrics {
  activeUsers: number
  totalUsers: number
  activationRate: number
  totalCreditsUsed: number
  totalCreditsExpired: number
  totalCreditsAvailable: number
  utilizationRate: number
  averageCreditsPerUser: number
  medianCreditsPerUser: number
  averageTimeBetweenUses: string
}

export interface PlanEfficiency {
  creditEfficiency: number
  valuePerCredit: number
  churnRate: number
  renewalRate: number
  averageDaysToFullUtilization: number
  roi: number
}

export interface UsageByMonth {
  year: number
  month: number
  monthName: string
  creditsUsed: number
  activeUsers: number
  newActivations: number
  expirations: number
}

export interface UtilizationSummary {
  overallUtilizationRate: number
  averageUtilizationPerPlan: number
  mostEfficientPlan: string
  leastEfficientPlan: string
  totalCreditsWasted: number
  wastePercentage: number
  utilizationByPlanType: Record<string, number>
}

export interface UtilizationPattern {
  patternName: string
  description: string
  affectedPlans: string[]
  affectedUsers: number
  recommendation: string
}

export interface PlanEfficiencyMetrics {
  averageCreditEfficiency: number
  optimalUtilizationThreshold: number
  underutilizedPlans: string[]
  overutilizedPlans: string[]
  efficiencyTrends: Record<string, number>
}