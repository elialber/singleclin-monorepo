import { api } from './api'
import { DashboardMetrics, ChartData } from '@/types/transaction'

export const dashboardService = {
  async getMetrics(): Promise<DashboardMetrics> {
    const response = await api.get<{ data: DashboardMetrics }>('/dashboard/metrics')
    return response.data.data
  },

  async getChartData(period: 'week' | 'month' | 'year' = 'month'): Promise<ChartData> {
    const response = await api.get<{ data: ChartData }>(`/dashboard/charts?period=${period}`)
    return response.data.data
  },
}