import { useState, useEffect, ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { authService } from '@/services/auth.service'
import { User } from '@/types/user'
import { AuthContext } from './AuthContextDefinition'

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const navigate = useNavigate()

  useEffect(() => {
    loadStoredUser()
  }, [])

  const loadStoredUser = async () => {
    try {
      const accessToken = authService.getAccessToken()
      const refreshToken = authService.getRefreshToken()
      const storedUser = localStorage.getItem('@SingleClin:user')

      if (!accessToken || !refreshToken) {
        setIsLoading(false)
        return
      }

      // If we have stored user data and token is not expired, use it
      if (storedUser && !authService.isTokenExpired(accessToken)) {
        setUser(JSON.parse(storedUser))
        setIsLoading(false)
        return
      }

      // Try to refresh the token and get fresh user data
      try {
        const refreshResult = await authService.refreshToken(refreshToken)
        authService.setTokens(refreshResult.accessToken, refreshResult.refreshToken)
        
        // Save user data
        localStorage.setItem('@SingleClin:user', JSON.stringify(refreshResult.user))
        setUser(refreshResult.user)
      } catch (refreshError) {
        // Refresh failed, clear everything
        authService.clearTokens()
        console.error('Failed to refresh token:', refreshError)
      }
    } catch (error) {
      console.error('Error loading user:', error)
      authService.clearTokens()
    } finally {
      setIsLoading(false)
    }
  }

  const login = async (email: string, password: string) => {
    try {
      const result = await authService.login(email, password)
      
      // Store tokens and user data
      authService.setTokens(result.accessToken, result.refreshToken)
      localStorage.setItem('@SingleClin:user', JSON.stringify(result.user))
      
      setUser(result.user)
      navigate('/dashboard')
    } catch (error) {
      // Clear any partial data on login failure
      authService.clearTokens()
      throw error
    }
  }

  const logout = async () => {
    try {
      await authService.logout()
    } catch (error) {
      console.error('Logout error:', error)
    } finally {
      // Always clear local state regardless of API call result
      authService.clearTokens()
      setUser(null)
      navigate('/login')
    }
  }

  const refreshUser = async () => {
    try {
      const userData = await authService.getCurrentUser()
      localStorage.setItem('@SingleClin:user', JSON.stringify(userData))
      setUser(userData)
    } catch (error) {
      console.error('Error refreshing user data:', error)
      // Don't clear tokens here, let the API interceptor handle auth errors
      throw error
    }
  }

  return (
    <AuthContext.Provider
      value={{
        user,
        isLoading,
        isAuthenticated: !!user,
        login,
        logout,
        refreshUser,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}


