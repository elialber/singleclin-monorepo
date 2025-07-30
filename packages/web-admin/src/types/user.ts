export type UserRole = 'Administrator' | 'ClinicOrigin' | 'ClinicPartner' | 'Patient'

export interface User {
  id: string
  email: string
  firstName: string
  lastName: string
  fullName: string
  role: UserRole
  isActive: boolean
  isEmailVerified: boolean
  phoneNumber?: string
  photoUrl?: string
  clinicId?: string
  createdAt: string
  updatedAt: string
}

export interface LoginResponse {
  user: User
  token: string
  refreshToken: string
  expiresIn: number
}

export interface AuthResponse {
  accessToken: string
  refreshToken: string
  expiresIn: number
  userId: string
  email: string
  fullName: string
  role: UserRole
  clinicId?: string
  isFirstLogin: boolean
}