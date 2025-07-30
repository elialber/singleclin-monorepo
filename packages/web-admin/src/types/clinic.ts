export type ClinicType = 'Origin' | 'Partner'

export interface Clinic {
  id: string
  name: string
  email: string
  phone: string
  address: string
  city: string
  state: string
  zipCode: string
  type: ClinicType
  isActive: boolean
  registrationNumber: string
  responsibleDoctor: string
  createdAt: string
  updatedAt: string
}

export interface ClinicListResponse {
  data: Clinic[]
  total: number
  page: number
  limit: number
}

export interface ClinicFilters {
  name?: string
  type?: ClinicType
  city?: string
  isActive?: boolean
}