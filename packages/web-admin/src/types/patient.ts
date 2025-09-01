export interface Patient {
  id: string
  email: string
  firstName: string
  lastName: string
  fullName: string
  role: string
  isActive: boolean
  isEmailVerified: boolean
  phoneNumber?: string
  clinicId?: string
  createdAt: string
  updatedAt: string
  
  // Computed/additional fields for patient view
  cpf?: string
  dateOfBirth?: string
  hasPlan?: boolean
  
  // Current plan info (from related data)
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

export interface CreatePatientRequest {
  email: string
  firstName: string
  lastName: string
  phoneNumber?: string
  clinicId?: string
  password: string
  isActive?: boolean
}

export interface UpdatePatientRequest extends Partial<Omit<CreatePatientRequest, 'password'>> {
  isActive?: boolean
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