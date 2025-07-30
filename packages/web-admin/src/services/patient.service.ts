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

    const response = await api.get<PatientListResponse>(`/patients?${queryParams.toString()}`)
    return response.data
  },

  async getPatient(id: string): Promise<Patient> {
    const response = await api.get<{ data: Patient }>(`/patients/${id}`)
    return response.data.data
  },

  async getPatientDetails(id: string): Promise<PatientDetails> {
    const response = await api.get<{ data: PatientDetails }>(`/patients/${id}/details`)
    return response.data.data
  },
}