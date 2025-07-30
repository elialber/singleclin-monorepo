export interface Patient {
  id: string
  firstName: string
  lastName: string
  fullName: string
  email: string
  phoneNumber?: string
  phone?: string // Alias for phoneNumber
  cpf?: string
  dateOfBirth?: string
  isActive: boolean
  hasPlan?: boolean
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
  phone?: string
  hasPlan?: boolean
  plans?: Array<{
    id: string
    planName: string
    planDescription: string
    remainingCredits: number
    purchaseDate: string
    isActive: boolean
  }>
  recentTransactions?: Array<{
    id: string
    clinicName: string
    planName: string
    creditsUsed: number
    transactionDate: string
    status: 'Pending' | 'Validated' | 'Cancelled'
  }>
  visitHistory?: Array<{
    id: string
    clinicName: string
    date: string
    creditsUsed: number
    planName: string
  }>
  planHistory?: Array<{
    id: string
    planName: string
    purchaseDate: string
    expirationDate: string
    totalCredits: number
    creditsUsed: number
    status: 'Active' | 'Expired' | 'Used'
  }>
}