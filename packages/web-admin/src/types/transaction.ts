// Enums
export type TransactionStatus = 'Pending' | 'Validated' | 'Cancelled' | 'Expired'

export type SortOrder = 'asc' | 'desc'

export type SortField = 'code' | 'patientname' | 'clinicname' | 'planname' | 'status' | 
  'creditsused' | 'amount' | 'createdat' | 'validationdate' | 'updatedat'

// Main Transaction interface (aligned with TransactionResponseDto)
export interface Transaction {
  id: string
  code: string
  patientId: string
  patientName: string
  patientEmail: string
  clinicId: string
  clinicName: string
  planId: string
  planName: string
  userPlanId: string
  status: TransactionStatus
  creditsUsed: number
  serviceDescription: string
  serviceType?: string
  amount: number
  createdAt: string
  validationDate?: string
  validatedBy?: string
  validationNotes?: string
  cancellationDate?: string
  cancellationReason?: string
  latitude?: number
  longitude?: number
  ipAddress?: string
  userAgent?: string
  qrToken?: string
  updatedAt: string
}

// Filter interface (aligned with TransactionFilterDto)
export interface TransactionFilters {
  search?: string
  patientId?: string
  clinicId?: string
  planId?: string
  status?: TransactionStatus
  startDate?: string
  endDate?: string
  validationStartDate?: string
  validationEndDate?: string
  minAmount?: number
  maxAmount?: number
  minCredits?: number
  maxCredits?: number
  serviceType?: string
  includeCancelled?: boolean
  page?: number
  limit?: number
  sortBy?: SortField
  sortOrder?: SortOrder
}

// List response interface (aligned with TransactionListResponseDto)
export interface TransactionListResponse {
  data: Transaction[]
  total: number
  page: number
  limit: number
  totalPages: number
  hasNextPage: boolean
  hasPreviousPage: boolean
}

// Update interface (aligned with TransactionUpdateDto)
export interface TransactionUpdate {
  serviceDescription?: string
  serviceType?: string
  validationNotes?: string
  amount?: number
}

// Cancel interface (aligned with TransactionCancelDto)
export interface TransactionCancel {
  cancellationReason: string
  notes?: string
  refundCredits?: boolean
}

// Dashboard metrics (aligned with DashboardMetricsDto)
export interface MostUsedPlan {
  id: string
  name: string
  transactionCount: number
  totalRevenue: number
}

export interface TopClinic {
  id: string
  name: string
  transactionCount: number
  totalRevenue: number
}

export interface StatusDistribution {
  status: string
  count: number
  percentage: number
}

export interface MonthlyTrend {
  month: string
  transactionCount: number
  revenue: number
  creditsUsed: number
}

export interface DashboardMetrics {
  totalTransactions: number
  totalRevenue: number
  transactionsThisMonth: number
  revenueThisMonth: number
  activePatients: number
  activeClinics: number
  activePlans: number
  averageTransactionAmount: number
  averageCreditsPerTransaction: number
  mostUsedPlan?: MostUsedPlan
  topClinic?: TopClinic
  statusDistribution: StatusDistribution[]
  monthlyTrends: MonthlyTrend[]
}

// Additional interfaces for UI
export interface ChartData {
  transactionsByDay: Array<{
    date: string
    count: number
    amount: number
  }>
  transactionsByPlan: Array<{
    planName: string
    count: number
    percentage: number
  }>
  topClinics: Array<{
    clinicName: string
    count: number
    amount: number
  }>
}

// API Response wrapper (common pattern in the backend)
export interface ApiResponse<T> {
  data: T
  success: boolean
  message?: string
  errors?: string[]
}