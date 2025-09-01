import { ReactNode, useState, useCallback } from 'react'
import { 
  Snackbar, 
  Alert, 
  AlertColor, 
  AlertTitle,
  Button,
  Box,
  Stack,
  Portal,
  Slide,
  SlideProps,
  IconButton
} from '@mui/material'
import {
  CheckCircle as CheckCircleIcon,
  Error as ErrorIcon,
  Warning as WarningIcon,
  Info as InfoIcon,
  Close as CloseIcon
} from '@mui/icons-material'
import { 
  NotificationContext, 
  NotificationData, 
  NotificationOptions 
} from './NotificationContextDefinition'

function SlideTransition(props: SlideProps) {
  return <Slide {...props} direction="left" />
}

interface NotificationItemProps {
  notification: NotificationData
  onClose: () => void
}

function NotificationItem({ notification, onClose }: NotificationItemProps) {
  const { message, severity, options } = notification

  const getIcon = () => {
    switch (severity) {
      case 'success':
        return <CheckCircleIcon />
      case 'error':
        return <ErrorIcon />
      case 'warning':
        return <WarningIcon />
      case 'info':
        return <InfoIcon />
      default:
        return <InfoIcon />
    }
  }

  return (
    <Alert
      icon={getIcon()}
      severity={severity}
      variant="filled"
      onClose={options?.persist ? undefined : onClose}
      sx={{
        minWidth: 300,
        maxWidth: 500,
        mb: 1,
        '& .MuiAlert-message': {
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          gap: 0.5
        }
      }}
      action={
        <Stack direction="row" spacing={1} alignItems="center">
          {options?.action && (
            <Button 
              color="inherit" 
              size="small"
              onClick={() => {
                options.action?.onClick()
                onClose()
              }}
              sx={{ 
                color: 'inherit', 
                fontWeight: 600,
                fontSize: '0.75rem'
              }}
            >
              {options.action.label}
            </Button>
          )}
          {!options?.persist && (
            <IconButton 
              color="inherit" 
              size="small"
              onClick={onClose}
              sx={{ color: 'inherit' }}
            >
              <CloseIcon fontSize="small" />
            </IconButton>
          )}
        </Stack>
      }
    >
      {options?.title && (
        <AlertTitle sx={{ fontWeight: 600, mb: 0.5 }}>
          {options.title}
        </AlertTitle>
      )}
      <Box sx={{ fontSize: '0.875rem' }}>
        {message}
      </Box>
    </Alert>
  )
}

export function NotificationProvider({ children }: { children: ReactNode }) {
  const [notifications, setNotifications] = useState<NotificationData[]>([])

  const showNotification = useCallback((
    message: string,
    severity: AlertColor = 'info',
    options?: NotificationOptions
  ): string => {
    const id = `notification-${Date.now()}-${Math.random().toString(36).substring(7)}`
    const notification: NotificationData = {
      id,
      message,
      severity,
      options,
      timestamp: Date.now()
    }

    setNotifications(prev => [...prev, notification])

    // Auto-dismiss after duration (unless persist is true)
    if (!options?.persist) {
      const duration = options?.duration ?? (severity === 'error' ? 8000 : 6000)
      setTimeout(() => {
        hideNotification(id)
      }, duration)
    }

    return id
  }, [])

  const hideNotification = useCallback((id: string) => {
    setNotifications(prev => prev.filter(notification => notification.id !== id))
  }, [])

  const clearAllNotifications = useCallback(() => {
    setNotifications([])
  }, [])

  const showSuccess = useCallback((message: string, options?: NotificationOptions) => {
    return showNotification(message, 'success', options)
  }, [showNotification])

  const showError = useCallback((message: string, options?: NotificationOptions) => {
    return showNotification(message, 'error', options)
  }, [showNotification])

  const showWarning = useCallback((message: string, options?: NotificationOptions) => {
    return showNotification(message, 'warning', options)
  }, [showNotification])

  const showInfo = useCallback((message: string, options?: NotificationOptions) => {
    return showNotification(message, 'info', options)
  }, [showNotification])

  // Keep only the latest 5 notifications visible
  const visibleNotifications = notifications.slice(-5)

  return (
    <NotificationContext.Provider
      value={{
        showNotification,
        showSuccess,
        showError,
        showWarning,
        showInfo,
        hideNotification,
        clearAllNotifications,
        notifications
      }}
    >
      {children}
      
      {/* Enhanced notification container */}
      {visibleNotifications.length > 0 && (
        <Portal>
          <Box
            sx={{
              position: 'fixed',
              top: 24,
              right: 24,
              zIndex: theme => theme.zIndex.snackbar + 1,
              display: 'flex',
              flexDirection: 'column',
              gap: 0,
              maxHeight: 'calc(100vh - 48px)',
              overflow: 'hidden',
            }}
          >
            {visibleNotifications.map((notification) => (
              <NotificationItem
                key={notification.id}
                notification={notification}
                onClose={() => hideNotification(notification.id)}
              />
            ))}
            
            {notifications.length > 5 && (
              <Alert 
                severity="info" 
                sx={{ 
                  minWidth: 300,
                  mb: 1,
                  '& .MuiAlert-message': {
                    textAlign: 'center',
                    width: '100%'
                  }
                }}
                action={
                  <Button 
                    color="inherit" 
                    size="small"
                    onClick={clearAllNotifications}
                    sx={{ color: 'inherit', fontSize: '0.75rem' }}
                  >
                    Limpar Todas
                  </Button>
                }
              >
                +{notifications.length - 5} mais notificações
              </Alert>
            )}
          </Box>
        </Portal>
      )}
    </NotificationContext.Provider>
  )
}


