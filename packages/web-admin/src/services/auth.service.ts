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
    try {
      console.log('Starting login process for:', email)
      
      // First authenticate with Firebase
      const firebaseResult = await signInWithEmail(email, password)
      console.log('Firebase authentication successful, got token')
      
      // Then authenticate with our backend using the Firebase token
      console.log('Sending token to backend...')
      const response = await api.post<AuthResponse>('/auth/login/firebase', {
        firebaseToken: firebaseResult.token,
        deviceInfo: navigator.userAgent,
        rememberMe: true
      })
      
      console.log('Backend authentication successful:', {
        userId: response.data.userId,
        email: response.data.email,
        role: response.data.role
      })
      
      return transformAuthResponse(response.data)
    } catch (error: any) {
      console.error('Login error details:', {
        code: error.code,
        message: error.message,
        response: error.response?.data,
        status: error.response?.status,
        email,
      })
      
      // Check if it's a backend error
      if (error.response) {
        console.error('Backend error:', {
          status: error.response.status,
          data: error.response.data,
          headers: error.response.headers
        })
        
        if (error.response.status === 400 || error.response.status === 401) {
          throw new Error(error.response.data?.detail || error.response.data?.message || 'Erro na autenticação com o servidor')
        } else if (error.response.status === 404) {
          throw new Error('Endpoint de autenticação não encontrado. Verifique se o backend está rodando.')
        } else if (error.response.status >= 500) {
          throw new Error('Erro no servidor. Tente novamente mais tarde.')
        }
      }
      
      // If Firebase login fails, it might be a timing issue after registration
      // Try with multiple retry attempts
      if (error.code === 'auth/invalid-credential' || 
          error.code === 'auth/user-not-found' ||
          error.code === 'auth/wrong-password') {
        
        console.log('Firebase login failed, will retry with increasing delays...')
        
        // Try up to 3 times with increasing delays
        for (let attempt = 1; attempt <= 3; attempt++) {
          try {
            const delay = attempt * 2000 // 2s, 4s, 6s
            console.log(`Retry attempt ${attempt} after ${delay}ms delay...`)
            await new Promise(resolve => setTimeout(resolve, delay))
            
            const firebaseResult = await signInWithEmail(email, password)
            const response = await api.post<AuthResponse>('/auth/login/firebase', {
              firebaseToken: firebaseResult.token,
              deviceInfo: navigator.userAgent,
              rememberMe: true
            })
            return transformAuthResponse(response.data)
          } catch (retryError: any) {
            console.error(`Retry attempt ${attempt} failed:`, retryError.code)
            if (attempt === 3) {
              // Last attempt failed, throw the original error
              throw error
            }
            // Continue to next attempt
          }
        }
      }
      throw error
    }
  },

  async loginWithGoogle(): Promise<LoginResult> {
    // Authenticate with Google via Firebase
    const firebaseResult = await signInWithGoogle()
    
    // Authenticate with our backend using the Firebase token
    const response = await api.post<AuthResponse>('/auth/login/firebase', {
      firebaseToken: firebaseResult.token,
      deviceInfo: navigator.userAgent,
      rememberMe: true
    })
    return transformAuthResponse(response.data)
  },

  async register(email: string, password: string, fullName: string): Promise<LoginResult> {
    // Register with our backend (which will create the user in Firebase)
    const response = await api.post<AuthResponse>('/auth/register', {
      email,
      password,
      confirmPassword: password,
      fullName,
      birthDate: '1990-01-01', // Default birthdate for now
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