import { api } from './api'
import { Patient, PatientListResponse, PatientFilters, PatientDetails } from '@/types/patient'

export interface PatientQueryParams extends PatientFilters {
  page?: number
  limit?: number
}

export const patientService = {
  async getPatients(params: PatientQueryParams = {}): Promise<PatientListResponse> {
    const queryParams = new URLSearchParams()
    
    if (params.page) queryParams.append('page', params.page.toString())
    if (params.limit) queryParams.append('limit', params.limit.toString())
    if (params.search) queryParams.append('search', params.search)
    if (params.isActive !== undefined) queryParams.append('isActive', params.isActive.toString())
    if (params.hasPlan !== undefined) queryParams.append('hasPlan', params.hasPlan.toString())

    try {
      const response = await api.get<PatientListResponse>(`/patients?${queryParams.toString()}`)
      return response.data
    } catch (error: any) {
      if (error.response?.status === 404) {
        // Return mock data if endpoint not implemented yet
        console.warn('Patients endpoint not implemented, returning mock data')
        
        const mockPatients: Patient[] = [
          {
            id: '1',
            firstName: 'João',
            lastName: 'Silva',
            fullName: 'João Silva',
            email: 'joao.silva@email.com',
            phone: '(11) 98765-4321',
            cpf: '123.456.789-00',
            dateOfBirth: '1985-05-15',
            isActive: true,
            hasPlan: true,
            createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
            updatedAt: new Date().toISOString(),
            currentPlan: {
              id: '1',
              name: 'Plano Básico',
              creditsRemaining: 8,
              expirationDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
            },
          },
          {
            id: '2',
            firstName: 'Maria',
            lastName: 'Santos',
            fullName: 'Maria Santos',
            email: 'maria.santos@email.com',
            phone: '(21) 97654-3210',
            cpf: '987.654.321-00',
            isActive: true,
            hasPlan: true,
            createdAt: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000).toISOString(),
            updatedAt: new Date().toISOString(),
            currentPlan: {
              id: '2',
              name: 'Plano Intermediário',
              creditsRemaining: 20,
              expirationDate: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000).toISOString(),
            },
          },
          {
            id: '3',
            firstName: 'Carlos',
            lastName: 'Oliveira',
            fullName: 'Carlos Oliveira',
            email: 'carlos.oliveira@email.com',
            phone: '(31) 96543-2109',
            isActive: true,
            hasPlan: false,
            createdAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '4',
            firstName: 'Ana',
            lastName: 'Paula Lima',
            fullName: 'Ana Paula Lima',
            email: 'ana.lima@email.com',
            phone: '(41) 95432-1098',
            cpf: '456.789.123-00',
            isActive: false,
            hasPlan: true,
            createdAt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString(),
            updatedAt: new Date().toISOString(),
            currentPlan: {
              id: '4',
              name: 'Plano Família',
              creditsRemaining: 95,
              expirationDate: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
            },
          },
          {
            id: '5',
            firstName: 'Pedro',
            lastName: 'Almeida',
            fullName: 'Pedro Almeida',
            email: 'pedro.almeida@email.com',
            phone: '(51) 94321-0987',
            isActive: true,
            hasPlan: false,
            createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '6',
            firstName: 'Fernanda',
            lastName: 'Costa',
            fullName: 'Fernanda Costa',
            email: 'fernanda.costa@email.com',
            phone: '(61) 93210-9876',
            cpf: '789.123.456-00',
            isActive: true,
            hasPlan: true,
            createdAt: new Date(Date.now() - 45 * 24 * 60 * 60 * 1000).toISOString(),
            updatedAt: new Date().toISOString(),
            currentPlan: {
              id: '3',
              name: 'Plano Premium',
              creditsRemaining: 45,
              expirationDate: new Date(Date.now() + 120 * 24 * 60 * 60 * 1000).toISOString(),
            },
          },
        ]

        // Apply filters
        let filtered = [...mockPatients]
        
        if (params.search) {
          const searchLower = params.search.toLowerCase()
          filtered = filtered.filter(p => 
            p.fullName.toLowerCase().includes(searchLower) ||
            p.email.toLowerCase().includes(searchLower) ||
            (p.cpf && p.cpf.includes(params.search!))
          )
        }
        
        if (params.isActive !== undefined) {
          filtered = filtered.filter(p => p.isActive === params.isActive)
        }
        
        if (params.hasPlan !== undefined) {
          filtered = filtered.filter(p => p.hasPlan === params.hasPlan)
        }

        // Sort by creation date (newest first)
        filtered.sort((a, b) => 
          new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
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

  async getPatient(id: string): Promise<Patient> {
    const response = await api.get<{ data: Patient }>(`/patients/${id}`)
    return response.data.data
  },

  async getPatientDetails(id: string): Promise<PatientDetails> {
    try {
      const response = await api.get<{ data: PatientDetails }>(`/patients/${id}/details`)
      return response.data.data
    } catch (error: any) {
      if (error.response?.status === 404) {
        // Return mock data if endpoint not implemented yet
        console.warn('Patient details endpoint not implemented, returning mock data')
        
        // Find the basic patient data first
        const patients = await this.getPatients({ limit: 100 })
        const patient = patients.data.find(p => p.id === id)
        
        if (!patient) {
          throw new Error('Patient not found')
        }

        const mockDetails: PatientDetails = {
          ...patient,
          plans: patient.hasPlan ? [
            {
              id: '1',
              planName: patient.currentPlan?.name || 'Plano Básico',
              planDescription: 'Ideal para consultas de rotina e exames simples',
              remainingCredits: patient.currentPlan?.creditsRemaining || 10,
              purchaseDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
              isActive: true,
            }
          ] : [],
          recentTransactions: patient.hasPlan ? [
            {
              id: '1',
              clinicName: 'Clínica Saúde Total',
              planName: patient.currentPlan?.name || 'Plano Básico',
              creditsUsed: 1,
              transactionDate: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
              status: 'Validated',
            },
            {
              id: '2',
              clinicName: 'Centro Médico Vida',
              planName: patient.currentPlan?.name || 'Plano Básico',
              creditsUsed: 2,
              transactionDate: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
              status: 'Validated',
            },
          ] : [],
          visitHistory: patient.hasPlan ? [
            {
              id: '1',
              clinicName: 'Clínica Saúde Total',
              date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
              creditsUsed: 1,
              planName: patient.currentPlan?.name || 'Plano Básico',
            },
            {
              id: '2',
              clinicName: 'Centro Médico Vida',
              date: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
              creditsUsed: 2,
              planName: patient.currentPlan?.name || 'Plano Básico',
            },
          ] : [],
          planHistory: patient.hasPlan ? [
            {
              id: '1',
              planName: patient.currentPlan?.name || 'Plano Básico',
              purchaseDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
              expirationDate: patient.currentPlan?.expirationDate || new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
              totalCredits: 10,
              creditsUsed: 10 - (patient.currentPlan?.creditsRemaining || 10),
              status: 'Active',
            },
          ] : [],
        }

        return mockDetails
      }
      throw error
    }
  },
}