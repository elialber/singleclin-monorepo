import { useState, memo, useMemo, useCallback } from 'react'
import {
  Card,
  CardContent,
  CardActions,
  Typography,
  Chip,
  Box,
  Stack,
  IconButton,
  Tooltip,
  Menu,
  MenuItem,
  Divider,
  Avatar,
} from '@mui/material'
import {
  MoreVert as MoreVertIcon,
  Edit as EditIcon,
  Cancel as CancelIcon,
  Visibility as VisibilityIcon,
  LocationOn as LocationIcon,
  Schedule as ScheduleIcon,
  CreditCard as CreditCardIcon,
  AttachMoney as AttachMoneyIcon,
} from '@mui/icons-material'
import { Transaction } from '@/types/transaction'
import { format, parseISO } from 'date-fns'
import { ptBR } from 'date-fns/locale'

interface TransactionCardProps {
  transaction: Transaction
  onView?: (transaction: Transaction) => void
  onEdit?: (transaction: Transaction) => void
  onCancel?: (transaction: Transaction) => void
}

const TransactionCard = memo<TransactionCardProps>(({
  transaction,
  onView,
  onEdit,
  onCancel,
}) => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null)
  const open = Boolean(anchorEl)

  const handleMenuClick = useCallback((event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget)
  }, [])

  const handleMenuClose = useCallback(() => {
    setAnchorEl(null)
  }, [])

  const handleAction = useCallback((action: () => void) => {
    action()
    handleMenuClose()
  }, [handleMenuClose])

  // Memoize expensive computations
  const statusInfo = useMemo(() => {
    const getStatusColor = (status: Transaction['status']) => {
      switch (status) {
        case 'Validated':
          return 'success'
        case 'Pending':
          return 'warning'
        case 'Cancelled':
          return 'error'
        case 'Expired':
          return 'default'
        default:
          return 'default'
      }
    }

    const getStatusLabel = (status: Transaction['status']) => {
      const labels = {
        Validated: 'Validada',
        Pending: 'Pendente',
        Cancelled: 'Cancelada',
        Expired: 'Expirada',
      }
      return labels[status] || status
    }

    return {
      color: getStatusColor(transaction.status),
      label: getStatusLabel(transaction.status)
    }
  }, [transaction.status])

  // Memoize date formatting
  const formattedDates = useMemo(() => {
    const formatDate = (dateString: string) => {
      try {
        return format(parseISO(dateString), 'dd/MM/yyyy HH:mm', { locale: ptBR })
      } catch {
        return dateString
      }
    }

    return {
      createdAt: formatDate(transaction.createdAt),
      validationDate: transaction.validationDate ? formatDate(transaction.validationDate) : null,
      cancellationDate: transaction.cancellationDate ? formatDate(transaction.cancellationDate) : null,
    }
  }, [transaction.createdAt, transaction.validationDate, transaction.cancellationDate])

  // Memoize permissions
  const permissions = useMemo(() => ({
    canEdit: transaction.status === 'Pending' || transaction.status === 'Validated',
    canCancel: transaction.status === 'Pending' || transaction.status === 'Validated'
  }), [transaction.status])

  // Memoize patient initial
  const patientInitial = useMemo(() => 
    transaction.patientName.charAt(0).toUpperCase(), 
    [transaction.patientName]
  )

  // Memoize location coordinates display
  const locationDisplay = useMemo(() => 
    transaction.latitude && transaction.longitude 
      ? `${transaction.latitude.toFixed(6)}, ${transaction.longitude.toFixed(6)}`
      : null,
    [transaction.latitude, transaction.longitude]
  )

  // Memoize credits display text
  const creditsDisplay = useMemo(() => 
    `${transaction.creditsUsed} crédito${transaction.creditsUsed !== 1 ? 's' : ''}`,
    [transaction.creditsUsed]
  )

  return (
    <Card 
      elevation={2}
      sx={{ 
        height: '100%', 
        display: 'flex', 
        flexDirection: 'column',
        transition: 'all 0.2s ease-in-out',
        '&:hover': {
          elevation: 4,
          transform: 'translateY(-2px)',
        }
      }}
    >
      <CardContent sx={{ flexGrow: 1, pb: 1 }}>
        {/* Header with status and menu */}
        <Stack direction="row" justifyContent="space-between" alignItems="flex-start" mb={2}>
          <Box>
            <Typography variant="subtitle1" fontWeight={600} gutterBottom>
              {transaction.code}
            </Typography>
            <Chip
              label={statusInfo.label}
              color={statusInfo.color}
              size="small"
              sx={{ fontWeight: 500 }}
            />
          </Box>
          
          <IconButton
            size="small"
            onClick={handleMenuClick}
            sx={{ color: 'text.secondary' }}
          >
            <MoreVertIcon fontSize="small" />
          </IconButton>
        </Stack>

        {/* Patient and Clinic Info */}
        <Box mb={2}>
          <Stack direction="row" alignItems="center" spacing={1} mb={1}>
            <Avatar sx={{ width: 24, height: 24, bgcolor: 'primary.main', fontSize: '0.75rem' }}>
              {patientInitial}
            </Avatar>
            <Typography variant="body2" fontWeight={500} color="text.primary">
              {transaction.patientName}
            </Typography>
          </Stack>
          
          <Typography variant="body2" color="text.secondary" gutterBottom>
            📍 {transaction.clinicName}
          </Typography>
          
          <Typography variant="body2" color="text.secondary">
            📋 {transaction.planName}
          </Typography>
        </Box>

        <Divider sx={{ my: 2 }} />

        {/* Service Info */}
        <Box mb={2}>
          <Typography variant="body2" color="text.primary" fontWeight={500} gutterBottom>
            {transaction.serviceDescription}
          </Typography>
          
          {transaction.serviceType && (
            <Typography variant="caption" color="text.secondary">
              Tipo: {transaction.serviceType}
            </Typography>
          )}
        </Box>

        {/* Financial Info */}
        <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
          <Box>
            <Stack direction="row" alignItems="center" spacing={0.5}>
              <AttachMoneyIcon fontSize="small" color="primary" />
              <Typography variant="h6" color="primary.main" fontWeight={600}>
                R$ {transaction.amount.toFixed(2)}
              </Typography>
            </Stack>
          </Box>
          
          <Box textAlign="right">
            <Stack direction="row" alignItems="center" spacing={0.5} justifyContent="flex-end">
              <CreditCardIcon fontSize="small" color="secondary" />
              <Typography variant="body2" color="secondary.main" fontWeight={500}>
                {creditsDisplay}
              </Typography>
            </Stack>
          </Box>
        </Stack>

        {/* Dates */}
        <Box>
          <Stack direction="row" alignItems="center" spacing={0.5} mb={0.5}>
            <ScheduleIcon fontSize="small" color="action" />
            <Typography variant="caption" color="text.secondary">
              Criada: {formattedDates.createdAt}
            </Typography>
          </Stack>
          
          {formattedDates.validationDate && (
            <Typography variant="caption" color="text.secondary" display="block">
              Validada: {formattedDates.validationDate}
            </Typography>
          )}
          
          {formattedDates.cancellationDate && (
            <Typography variant="caption" color="error.main" display="block">
              Cancelada: {formattedDates.cancellationDate}
            </Typography>
          )}
        </Box>

        {/* Location (if available) */}
        {locationDisplay && (
          <Stack direction="row" alignItems="center" spacing={0.5} mt={1}>
            <LocationIcon fontSize="small" color="action" />
            <Typography variant="caption" color="text.secondary">
              {locationDisplay}
            </Typography>
          </Stack>
        )}

        {/* Validation Notes */}
        {transaction.validationNotes && (
          <Box mt={1}>
            <Typography variant="caption" color="text.secondary" display="block">
              Observações: {transaction.validationNotes}
            </Typography>
          </Box>
        )}

        {/* Cancellation Reason */}
        {transaction.cancellationReason && (
          <Box mt={1}>
            <Typography variant="caption" color="error.main" display="block">
              Motivo do cancelamento: {transaction.cancellationReason}
            </Typography>
          </Box>
        )}
      </CardContent>

      {/* Actions Menu */}
      <Menu
        anchorEl={anchorEl}
        open={open}
        onClose={handleMenuClose}
        transformOrigin={{ horizontal: 'right', vertical: 'top' }}
        anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
      >
        {onView && (
          <MenuItem onClick={() => handleAction(() => onView(transaction))}>
            <VisibilityIcon fontSize="small" sx={{ mr: 1 }} />
            Ver Detalhes
          </MenuItem>
        )}
        
        {onEdit && permissions.canEdit && (
          <MenuItem onClick={() => handleAction(() => onEdit(transaction))}>
            <EditIcon fontSize="small" sx={{ mr: 1 }} />
            Editar
          </MenuItem>
        )}
        
        {onCancel && permissions.canCancel && (
          <MenuItem onClick={() => handleAction(() => onCancel(transaction))}>
            <CancelIcon fontSize="small" sx={{ mr: 1, color: 'error.main' }} />
            <Typography color="error.main">Cancelar</Typography>
          </MenuItem>
        )}
      </Menu>
    </Card>
  )
})

TransactionCard.displayName = 'TransactionCard'

export default TransactionCard