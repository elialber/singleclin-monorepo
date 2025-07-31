import { api } from './api'
import { Clinic, ClinicListResponse, ClinicFilters } from '@/types/clinic'

export interface ClinicQueryParams extends ClinicFilters {
  page?: number
  limit?: number
}

export const clinicService = {
  async getClinics(params: ClinicQueryParams = {}): Promise<ClinicListResponse> {
    const queryParams = new URLSearchParams()
    
    if (params.page) queryParams.append('page', params.page.toString())
    if (params.limit) queryParams.append('limit', params.limit.toString())
    if (params.name) queryParams.append('name', params.name)
    if (params.type) queryParams.append('type', params.type)
    if (params.city) queryParams.append('city', params.city)
    if (params.isActive !== undefined) queryParams.append('isActive', params.isActive.toString())

    try {
      const response = await api.get<ClinicListResponse>(`/clinics?${queryParams.toString()}`)
      return response.data
    } catch (error: any) {
      if (error.response?.status === 404) {
        // Return mock data if endpoint not implemented yet
        console.warn('Clinics endpoint not implemented, returning mock data')
        
        const mockClinics: Clinic[] = [
          {
            id: '1',
            name: 'Clínica Saúde Total',
            email: 'contato@saudetotal.com',
            phone: '(11) 3456-7890',
            address: 'Rua das Flores, 123',
            city: 'São Paulo',
            state: 'SP',
            zipCode: '01234-567',
            type: 'Origin',
            isActive: true,
            registrationNumber: 'CRM-SP 123456',
            responsibleDoctor: 'Dr. João Silva',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '2',
            name: 'Clínica Bem Estar',
            email: 'atendimento@bemestar.com',
            phone: '(11) 2345-6789',
            address: 'Av. Paulista, 1000',
            city: 'São Paulo',
            state: 'SP',
            zipCode: '01310-100',
            type: 'Partner',
            isActive: true,
            registrationNumber: 'CRM-SP 234567',
            responsibleDoctor: 'Dra. Maria Santos',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '3',
            name: 'Centro Médico Vida',
            email: 'contato@centrovida.com',
            phone: '(21) 3456-7890',
            address: 'Rua do Ouvidor, 50',
            city: 'Rio de Janeiro',
            state: 'RJ',
            zipCode: '20040-030',
            type: 'Partner',
            isActive: true,
            registrationNumber: 'CRM-RJ 345678',
            responsibleDoctor: 'Dr. Carlos Oliveira',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '4',
            name: 'Policlínica Central',
            email: 'central@policlinica.com',
            phone: '(31) 3456-7890',
            address: 'Av. Afonso Pena, 500',
            city: 'Belo Horizonte',
            state: 'MG',
            zipCode: '30130-001',
            type: 'Partner',
            isActive: false,
            registrationNumber: 'CRM-MG 456789',
            responsibleDoctor: 'Dra. Ana Paula Lima',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          },
        ]

        // Apply filters
        let filtered = [...mockClinics]
        
        if (params.name) {
          filtered = filtered.filter(c => 
            c.name.toLowerCase().includes(params.name!.toLowerCase())
          )
        }
        
        if (params.type) {
          filtered = filtered.filter(c => c.type === params.type)
        }
        
        if (params.city) {
          filtered = filtered.filter(c => 
            c.city.toLowerCase().includes(params.city!.toLowerCase())
          )
        }
        
        if (params.isActive !== undefined) {
          filtered = filtered.filter(c => c.isActive === params.isActive)
        }

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

  async getClinic(id: string): Promise<Clinic> {
    const response = await api.get<{ data: Clinic }>(`/clinics/${id}`)
    return response.data.data
  },

  async getClinicOptions(): Promise<Array<{ id: string; name: string }>> {
    const response = await api.get<{ data: Array<{ id: string; name: string }> }>('/clinics/options')
    return response.data.data
  },
}