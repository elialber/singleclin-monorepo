import { createContext } from 'react'
import { AlertColor } from '@mui/material'

interface NotificationContextData {
  showNotification: (message: string, severity?: AlertColor) => void
  showSuccess: (message: string) => void
  showError: (message: string) => void
  showWarning: (message: string) => void
  showInfo: (message: string) => void
}

export const NotificationContext = createContext<NotificationContextData>(
  {} as NotificationContextData,
)