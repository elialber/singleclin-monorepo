import { api } from './api'
import { Transaction, TransactionListResponse, TransactionFilters } from '@/types/transaction'

export interface TransactionQueryParams extends TransactionFilters {
  page?: number
  limit?: number
}

export const transactionService = {
  async getTransactions(params: TransactionQueryParams = {}): Promise<TransactionListResponse> {
    const queryParams = new URLSearchParams()
    
    if (params.page) queryParams.append('page', params.page.toString())
    if (params.limit) queryParams.append('limit', params.limit.toString())
    if (params.patientName) queryParams.append('patientName', params.patientName)
    if (params.clinicName) queryParams.append('clinicName', params.clinicName)
    if (params.planName) queryParams.append('planName', params.planName)
    if (params.status) queryParams.append('status', params.status)
    if (params.startDate) queryParams.append('startDate', params.startDate)
    if (params.endDate) queryParams.append('endDate', params.endDate)

    const response = await api.get<TransactionListResponse>(`/transactions?${queryParams.toString()}`)
    return response.data
  },

  async getTransaction(id: string): Promise<Transaction> {
    const response = await api.get<{ data: Transaction }>(`/transactions/${id}`)
    return response.data.data
  },

  async exportTransactions(params: TransactionQueryParams = {}, format: 'csv' | 'excel' = 'csv'): Promise<Blob> {
    const queryParams = new URLSearchParams()
    
    if (params.patientName) queryParams.append('patientName', params.patientName)
    if (params.clinicName) queryParams.append('clinicName', params.clinicName)
    if (params.planName) queryParams.append('planName', params.planName)
    if (params.status) queryParams.append('status', params.status)
    if (params.startDate) queryParams.append('startDate', params.startDate)
    if (params.endDate) queryParams.append('endDate', params.endDate)
    
    queryParams.append('format', format)

    const response = await api.get(`/transactions/export?${queryParams.toString()}`, {
      responseType: 'blob',
    })
    return response.data
  },
}