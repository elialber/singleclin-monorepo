import { useState, useEffect, ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { authService } from '@/services/auth.service'
import { User } from '@/types/user'
import { AuthContext } from './AuthContextDefinition'
import { onAuthStateChange } from '@/services/firebaseAuth'
import { getGoogleRedirectResult } from '@/services/firebaseAuthRedirect'

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const navigate = useNavigate()

  useEffect(() => {
    let isSubscribed = true
    
    // Check for redirect result first
    const checkRedirectResult = async () => {
      try {
        // Only check for redirect result if we don't have tokens
        const hasTokens = authService.getAccessToken() && authService.getRefreshToken()
        if (hasTokens) {
          return
        }
        
        setIsLoading(true)
        const redirectResult = await getGoogleRedirectResult()
        
        if (redirectResult && isSubscribed) {
          console.log('Processing Google redirect login...')
          // Handle redirect login - the auth state change will trigger automatically
          // No need to manually call loginWithGoogle here
        }
      } catch (error) {
        console.error('Redirect result error:', error)
      }
    }

    // Subscribe to Firebase auth state changes
    const unsubscribe = onAuthStateChange(async (firebaseUser) => {
      if (!isSubscribed) return
      
      if (firebaseUser) {
        // If we have a Firebase user but no stored tokens, it might be from a redirect
        const accessToken = authService.getAccessToken()
        if (!accessToken) {
          // This is likely a Google redirect result, handle it
          try {
            const token = await firebaseUser.getIdToken()
            const response = await authService.loginWithGoogle()
            
            authService.setTokens(response.accessToken, response.refreshToken)
            localStorage.setItem('@SingleClin:user', JSON.stringify(response.user))
            setUser(response.user)
            
            // Only navigate if we're on the login page
            if (window.location.pathname === '/login') {
              navigate('/dashboard')
            }
          } catch (error) {
            console.error('Error syncing Firebase user with backend:', error)
            await loadStoredUser()
          }
        } else {
          // We already have tokens, just load the stored user
          await loadStoredUser()
        }
      } else {
        // No Firebase user, try to load from stored tokens
        await loadStoredUser()
      }
    })

    // Check redirect result and initial load
    checkRedirectResult()

    return () => {
      isSubscribed = false
      unsubscribe()
    }
  }, [navigate])

  const loadStoredUser = async () => {
    try {
      const accessToken = authService.getAccessToken()
      const refreshToken = authService.getRefreshToken()
      const storedUser = localStorage.getItem('@SingleClin:user')

      if (!accessToken || !refreshToken) {
        // If no tokens but Firebase user exists, sign out from Firebase
        const { logOut } = await import('@/services/firebaseAuth')
        await logOut()
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
        // Refresh failed, clear everything including Firebase
        authService.clearTokens()
        const { logOut } = await import('@/services/firebaseAuth')
        await logOut()
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

  const loginWithGoogle = async () => {
    try {
      const result = await authService.loginWithGoogle()
      
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

  const register = async (email: string, password: string, fullName: string) => {
    try {
      const result = await authService.register(email, password, fullName)
      
      // Store tokens and user data
      authService.setTokens(result.accessToken, result.refreshToken)
      localStorage.setItem('@SingleClin:user', JSON.stringify(result.user))
      
      setUser(result.user)
      navigate('/dashboard')
    } catch (error) {
      // Clear any partial data on registration failure
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
        loginWithGoogle,
        register,
        logout,
        refreshUser,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}


