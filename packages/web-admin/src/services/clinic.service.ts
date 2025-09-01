import { api } from './api'
import { 
  Clinic, 
  CreateClinicRequest, 
  UpdateClinicRequest, 
  ClinicListResponse, 
  ClinicType 
} from '@/types/clinic'

export interface ClinicQueryParams {
  pageNumber?: number
  pageSize?: number
  searchTerm?: string
  isActive?: boolean
  type?: ClinicType
  city?: string
  state?: string
  sortBy?: 'name' | 'type' | 'createdat' | 'updatedat' | 'isactive' | 'address'
  sortDirection?: 'asc' | 'desc'
}

export const clinicService = {
  async getActiveClinics(): Promise<Clinic[]> {
    const response = await api.get<Clinic[]>('/clinic/active')
    return response.data
  },

  async getClinics(params: ClinicQueryParams = {}): Promise<ClinicListResponse> {
    try {
      const queryParams = new URLSearchParams()
      
      if (params.pageNumber) queryParams.append('pageNumber', params.pageNumber.toString())
      if (params.pageSize) queryParams.append('pageSize', params.pageSize.toString())
      if (params.searchTerm) queryParams.append('searchTerm', params.searchTerm)
      if (params.isActive !== undefined) queryParams.append('isActive', params.isActive.toString())
      if (params.type !== undefined) queryParams.append('type', params.type.toString())
      if (params.city) queryParams.append('city', params.city)
      if (params.state) queryParams.append('state', params.state)
      if (params.sortBy) queryParams.append('sortBy', params.sortBy)
      if (params.sortDirection) queryParams.append('sortDirection', params.sortDirection)

      const response = await api.get<any>(`/clinic?${queryParams.toString()}`)
      
      // Mapear a resposta do backend para o formato esperado pelo frontend
      return {
        data: response.data.items || [],
        total: response.data.totalCount || 0,
        totalCount: response.data.totalCount || 0,
        pageNumber: response.data.pageNumber || 1,
        pageSize: response.data.pageSize || 10,
        totalPages: response.data.totalPages || 0
      } as ClinicListResponse
    } catch (error: any) {
      // Fallback to active clinics endpoint and simulate pagination for development
      if (error.response?.status === 404 || error.response?.status === 403) {
        console.warn('Full clinic endpoint not accessible, using active clinics with client-side filtering')
        
        const activeClinics = await this.getActiveClinics()
        
        // Apply client-side filtering and sorting
        let filteredClinics = activeClinics

        if (params.searchTerm) {
          const searchLower = params.searchTerm.toLowerCase()
          filteredClinics = filteredClinics.filter(clinic => 
            clinic.name.toLowerCase().includes(searchLower) ||
            clinic.address?.toLowerCase().includes(searchLower) ||
            clinic.email?.toLowerCase().includes(searchLower)
          )
        }

        if (params.type !== undefined) {
          filteredClinics = filteredClinics.filter(clinic => clinic.type === params.type)
        }

        if (params.isActive !== undefined) {
          filteredClinics = filteredClinics.filter(clinic => clinic.isActive === params.isActive)
        }

        // Apply sorting
        if (params.sortBy) {
          filteredClinics.sort((a, b) => {
            const direction = params.sortDirection === 'desc' ? -1 : 1
            
            switch (params.sortBy) {
              case 'name':
                return direction * a.name.localeCompare(b.name)
              case 'type':
                return direction * (a.type - b.type)
              case 'address':
                return direction * a.address.localeCompare(b.address)
              case 'createdat':
                return direction * (new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime())
              case 'updatedat':
                return direction * (new Date(a.updatedAt).getTime() - new Date(b.updatedAt).getTime())
              case 'isactive':
                return direction * (Number(a.isActive) - Number(b.isActive))
              default:
                return 0
            }
          })
        }

        // Apply pagination
        const pageSize = params.pageSize || 10
        const pageNumber = params.pageNumber || 1
        const startIndex = (pageNumber - 1) * pageSize
        const endIndex = startIndex + pageSize
        const paginatedClinics = filteredClinics.slice(startIndex, endIndex)

        return {
          data: paginatedClinics,
          total: filteredClinics.length,
          totalCount: filteredClinics.length,
          pageNumber: pageNumber,
          pageSize: pageSize,
          totalPages: Math.ceil(filteredClinics.length / pageSize)
        }
      }
      throw error
    }
  },

  async getClinic(id: string): Promise<Clinic> {
    const response = await api.get<Clinic>(`/clinic/${id}`)
    return response.data
  },

  async createClinic(data: CreateClinicRequest): Promise<Clinic> {
    const response = await api.post<Clinic>('/clinic', data)
    return response.data
  },

  async updateClinic(id: string, data: UpdateClinicRequest): Promise<Clinic> {
    const response = await api.put<Clinic>(`/clinic/${id}`, data)
    return response.data
  },

  async deleteClinic(id: string): Promise<void> {
    await api.delete(`/clinic/${id}`)
  },

  async toggleClinicStatus(id: string): Promise<Clinic> {
    const response = await api.patch<Clinic>(`/clinic/${id}/toggle-status`)
    return response.data
  },

  async getClinicStatistics(): Promise<Record<string, number>> {
    const response = await api.get<Record<string, number>>('/clinic/statistics')
    return response.data
  },

  async getClinicOptions(): Promise<Array<{ id: string; name: string }>> {
    const clinics = await this.getActiveClinics()
    return clinics.map(clinic => ({
      id: clinic.id,
      name: clinic.name
    }))
  },
}