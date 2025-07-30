export interface Patient {
  id: string
  firstName: string
  lastName: string
  fullName: string
  email: string
  phoneNumber?: string
  cpf?: string
  dateOfBirth?: string
  isActive: boolean
  createdAt: string
  updatedAt: string
  
  // Current plan info
  currentPlan?: {
    id: string
    name: string
    creditsRemaining: number
    expirationDate: string
  }
}

export interface PatientFilters {
  search?: string // name, email, or CPF
  isActive?: boolean
  hasPlan?: boolean
}

export interface PatientListResponse {
  data: Patient[]
  total: number
  page: number
  limit: number
}

export interface PatientDetails extends Patient {
  visitHistory: Array<{
    id: string
    clinicName: string
    date: string
    creditsUsed: number
    planName: string
  }>
  planHistory: Array<{
    id: string
    planName: string
    purchaseDate: string
    expirationDate: string
    totalCredits: number
    creditsUsed: number
    status: 'Active' | 'Expired' | 'Used'
  }>
}