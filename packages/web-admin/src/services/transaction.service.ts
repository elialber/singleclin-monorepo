import { api } from './api'
import { 
  Transaction, 
  TransactionListResponse, 
  TransactionFilters,
  TransactionUpdate,
  TransactionCancel,
  DashboardMetrics,
  ApiResponse
} from '@/types/transaction'

export interface TransactionQueryParams extends TransactionFilters {}

export const transactionService = {
  /**
   * Get paginated list of transactions with advanced filtering
   */
  async getTransactions(params: TransactionQueryParams = {}): Promise<TransactionListResponse> {
    const queryParams = new URLSearchParams()
    
    // Pagination
    if (params.page) queryParams.append('page', params.page.toString())
    if (params.limit) queryParams.append('limit', params.limit.toString())
    
    // Search and filters (aligned with backend TransactionFilterDto)
    if (params.search) queryParams.append('search', params.search)
    if (params.patientId) queryParams.append('patientId', params.patientId)
    if (params.clinicId) queryParams.append('clinicId', params.clinicId)
    if (params.planId) queryParams.append('planId', params.planId)
    if (params.status) queryParams.append('status', params.status)
    if (params.startDate) queryParams.append('startDate', params.startDate)
    if (params.endDate) queryParams.append('endDate', params.endDate)
    if (params.validationStartDate) queryParams.append('validationStartDate', params.validationStartDate)
    if (params.validationEndDate) queryParams.append('validationEndDate', params.validationEndDate)
    if (params.minAmount !== undefined) queryParams.append('minAmount', params.minAmount.toString())
    if (params.maxAmount !== undefined) queryParams.append('maxAmount', params.maxAmount.toString())
    if (params.minCredits !== undefined) queryParams.append('minCredits', params.minCredits.toString())
    if (params.maxCredits !== undefined) queryParams.append('maxCredits', params.maxCredits.toString())
    if (params.serviceType) queryParams.append('serviceType', params.serviceType)
    if (params.includeCancelled !== undefined) queryParams.append('includeCancelled', params.includeCancelled.toString())
    
    // Sorting
    if (params.sortBy) queryParams.append('sortBy', params.sortBy)
    if (params.sortOrder) queryParams.append('sortOrder', params.sortOrder)

    try {
      const response = await api.get<ApiResponse<TransactionListResponse>>(`/transactions?${queryParams.toString()}`)
      return response.data.data
    } catch (error: any) {
      console.error('Error fetching transactions:', error)
      throw error
    }
  },

  /**
   * Get a specific transaction by ID
   */
  async getTransaction(id: string): Promise<Transaction> {
    try {
      const response = await api.get<ApiResponse<Transaction>>(`/transactions/${id}`)
      return response.data.data
    } catch (error: any) {
      console.error('Error fetching transaction:', error)
      throw error
    }
  },

  /**
   * Update a transaction (only specific fields allowed)
   */
  async updateTransaction(id: string, data: TransactionUpdate): Promise<Transaction> {
    try {
      const response = await api.put<ApiResponse<Transaction>>(`/transactions/${id}`, data)
      return response.data.data
    } catch (error: any) {
      console.error('Error updating transaction:', error)
      throw error
    }
  },

  /**
   * Cancel a transaction and optionally refund credits
   */
  async cancelTransaction(id: string, data: TransactionCancel): Promise<Transaction> {
    try {
      const response = await api.put<ApiResponse<Transaction>>(`/transactions/${id}/cancel`, data)
      return response.data.data
    } catch (error: any) {
      console.error('Error cancelling transaction:', error)
      throw error
    }
  },

  /**
   * Get dashboard metrics for transactions
   */
  async getDashboardMetrics(): Promise<DashboardMetrics> {
    try {
      const response = await api.get<ApiResponse<DashboardMetrics>>('/transactions/dashboard-metrics')
      return response.data.data
    } catch (error: any) {
      console.error('Error fetching dashboard metrics:', error)
      throw error
    }
  },

  /**
   * Export transactions in different formats (Excel/CSV/PDF)
   */
  async exportTransactions(
    params: TransactionQueryParams = {}, 
    format: 'xlsx' | 'csv' | 'pdf' = 'xlsx'
  ): Promise<Blob> {
    const queryParams = new URLSearchParams()
    
    // Apply all the same filters as getTransactions
    if (params.search) queryParams.append('search', params.search)
    if (params.patientId) queryParams.append('patientId', params.patientId)
    if (params.clinicId) queryParams.append('clinicId', params.clinicId)
    if (params.planId) queryParams.append('planId', params.planId)
    if (params.status) queryParams.append('status', params.status)
    if (params.startDate) queryParams.append('startDate', params.startDate)
    if (params.endDate) queryParams.append('endDate', params.endDate)
    if (params.validationStartDate) queryParams.append('validationStartDate', params.validationStartDate)
    if (params.validationEndDate) queryParams.append('validationEndDate', params.validationEndDate)
    if (params.minAmount !== undefined) queryParams.append('minAmount', params.minAmount.toString())
    if (params.maxAmount !== undefined) queryParams.append('maxAmount', params.maxAmount.toString())
    if (params.minCredits !== undefined) queryParams.append('minCredits', params.minCredits.toString())
    if (params.maxCredits !== undefined) queryParams.append('maxCredits', params.maxCredits.toString())
    if (params.serviceType) queryParams.append('serviceType', params.serviceType)
    if (params.includeCancelled !== undefined) queryParams.append('includeCancelled', params.includeCancelled.toString())
    if (params.sortBy) queryParams.append('sortBy', params.sortBy)
    if (params.sortOrder) queryParams.append('sortOrder', params.sortOrder)
    
    queryParams.append('format', format)

    try {
      const response = await api.get(`/transactions/export?${queryParams.toString()}`, {
        responseType: 'blob',
      })
      return response.data
    } catch (error: any) {
      console.error('Error exporting transactions:', error)
      throw error
    }
  },

  /**
   * Helper function to generate mock data for development
   */
  generateMockData(): Transaction[] {
    const now = new Date()
    return [
      {
        id: '1',
        code: 'TXN-001',
        patientId: '1',
        patientName: 'João Silva',
        patientEmail: 'joao@email.com',
        clinicId: '1',
        clinicName: 'Clínica Saúde Total',
        planId: '1',
        planName: 'Plano Básico',
        userPlanId: '1',
        status: 'Validated',
        creditsUsed: 1,
        serviceDescription: 'Consulta de rotina',
        serviceType: 'Consulta',
        amount: 14.99,
        createdAt: new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000).toISOString(),
        validationDate: new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000 + 60000).toISOString(),
        validatedBy: 'Dr. Maria Santos',
        validationNotes: 'Consulta realizada normalmente',
        latitude: -23.5505,
        longitude: -46.6333,
        ipAddress: '192.168.1.100',
        userAgent: 'Mozilla/5.0...',
        qrToken: 'QR001',
        updatedAt: new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000 + 120000).toISOString(),
      },
      {
        id: '2',
        code: 'TXN-002', 
        patientId: '2',
        patientName: 'Maria Santos',
        patientEmail: 'maria@email.com',
        clinicId: '2',
        clinicName: 'Clínica Bem Estar',
        planId: '2',
        planName: 'Plano Intermediário',
        userPlanId: '2',
        status: 'Pending',
        creditsUsed: 2,
        serviceDescription: 'Exame laboratorial',
        serviceType: 'Exame',
        amount: 23.99,
        createdAt: new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000).toISOString(),
        latitude: -23.5505,
        longitude: -46.6333,
        ipAddress: '192.168.1.101',
        userAgent: 'Mozilla/5.0...',
        qrToken: 'QR002',
        updatedAt: new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000 + 60000).toISOString(),
      },
    ]
  },
}