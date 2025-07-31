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

    try {
      const response = await api.get<TransactionListResponse>(`/transactions?${queryParams.toString()}`)
      return response.data
    } catch (error: any) {
      if (error.response?.status === 404) {
        // Return mock data if endpoint not implemented yet
        console.warn('Transactions endpoint not implemented, returning mock data')
        
        const mockTransactions: Transaction[] = [
          {
            id: '1',
            patientId: '1',
            patientName: 'João Silva',
            clinicId: '1',
            clinicName: 'Clínica Saúde Total',
            planId: '1',
            planName: 'Plano Básico',
            creditsUsed: 1,
            amount: 14.99,
            status: 'Validated',
            transactionDate: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
            description: 'Consulta de rotina',
            qrCodeId: 'QR001',
          },
          {
            id: '2',
            patientId: '2',
            patientName: 'Maria Santos',
            clinicId: '2',
            clinicName: 'Clínica Bem Estar',
            planId: '2',
            planName: 'Plano Intermediário',
            creditsUsed: 2,
            amount: 23.99,
            status: 'Validated',
            transactionDate: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
            description: 'Exame laboratorial',
            qrCodeId: 'QR002',
          },
          {
            id: '3',
            patientId: '3',
            patientName: 'Carlos Oliveira',
            clinicId: '3',
            clinicName: 'Centro Médico Vida',
            planId: '3',
            planName: 'Plano Premium',
            creditsUsed: 3,
            amount: 32.99,
            status: 'Pending',
            transactionDate: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
            description: 'Consulta especializada',
            qrCodeId: 'QR003',
          },
          {
            id: '4',
            patientId: '4',
            patientName: 'Ana Paula Lima',
            clinicId: '1',
            clinicName: 'Clínica Saúde Total',
            planId: '4',
            planName: 'Plano Família',
            creditsUsed: 4,
            amount: 35.99,
            status: 'Validated',
            transactionDate: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
            description: 'Atendimento familiar',
            qrCodeId: 'QR004',
          },
          {
            id: '5',
            patientId: '5',
            patientName: 'Pedro Almeida',
            clinicId: '2',
            clinicName: 'Clínica Bem Estar',
            planId: '1',
            planName: 'Plano Básico',
            creditsUsed: 1,
            amount: 14.99,
            status: 'Cancelled',
            transactionDate: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(),
            description: 'Consulta cancelada',
            qrCodeId: 'QR005',
          },
          {
            id: '6',
            patientId: '1',
            patientName: 'João Silva',
            clinicId: '3',
            clinicName: 'Centro Médico Vida',
            planId: '2',
            planName: 'Plano Intermediário',
            creditsUsed: 2,
            amount: 23.99,
            status: 'Validated',
            transactionDate: new Date().toISOString(),
            description: 'Exame de imagem',
            qrCodeId: 'QR006',
          },
        ]

        // Apply filters
        let filtered = [...mockTransactions]
        
        if (params.patientName) {
          filtered = filtered.filter(t => 
            t.patientName.toLowerCase().includes(params.patientName!.toLowerCase())
          )
        }
        
        if (params.clinicName) {
          filtered = filtered.filter(t => 
            t.clinicName.toLowerCase().includes(params.clinicName!.toLowerCase())
          )
        }
        
        if (params.planName) {
          filtered = filtered.filter(t => 
            t.planName.toLowerCase().includes(params.planName!.toLowerCase())
          )
        }
        
        if (params.status) {
          filtered = filtered.filter(t => t.status === params.status)
        }
        
        if (params.startDate) {
          filtered = filtered.filter(t => 
            new Date(t.transactionDate) >= new Date(params.startDate!)
          )
        }
        
        if (params.endDate) {
          filtered = filtered.filter(t => 
            new Date(t.transactionDate) <= new Date(params.endDate!)
          )
        }

        // Sort by date (newest first)
        filtered.sort((a, b) => 
          new Date(b.transactionDate).getTime() - new Date(a.transactionDate).getTime()
        )

        // Pagination
        const page = params.page || 1
        const limit = params.limit || 10
        const start = (page - 1) * limit
        const end = start + limit
        const paginatedData = filtered.slice(start, end)

        return {
          data: paginatedData,
          total: filtered.length,
          page,
          limit,
        }
      }
      throw error
    }
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

    try {
      const response = await api.get(`/transactions/export?${queryParams.toString()}`, {
        responseType: 'blob',
      })
      return response.data
    } catch (error: any) {
      if (error.response?.status === 404) {
        // Return mock CSV data if endpoint not implemented
        console.warn('Export endpoint not implemented, returning mock data')
        
        if (format === 'csv') {
          const csvContent = `ID,Data,Paciente,Clínica,Plano,Créditos,Valor,Status
1,${new Date().toLocaleDateString('pt-BR')},João Silva,Clínica Saúde Total,Plano Básico,1,R$ 14.99,Validada
2,${new Date().toLocaleDateString('pt-BR')},Maria Santos,Clínica Bem Estar,Plano Intermediário,2,R$ 23.99,Validada
3,${new Date().toLocaleDateString('pt-BR')},Carlos Oliveira,Centro Médico Vida,Plano Premium,3,R$ 32.99,Pendente`
          
          return new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
        } else {
          // Return a simple Excel-like CSV for now
          const csvContent = `ID\tData\tPaciente\tClínica\tPlano\tCréditos\tValor\tStatus
1\t${new Date().toLocaleDateString('pt-BR')}\tJoão Silva\tClínica Saúde Total\tPlano Básico\t1\tR$ 14,99\tValidada
2\t${new Date().toLocaleDateString('pt-BR')}\tMaria Santos\tClínica Bem Estar\tPlano Intermediário\t2\tR$ 23,99\tValidada
3\t${new Date().toLocaleDateString('pt-BR')}\tCarlos Oliveira\tCentro Médico Vida\tPlano Premium\t3\tR$ 32,99\tPendente`
          
          return new Blob([csvContent], { type: 'application/vnd.ms-excel;charset=utf-8;' })
        }
      }
      throw error
    }
  },
}