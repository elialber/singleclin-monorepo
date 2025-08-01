import { ReactNode } from 'react'
import { Snackbar, Alert, AlertColor } from '@mui/material'
import { useState } from 'react'
import { NotificationContext } from './NotificationContextDefinition'

interface NotificationData {
  message: string
  severity: AlertColor
}

export function NotificationProvider({ children }: { children: ReactNode }) {
  const [notification, setNotification] = useState<NotificationData | null>(
    null,
  )
  const [open, setOpen] = useState(false)

  const showNotification = (
    message: string,
    severity: AlertColor = 'info',
  ) => {
    setNotification({ message, severity })
    setOpen(true)
  }

  const showSuccess = (message: string) => {
    showNotification(message, 'success')
  }

  const showError = (message: string) => {
    showNotification(message, 'error')
  }

  const showWarning = (message: string) => {
    showNotification(message, 'warning')
  }

  const showInfo = (message: string) => {
    showNotification(message, 'info')
  }

  const handleClose = () => {
    setOpen(false)
  }

  return (
    <NotificationContext.Provider
      value={{
        showNotification,
        showSuccess,
        showError,
        showWarning,
        showInfo,
      }}
    >
      {children}
      <Snackbar
        open={open}
        autoHideDuration={6000}
        onClose={handleClose}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert
          onClose={handleClose}
          severity={notification?.severity}
          sx={{ width: '100%' }}
          variant="filled"
        >
          {notification?.message}
        </Alert>
      </Snackbar>
    </NotificationContext.Provider>
  )
}


