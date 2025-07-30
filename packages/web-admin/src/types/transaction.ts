export interface Transaction {
  id: string
  patientId: string
  patientName: string
  clinicId: string
  clinicName: string
  planId: string
  planName: string
  creditsUsed: number
  amount: number
  status: 'Pending' | 'Validated' | 'Cancelled'
  transactionDate: string
  description?: string
  qrCodeId?: string
}

export interface TransactionFilters {
  patientName?: string
  clinicName?: string
  planName?: string
  status?: string
  startDate?: string
  endDate?: string
}

export interface TransactionListResponse {
  data: Transaction[]
  total: number
  page: number
  limit: number
}

export interface DashboardMetrics {
  totalPatients: number
  totalTransactions: number
  totalRevenue: number
  activePlans: number
  transactionsThisMonth: number
  revenueThisMonth: number
  mostUsedPlan: {
    name: string
    count: number
  }
  topClinic: {
    name: string
    count: number
  }
}

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