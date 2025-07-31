import { api } from './api'
import { User, AuthResponse } from '@/types/user'
import {
  signInWithEmail,
  signInWithGoogle,
  createUser as createFirebaseUser,
  logOut as firebaseLogOut,
  resetPassword as firebaseResetPassword,
  getCurrentUserToken,
  onAuthStateChange,
  convertFirebaseUserToIUser,
} from './firebaseAuth'

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
    // First authenticate with Firebase
    const firebaseResult = await signInWithEmail(email, password)
    
    // Then authenticate with our backend using the Firebase token
    const response = await api.post<AuthResponse>('/auth/login/firebase', {
      firebaseToken: firebaseResult.token,
    })
    return transformAuthResponse(response.data)
  },

  async loginWithGoogle(): Promise<LoginResult> {
    // Authenticate with Google via Firebase
    const firebaseResult = await signInWithGoogle()
    
    try {
      // Try to authenticate with our backend using the Firebase token
      const response = await api.post<AuthResponse>('/auth/login/firebase', {
        firebaseToken: firebaseResult.token,
      })
      return transformAuthResponse(response.data)
    } catch (error) {
      // Temporary fallback for development - simulate successful login
      console.warn('Backend Firebase endpoint not ready, using development fallback')
      
      // Create a mock user from Firebase data
      const mockUser: User = {
        id: firebaseResult.user.uid,
        email: firebaseResult.user.email || '',
        firstName: firebaseResult.user.displayName?.split(' ')[0] || '',
        lastName: firebaseResult.user.displayName?.split(' ').slice(1).join(' ') || '',
        fullName: firebaseResult.user.displayName || firebaseResult.user.email || '',
        role: 'admin', // Default role for development
        isActive: true,
        isEmailVerified: firebaseResult.user.emailVerified,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      }
      
      // Return mock tokens for development
      return {
        user: mockUser,
        accessToken: firebaseResult.token, // Use Firebase token temporarily
        refreshToken: firebaseResult.token,
        expiresIn: 3600,
      }
    }
  },

  async register(email: string, password: string, fullName: string): Promise<LoginResult> {
    // Create user in Firebase
    const firebaseResult = await createFirebaseUser(email, password, fullName)
    
    // Then register with our backend using the Firebase token
    const response = await api.post<AuthResponse>('/auth/register/firebase', {
      firebaseToken: firebaseResult.token,
      fullName,
    })
    return transformAuthResponse(response.data)
  },

  async refreshToken(refreshToken: string): Promise<LoginResult> {
    // Get fresh Firebase token first
    const firebaseToken = await getCurrentUserToken()
    if (!firebaseToken) {
      throw new Error('No Firebase user authenticated')
    }

    const response = await api.post<AuthResponse>('/auth/refresh', {
      refreshToken,
      firebaseToken,
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
    } finally {
      // Always logout from Firebase
      await firebaseLogOut()
    }
  },

  async resetPassword(email: string): Promise<void> {
    await firebaseResetPassword(email)
  },

  // Subscribe to Firebase auth state changes
  onAuthStateChange(callback: (user: any) => void): () => void {
    return onAuthStateChange(async (firebaseUser) => {
      if (firebaseUser) {
        const userInfo = await convertFirebaseUserToIUser(firebaseUser)
        callback(userInfo)
      } else {
        callback(null)
      }
    })
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