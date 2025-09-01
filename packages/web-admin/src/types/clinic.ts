export enum ClinicType {
  Regular = 0,
  Origin = 1,
  Partner = 2,
  Administrative = 3,
}

export interface Clinic {
  id: string
  name: string
  type: ClinicType
  address: string
  phoneNumber?: string
  email?: string
  cnpj?: string
  isActive: boolean
  latitude?: number
  longitude?: number
  createdAt: string
  updatedAt: string
  transactionCount: number
  typeDisplayName: string
}

export interface CreateClinicRequest {
  name: string
  type: ClinicType
  address: string
  phoneNumber?: string
  email?: string
  cnpj?: string
  isActive?: boolean
}

export interface UpdateClinicRequest extends Partial<CreateClinicRequest> {
  isActive?: boolean
}

export interface ClinicListResponse {
  data: Clinic[]
  total: number
  totalCount: number
  pageNumber: number
  pageSize: number
  totalPages: number
}

// Helper functions for display
export const getClinicTypeLabel = (type: ClinicType): string => {
  switch (type) {
    case ClinicType.Regular:
      return 'Regular'
    case ClinicType.Origin:
      return 'Origem'
    case ClinicType.Partner:
      return 'Parceira'
    case ClinicType.Administrative:
      return 'Administrativa'
    default:
      return 'Desconhecido'
  }
}

export const getClinicTypeColor = (type: ClinicType): 'default' | 'primary' | 'secondary' | 'success' | 'warning' => {
  switch (type) {
    case ClinicType.Origin:
      return 'primary'
    case ClinicType.Partner:
      return 'secondary'
    case ClinicType.Administrative:
      return 'success'
    case ClinicType.Regular:
    default:
      return 'default'
  }
}