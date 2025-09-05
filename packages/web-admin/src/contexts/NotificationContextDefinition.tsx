import { createContext, useContext } from 'react'
import { AlertColor } from '@mui/material'

export interface NotificationOptions {
  duration?: number
  action?: {
    label: string
    onClick: () => void
  }
  title?: string
  persist?: boolean
}

export interface NotificationData {
  id: string
  message: string
  severity: AlertColor
  options?: NotificationOptions
  timestamp: number
}

interface NotificationContextData {
  showNotification: (message: string, severity?: AlertColor, options?: NotificationOptions) => string
  showSuccess: (message: string, options?: NotificationOptions) => string
  showError: (message: string, options?: NotificationOptions) => string
  showWarning: (message: string, options?: NotificationOptions) => string
  showInfo: (message: string, options?: NotificationOptions) => string
  hideNotification: (id: string) => void
  clearAllNotifications: () => void
  notifications: NotificationData[]
}

export const NotificationContext = createContext<NotificationContextData>(
  {} as NotificationContextData,
)

export const useNotification = () => {
  const context = useContext(NotificationContext)
  if (!context) {
    throw new Error('useNotification must be used within a NotificationProvider')
  }
  return context
}