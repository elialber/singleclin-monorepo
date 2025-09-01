import React, { Component, ReactNode } from 'react'
import {
  Box,
  Button,
  Card,
  CardContent,
  Container,
  Stack,
  Typography,
  Alert,
  AlertTitle,
  Collapse,
  IconButton,
} from '@mui/material'
import {
  Error as ErrorIcon,
  Refresh as RefreshIcon,
  BugReport as BugReportIcon,
  ExpandMore as ExpandMoreIcon,
  ExpandLess as ExpandLessIcon,
  Home as HomeIcon,
} from '@mui/icons-material'
import { TransactionErrorHandler } from '@/utils/transactionErrorHandler'

interface Props {
  children: ReactNode
  fallback?: ReactNode
  onError?: (error: Error, errorInfo: React.ErrorInfo) => void
}

interface State {
  hasError: boolean
  error: Error | null
  errorInfo: React.ErrorInfo | null
  expanded: boolean
}

export default class TransactionErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = {
      hasError: false,
      error: null,
      errorInfo: null,
      expanded: false
    }
  }

  static getDerivedStateFromError(error: Error): Partial<State> {
    return {
      hasError: true,
      error
    }
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    this.setState({
      error,
      errorInfo
    })

    // Log error for monitoring
    console.error('TransactionErrorBoundary caught an error:', error, errorInfo)
    
    // Call optional error callback
    this.props.onError?.(error, errorInfo)

    // Log to external service if available
    this.logErrorToService(error, errorInfo)
  }

  private logErrorToService = (error: Error, errorInfo: React.ErrorInfo) => {
    try {
      // Here you would integrate with your error monitoring service
      // Example: Sentry, LogRocket, Bugsnag, etc.
      const errorData = {
        message: error.message,
        stack: error.stack,
        componentStack: errorInfo.componentStack,
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent,
        url: window.location.href,
        context: 'TransactionSystem'
      }
      
      // For now, just log to console
      console.error('Error logged:', errorData)
    } catch (loggingError) {
      console.error('Failed to log error:', loggingError)
    }
  }

  private handleRetry = () => {
    this.setState({
      hasError: false,
      error: null,
      errorInfo: null,
      expanded: false
    })
  }

  private handleGoHome = () => {
    window.location.href = '/dashboard'
  }

  private toggleExpanded = () => {
    this.setState(prev => ({ expanded: !prev.expanded }))
  }

  render() {
    if (this.state.hasError) {
      // If a custom fallback is provided, use it
      if (this.props.fallback) {
        return this.props.fallback
      }

      // Default error UI
      return (
        <Container maxWidth="md" sx={{ py: 8 }}>
          <Card elevation={3}>
            <CardContent sx={{ p: 4 }}>
              <Stack spacing={3} alignItems="center" textAlign="center">
                <ErrorIcon color="error" sx={{ fontSize: 64 }} />
                
                <Box>
                  <Typography variant="h4" color="error" fontWeight={600} gutterBottom>
                    Oops! Algo deu errado
                  </Typography>
                  <Typography variant="h6" color="text.secondary" gutterBottom>
                    Ocorreu um erro inesperado no sistema de transações
                  </Typography>
                  <Typography variant="body1" color="text.secondary">
                    Nossa equipe foi notificada automaticamente. Você pode tentar atualizar a página ou voltar ao início.
                  </Typography>
                </Box>

                <Stack direction="row" spacing={2}>
                  <Button
                    variant="contained"
                    startIcon={<RefreshIcon />}
                    onClick={this.handleRetry}
                    color="primary"
                  >
                    Tentar Novamente
                  </Button>
                  <Button
                    variant="outlined"
                    startIcon={<HomeIcon />}
                    onClick={this.handleGoHome}
                  >
                    Voltar ao Início
                  </Button>
                </Stack>

                {/* Error Details (Expandable) */}
                <Box sx={{ width: '100%', mt: 4 }}>
                  <Alert severity="error">
                    <Stack direction="row" justifyContent="space-between" alignItems="center">
                      <AlertTitle>
                        <Stack direction="row" alignItems="center" spacing={1}>
                          <BugReportIcon />
                          <Typography variant="subtitle1">
                            Detalhes Técnicos
                          </Typography>
                        </Stack>
                      </AlertTitle>
                      <IconButton
                        size="small"
                        onClick={this.toggleExpanded}
                        color="inherit"
                      >
                        {this.state.expanded ? <ExpandLessIcon /> : <ExpandMoreIcon />}
                      </IconButton>
                    </Stack>
                    
                    <Collapse in={this.state.expanded}>
                      <Box sx={{ mt: 2 }}>
                        {this.state.error && (
                          <Box sx={{ mb: 2 }}>
                            <Typography variant="subtitle2" color="error" gutterBottom>
                              Erro:
                            </Typography>
                            <Typography 
                              variant="body2" 
                              fontFamily="monospace" 
                              sx={{ 
                                bgcolor: 'error.light', 
                                color: 'error.contrastText',
                                p: 1, 
                                borderRadius: 1,
                                fontSize: '0.75rem',
                                wordBreak: 'break-word'
                              }}
                            >
                              {this.state.error.message}
                            </Typography>
                          </Box>
                        )}
                        
                        {this.state.error?.stack && (
                          <Box sx={{ mb: 2 }}>
                            <Typography variant="subtitle2" color="error" gutterBottom>
                              Stack Trace:
                            </Typography>
                            <Typography 
                              variant="body2" 
                              fontFamily="monospace" 
                              sx={{ 
                                bgcolor: 'grey.100', 
                                p: 1, 
                                borderRadius: 1,
                                fontSize: '0.7rem',
                                maxHeight: 200,
                                overflow: 'auto',
                                wordBreak: 'break-word',
                                whiteSpace: 'pre-wrap'
                              }}
                            >
                              {this.state.error.stack}
                            </Typography>
                          </Box>
                        )}
                        
                        <Box>
                          <Typography variant="caption" color="text.secondary">
                            Timestamp: {new Date().toLocaleString('pt-BR')}
                          </Typography>
                        </Box>
                      </Box>
                    </Collapse>
                  </Alert>
                </Box>

                <Box sx={{ textAlign: 'center', mt: 2 }}>
                  <Typography variant="caption" color="text.secondary">
                    Se este erro persistir, entre em contato com o suporte técnico informando
                    os detalhes acima e as ações que levaram a este problema.
                  </Typography>
                </Box>
              </Stack>
            </CardContent>
          </Card>
        </Container>
      )
    }

    return this.props.children
  }
}

// Higher-order component for easy wrapping
export function withTransactionErrorBoundary<P extends object>(
  Component: React.ComponentType<P>,
  errorFallback?: ReactNode
) {
  return function WrappedComponent(props: P) {
    return (
      <TransactionErrorBoundary fallback={errorFallback}>
        <Component {...props} />
      </TransactionErrorBoundary>
    )
  }
}