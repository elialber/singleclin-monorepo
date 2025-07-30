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

    const response = await api.get<ClinicListResponse>(`/clinics?${queryParams.toString()}`)
    return response.data
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