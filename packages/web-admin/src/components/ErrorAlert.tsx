import { useState } from 'react'
import {
  Alert,
  AlertTitle,
  Box,
  Button,
  Collapse,
  IconButton,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Stack,
  Typography,
} from '@mui/material'
import {
  Close as CloseIcon,
  ExpandMore as ExpandMoreIcon,
  ExpandLess as ExpandLessIcon,
  Lightbulb as LightbulbIcon,
  Refresh as RefreshIcon,
  Info as InfoIcon,
  Error as ErrorIcon,
  Warning as WarningIcon,
  CheckCircle as CheckCircleIcon,
} from '@mui/icons-material'
import { TransactionError } from '@/utils/transactionErrorHandler'

interface ErrorAlertProps {
  error: TransactionError
  onClose?: () => void
  onRetry?: () => void
  showDetails?: boolean
  showSuggestions?: boolean
}

export default function ErrorAlert({
  error,
  onClose,
  onRetry,
  showDetails = true,
  showSuggestions = true,
}: ErrorAlertProps) {
  const [expanded, setExpanded] = useState(false)

  const getSeverity = (): 'error' | 'warning' | 'info' => {
    switch (error.type) {
      case 'network':
      case 'server':
        return 'error'
      case 'business':
      case 'validation':
        return 'warning'
      default:
        return 'error'
    }
  }

  const getIcon = () => {
    switch (error.type) {
      case 'network':
      case 'server':
        return <ErrorIcon />
      case 'business':
      case 'validation':
        return <WarningIcon />
      default:
        return <InfoIcon />
    }
  }

  const getTypeLabel = () => {
    switch (error.type) {
      case 'network':
        return 'Erro de Rede'
      case 'business':
        return 'Regra de Negócio'
      case 'validation':
        return 'Validação'
      case 'server':
        return 'Erro do Servidor'
      default:
        return 'Erro'
    }
  }

  return (
    <Alert
      severity={getSeverity()}
      icon={getIcon()}
      action={
        <Stack direction="row" spacing={1}>
          {error.isRetryable && onRetry && (
            <Button
              color="inherit"
              size="small"
              startIcon={<RefreshIcon />}
              onClick={onRetry}
            >
              Tentar Novamente
            </Button>
          )}
          {(showDetails || showSuggestions) && error.suggestions && (
            <IconButton
              size="small"
              color="inherit"
              onClick={() => setExpanded(!expanded)}
            >
              {expanded ? <ExpandLessIcon /> : <ExpandMoreIcon />}
            </IconButton>
          )}
          {onClose && (
            <IconButton
              size="small"
              color="inherit"
              onClick={onClose}
            >
              <CloseIcon />
            </IconButton>
          )}
        </Stack>
      }
    >
      <AlertTitle>
        <Stack direction="row" alignItems="center" spacing={1}>
          <Typography variant="subtitle1" fontWeight={600}>
            {error.title}
          </Typography>
          <Typography variant="caption" color="text.secondary">
            ({getTypeLabel()})
          </Typography>
        </Stack>
      </AlertTitle>

      <Typography variant="body2" mb={1}>
        {error.message}
      </Typography>

      {error.details && showDetails && (
        <Box sx={{ mb: 1 }}>
          <Typography variant="caption" color="text.secondary">
            Detalhes: {error.details}
          </Typography>
        </Box>
      )}

      {error.code && showDetails && (
        <Box sx={{ mb: 1 }}>
          <Typography variant="caption" color="text.secondary">
            Código: {error.code}
          </Typography>
        </Box>
      )}

      <Collapse in={expanded}>
        {error.suggestions && showSuggestions && (
          <Box sx={{ mt: 2 }}>
            <Stack direction="row" alignItems="center" spacing={1} mb={1}>
              <LightbulbIcon fontSize="small" color="action" />
              <Typography variant="subtitle2" color="text.secondary">
                Sugestões para resolução:
              </Typography>
            </Stack>
            
            <List dense sx={{ py: 0 }}>
              {error.suggestions.map((suggestion, index) => (
                <ListItem key={index} sx={{ py: 0, pl: 2 }}>
                  <ListItemIcon sx={{ minWidth: 28 }}>
                    <CheckCircleIcon fontSize="small" color="action" />
                  </ListItemIcon>
                  <ListItemText>
                    <Typography variant="body2" color="text.secondary">
                      {suggestion}
                    </Typography>
                  </ListItemText>
                </ListItem>
              ))}
            </List>
          </Box>
        )}
      </Collapse>
    </Alert>
  )
}

// Simplified version for inline use
export function SimpleErrorAlert({ 
  error, 
  onRetry 
}: { 
  error: TransactionError
  onRetry?: () => void 
}) {
  return (
    <Alert
      severity={error.type === 'validation' ? 'warning' : 'error'}
      action={
        error.isRetryable && onRetry && (
          <Button
            color="inherit"
            size="small"
            startIcon={<RefreshIcon />}
            onClick={onRetry}
          >
            Tentar Novamente
          </Button>
        )
      }
    >
      <AlertTitle>{error.title}</AlertTitle>
      {error.message}
    </Alert>
  )
}