import { api } from './api'
import { DashboardMetrics, ChartData } from '@/types/transaction'

// Mock data while backend endpoints are not implemented
const mockMetrics: DashboardMetrics = {
  totalPatients: 1250,
  totalTransactions: 3567,
  transactionsThisMonth: 234,
  totalRevenue: 125678.90,
  revenueThisMonth: 15234.50,
  activePlans: 45,
  mostUsedPlan: {
    id: '1',
    name: 'Plano Premium',
    count: 125
  }
}

const generateMockChartData = (period: string): ChartData => {
  const days = period === 'week' ? 7 : period === 'month' ? 30 : 365
  const now = new Date()
  
  const transactionsByDay = Array.from({ length: Math.min(days, 30) }, (_, i) => {
    const date = new Date(now)
    date.setDate(date.getDate() - i)
    return {
      date: date.toISOString(),
      count: Math.floor(Math.random() * 50) + 10,
      amount: Math.floor(Math.random() * 5000) + 1000
    }
  }).reverse()

  const transactionsByPlan = [
    { planName: 'Plano Basic', count: 120, percentage: 25 },
    { planName: 'Plano Premium', count: 180, percentage: 37.5 },
    { planName: 'Plano Gold', count: 90, percentage: 18.75 },
    { planName: 'Plano Platinum', count: 90, percentage: 18.75 }
  ]

  const topClinics = [
    { clinicName: 'Clínica Central', count: 234, amount: 45678.90 },
    { clinicName: 'Clínica Norte', count: 189, amount: 38956.70 },
    { clinicName: 'Clínica Sul', count: 167, amount: 32456.80 },
    { clinicName: 'Clínica Oeste', count: 145, amount: 28976.50 },
    { clinicName: 'Clínica Leste', count: 134, amount: 26789.40 },
    { clinicName: 'Clínica Jardins', count: 123, amount: 24567.30 },
    { clinicName: 'Clínica Vila Nova', count: 112, amount: 22345.60 },
    { clinicName: 'Clínica Centro', count: 101, amount: 20123.40 },
    { clinicName: 'Clínica Santana', count: 98, amount: 19876.50 },
    { clinicName: 'Clínica Moema', count: 87, amount: 17654.30 }
  ]

  return {
    transactionsByDay,
    transactionsByPlan,
    topClinics
  }
}

export const dashboardService = {
  async getMetrics(): Promise<DashboardMetrics> {
    try {
      const response = await api.get<{ data: DashboardMetrics }>('/dashboard/metrics')
      return response.data.data
    } catch (error: any) {
      if (error.response?.status === 404) {
        console.warn('Dashboard metrics endpoint not found, using mock data')
        // Simulate API delay
        await new Promise(resolve => setTimeout(resolve, 500))
        return mockMetrics
      }
      throw error
    }
  },

  async getChartData(period: 'week' | 'month' | 'year' = 'month'): Promise<ChartData> {
    try {
      const response = await api.get<{ data: ChartData }>(`/dashboard/charts?period=${period}`)
      return response.data.data
    } catch (error: any) {
      if (error.response?.status === 404) {
        console.warn('Dashboard charts endpoint not found, using mock data')
        // Simulate API delay
        await new Promise(resolve => setTimeout(resolve, 500))
        return generateMockChartData(period)
      }
      throw error
    }
  },
}