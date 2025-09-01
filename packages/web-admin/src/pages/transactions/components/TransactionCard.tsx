import { useState } from 'react'
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

export default function TransactionCard({
  transaction,
  onView,
  onEdit,
  onCancel,
}: TransactionCardProps) {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null)
  const open = Boolean(anchorEl)

  const handleMenuClick = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget)
  }

  const handleMenuClose = () => {
    setAnchorEl(null)
  }

  const handleAction = (action: () => void) => {
    action()
    handleMenuClose()
  }

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

  const formatDate = (dateString: string) => {
    try {
      return format(parseISO(dateString), 'dd/MM/yyyy HH:mm', { locale: ptBR })
    } catch {
      return dateString
    }
  }

  const canEdit = transaction.status === 'Pending' || transaction.status === 'Validated'
  const canCancel = transaction.status === 'Pending' || transaction.status === 'Validated'

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
              label={getStatusLabel(transaction.status)}
              color={getStatusColor(transaction.status)}
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
              {transaction.patientName.charAt(0).toUpperCase()}
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
                {transaction.creditsUsed} crédito{transaction.creditsUsed !== 1 ? 's' : ''}
              </Typography>
            </Stack>
          </Box>
        </Stack>

        {/* Dates */}
        <Box>
          <Stack direction="row" alignItems="center" spacing={0.5} mb={0.5}>
            <ScheduleIcon fontSize="small" color="action" />
            <Typography variant="caption" color="text.secondary">
              Criada: {formatDate(transaction.createdAt)}
            </Typography>
          </Stack>
          
          {transaction.validationDate && (
            <Typography variant="caption" color="text.secondary" display="block">
              Validada: {formatDate(transaction.validationDate)}
            </Typography>
          )}
          
          {transaction.cancellationDate && (
            <Typography variant="caption" color="error.main" display="block">
              Cancelada: {formatDate(transaction.cancellationDate)}
            </Typography>
          )}
        </Box>

        {/* Location (if available) */}
        {transaction.latitude && transaction.longitude && (
          <Stack direction="row" alignItems="center" spacing={0.5} mt={1}>
            <LocationIcon fontSize="small" color="action" />
            <Typography variant="caption" color="text.secondary">
              {transaction.latitude.toFixed(6)}, {transaction.longitude.toFixed(6)}
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
        
        {onEdit && canEdit && (
          <MenuItem onClick={() => handleAction(() => onEdit(transaction))}>
            <EditIcon fontSize="small" sx={{ mr: 1 }} />
            Editar
          </MenuItem>
        )}
        
        {onCancel && canCancel && (
          <MenuItem onClick={() => handleAction(() => onCancel(transaction))}>
            <CancelIcon fontSize="small" sx={{ mr: 1, color: 'error.main' }} />
            <Typography color="error.main">Cancelar</Typography>
          </MenuItem>
        )}
      </Menu>
    </Card>
  )
}