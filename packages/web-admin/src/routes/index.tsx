import { Routes, Route, Navigate } from 'react-router-dom'

// Components
import ProtectedRoute from '@/components/ProtectedRoute'

// Layouts
import DashboardLayout from '@/layouts/DashboardLayout'
import AuthLayout from '@/layouts/AuthLayout'

// Pages
import Login from '@/pages/auth/Login'
import Register from '@/pages/auth/Register'
import Dashboard from '@/pages/Dashboard'
import Plans from '@/pages/plans/Plans'
import Clinics from '@/pages/clinics/Clinics'
import Patients from '@/pages/patients/Patients'
import PatientDetails from '@/pages/patients/PatientDetails'
import Users from '@/pages/users/Users'
import Transactions from '@/pages/transactions/Transactions'
import Reports from '@/pages/reports/Reports'
import Settings from '@/pages/settings/Settings'

export default function Router() {
  return (
    <Routes>
      {/* Public routes */}
      <Route element={<AuthLayout />}>
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
      </Route>

      {/* Private routes */}
      <Route
        element={
          <ProtectedRoute>
            <DashboardLayout />
          </ProtectedRoute>
        }
      >
        <Route path="/" element={<Navigate to="/dashboard" />} />
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/plans" element={<Plans />} />
        <Route path="/clinics" element={<Clinics />} />
        <Route path="/patients" element={<Patients />} />
        <Route path="/patients/:id" element={<PatientDetails />} />
        <Route path="/users" element={<Users />} />
        <Route path="/transactions" element={<Transactions />} />
        <Route path="/reports" element={<Reports />} />
        <Route path="/settings" element={<Settings />} />
      </Route>

      {/* 404 */}
      <Route path="*" element={<Navigate to="/dashboard" />} />
    </Routes>
  )
}