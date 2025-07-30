import { ReactNode } from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import { Box, CircularProgress, Typography } from '@mui/material'
import { useAuth } from '@/contexts/AuthContext'

interface ProtectedRouteProps {
  children: ReactNode
  requiredRole?: 'Administrator' | 'ClinicOrigin' | 'ClinicPartner'
  fallbackPath?: string
}

export default function ProtectedRoute({ 
  children, 
  requiredRole,
  fallbackPath = '/login' 
}: ProtectedRouteProps) {
  const { isAuthenticated, isLoading, user } = useAuth()
  const location = useLocation()

  // Show loading spinner while authentication state is being determined
  if (isLoading) {
    return (
      <Box
        display="flex"
        flexDirection="column"
        justifyContent="center"
        alignItems="center"
        minHeight="100vh"
        gap={2}
      >
        <CircularProgress size={40} />
        <Typography variant="body2" color="text.secondary">
          Verificando autenticação...
        </Typography>
      </Box>
    )
  }

  // Redirect to login if not authenticated
  if (!isAuthenticated) {
    return <Navigate to={fallbackPath} state={{ from: location }} replace />
  }

  // Check role-based access if required
  if (requiredRole && user?.role !== requiredRole) {
    // For role-based restrictions, show access denied instead of redirecting
    return (
      <Box
        display="flex"
        flexDirection="column"
        justifyContent="center"
        alignItems="center"
        minHeight="100vh"
        gap={2}
        sx={{ p: 3, textAlign: 'center' }}
      >
        <Typography variant="h5" color="error" gutterBottom>
          Acesso Negado
        </Typography>
        <Typography variant="body1" color="text.secondary" sx={{ mb: 2 }}>
          Você não tem permissão para acessar esta página.
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Permissão necessária: {requiredRole}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Sua permissão atual: {user?.role || 'Nenhuma'}
        </Typography>
      </Box>
    )
  }

  return <>{children}</>
}