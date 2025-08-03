import { Outlet, Navigate } from 'react-router-dom'
import { useAuth } from "@/hooks/useAuth"

export default function AuthLayout() {
  const { isAuthenticated } = useAuth()

  // If already authenticated, redirect to dashboard
  if (isAuthenticated) {
    return <Navigate to="/dashboard" replace />
  }

  // The new Login component handles its own layout
  return <Outlet />
}