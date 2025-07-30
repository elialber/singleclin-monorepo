import { api } from './api'
import { User, AuthResponse } from '@/types/user'

export interface LoginRequest {
  email: string
  password: string
}

export interface RefreshTokenRequest {
  refreshToken: string
  deviceInfo?: string
}

export interface LoginResult {
  user: User
  accessToken: string
  refreshToken: string
  expiresIn: number
}

// Transform backend AuthResponse to our LoginResult format
const transformAuthResponse = (authResponse: AuthResponse): LoginResult => {
  const user: User = {
    id: authResponse.userId,
    email: authResponse.email,
    firstName: authResponse.fullName.split(' ')[0] || '',
    lastName: authResponse.fullName.split(' ').slice(1).join(' ') || '',
    fullName: authResponse.fullName,
    role: authResponse.role,
    isActive: true,
    isEmailVerified: true,
    clinicId: authResponse.clinicId,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  }

  return {
    user,
    accessToken: authResponse.accessToken,
    refreshToken: authResponse.refreshToken,
    expiresIn: authResponse.expiresIn,
  }
}

export const authService = {
  async login(email: string, password: string): Promise<LoginResult> {
    const response = await api.post<AuthResponse>('/auth/login', {
      email,
      password,
    })
    return transformAuthResponse(response.data)
  },

  async refreshToken(refreshToken: string): Promise<LoginResult> {
    const response = await api.post<AuthResponse>('/auth/refresh', {
      refreshToken,
      deviceInfo: navigator.userAgent,
    })
    return transformAuthResponse(response.data)
  },

  async getCurrentUser(): Promise<User> {
    const response = await api.get<{ data: User }>('/auth/profile')
    return response.data.data
  },

  async updateProfile(data: Partial<User>): Promise<User> {
    const response = await api.put<{ data: User }>('/auth/profile', data)
    return response.data.data
  },

  async changePassword(
    currentPassword: string,
    newPassword: string,
  ): Promise<void> {
    await api.post('/auth/change-password', {
      currentPassword,
      newPassword,
    })
  },

  async logout(): Promise<void> {
    try {
      await api.post('/auth/logout')
    } catch (error) {
      // Even if logout fails on server, clear local storage
      console.warn('Logout request failed, but clearing local storage anyway:', error)
    }
  },

  // Helper methods for token management
  getAccessToken(): string | null {
    return localStorage.getItem('@SingleClin:accessToken')
  },

  getRefreshToken(): string | null {
    return localStorage.getItem('@SingleClin:refreshToken')
  },

  setTokens(accessToken: string, refreshToken: string): void {
    localStorage.setItem('@SingleClin:accessToken', accessToken)
    localStorage.setItem('@SingleClin:refreshToken', refreshToken)
  },

  clearTokens(): void {
    localStorage.removeItem('@SingleClin:accessToken')
    localStorage.removeItem('@SingleClin:refreshToken')
    localStorage.removeItem('@SingleClin:user')
  },

  // Check if access token is expired
  isTokenExpired(token: string): boolean {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]))
      const currentTime = Date.now() / 1000
      return payload.exp < currentTime
    } catch {
      return true
    }
  },
}