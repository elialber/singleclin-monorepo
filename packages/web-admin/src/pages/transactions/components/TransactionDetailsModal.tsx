import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Box,
  Stack,
  Chip,
  Divider,
  Card,
  CardContent,
  Grid,
  IconButton,
  Tooltip,
} from '@mui/material'
import {
  Timeline,
  TimelineItem,
  TimelineContent,
  TimelineDot,
  TimelineSeparator,
  TimelineConnector,
  TimelineOppositeContent,
} from '@mui/lab'
import {
  Visibility as VisibilityIcon,
  Person as PersonIcon,
  Business as BusinessIcon,
  CreditCard as CreditCardIcon,
  AttachMoney as AttachMoneyIcon,
  Schedule as ScheduleIcon,
  LocationOn as LocationIcon,
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
  Pending as PendingIcon,
  AccessTime as AccessTimeIcon,
  Close as CloseIcon,
  ContentCopy as ContentCopyIcon,
} from '@mui/icons-material'
import { Transaction } from '@/types/transaction'
import { format, parseISO } from 'date-fns'
import { ptBR } from 'date-fns/locale'
import { useNotification } from '@/hooks/useNotification'

interface TransactionDetailsModalProps {
  open: boolean
  transaction: Transaction | null
  onClose: () => void
  onEdit?: (transaction: Transaction) => void
  onCancel?: (transaction: Transaction) => void
}

export default function TransactionDetailsModal({
  open,
  transaction,
  onClose,
  onEdit,
  onCancel,
}: TransactionDetailsModalProps) {
  const { showSuccess } = useNotification()

  const copyToClipboard = (text: string, label: string) => {
    navigator.clipboard.writeText(text)
    showSuccess(`${label} copiado para a área de transferência`)
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

  const getStatusIcon = (status: Transaction['status']) => {
    switch (status) {
      case 'Validated':
        return <CheckCircleIcon />
      case 'Pending':
        return <PendingIcon />
      case 'Cancelled':
        return <CancelIcon />
      case 'Expired':
        return <AccessTimeIcon />
      default:
        return <PendingIcon />
    }
  }

  const formatDate = (dateString: string) => {
    try {
      return format(parseISO(dateString), 'dd/MM/yyyy HH:mm', { locale: ptBR })
    } catch {
      return dateString
    }
  }

  const formatDateLong = (dateString: string) => {
    try {
      return format(parseISO(dateString), "dd 'de' MMMM 'de' yyyy 'às' HH:mm", { locale: ptBR })
    } catch {
      return dateString
    }
  }

  if (!transaction) return null

  const canEdit = transaction.status === 'Pending' || transaction.status === 'Validated'
  const canCancel = transaction.status === 'Pending' || transaction.status === 'Validated'

  const timelineEvents = [
    {
      date: transaction.createdAt,
      title: 'Transação Criada',
      description: 'Transação iniciada pelo paciente',
      icon: <ScheduleIcon />,
      color: 'primary',
    },
    ...(transaction.validationDate ? [{
      date: transaction.validationDate,
      title: 'Transação Validada',
      description: `Validada por ${transaction.validatedBy || 'Sistema'}`,
      icon: <CheckCircleIcon />,
      color: 'success',
    }] : []),
    ...(transaction.cancellationDate ? [{
      date: transaction.cancellationDate,
      title: 'Transação Cancelada',
      description: transaction.cancellationReason || 'Motivo não informado',
      icon: <CancelIcon />,
      color: 'error',
    }] : []),
  ]

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="lg"
      fullWidth
      PaperProps={{
        sx: { borderRadius: 2, maxHeight: '90vh' }
      }}
    >
      <DialogTitle>
        <Stack direction="row" alignItems="center" justifyContent="space-between">
          <Stack direction="row" alignItems="center" spacing={2}>
            <VisibilityIcon color="primary" />
            <Box>
              <Typography variant="h6" fontWeight={600}>
                Detalhes da Transação
              </Typography>
              <Stack direction="row" alignItems="center" spacing={1}>
                <Typography variant="body2" color="text.secondary">
                  {transaction.code}
                </Typography>
                <Tooltip title="Copiar código">
                  <IconButton
                    size="small"
                    onClick={() => copyToClipboard(transaction.code, 'Código')}
                  >
                    <ContentCopyIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              </Stack>
            </Box>
          </Stack>
          
          <IconButton onClick={onClose}>
            <CloseIcon />
          </IconButton>
        </Stack>
      </DialogTitle>

      <DialogContent dividers sx={{ p: 0 }}>
        <Box sx={{ p: 3 }}>
          {/* Status and Quick Info */}
          <Card variant="outlined" sx={{ mb: 3, bgcolor: 'primary.light', color: 'primary.contrastText' }}>
            <CardContent>
              <Stack direction="row" justifyContent="space-between" alignItems="center">
                <Stack direction="row" alignItems="center" spacing={2}>
                  <Chip
                    label={getStatusLabel(transaction.status)}
                    color={getStatusColor(transaction.status)}
                    icon={getStatusIcon(transaction.status)}
                    sx={{ bgcolor: 'white', color: 'text.primary' }}
                  />
                  <Typography variant="h6" fontWeight={600}>
                    R$ {transaction.amount.toFixed(2)}
                  </Typography>
                  <Typography variant="body1">
                    {transaction.creditsUsed} crédito{transaction.creditsUsed !== 1 ? 's' : ''}
                  </Typography>
                </Stack>
                
                <Typography variant="body2">
                  {formatDate(transaction.createdAt)}
                </Typography>
              </Stack>
            </CardContent>
          </Card>

          <Grid container spacing={3}>
            {/* Left Column - Main Details */}
            <Grid item xs={12} md={8}>
              {/* Participant Information */}
              <Card variant="outlined" sx={{ mb: 3 }}>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Informações dos Participantes
                  </Typography>
                  
                  <Grid container spacing={3}>
                    <Grid item xs={12} md={6}>
                      <Stack direction="row" alignItems="flex-start" spacing={2}>
                        <PersonIcon color="primary" sx={{ mt: 0.5 }} />
                        <Box>
                          <Typography variant="subtitle2" color="primary" gutterBottom>
                            Paciente
                          </Typography>
                          <Typography variant="body1" fontWeight={500}>
                            {transaction.patientName}
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            {transaction.patientEmail}
                          </Typography>
                          <Tooltip title="Copiar email">
                            <IconButton
                              size="small"
                              onClick={() => copyToClipboard(transaction.patientEmail, 'Email do paciente')}
                            >
                              <ContentCopyIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        </Box>
                      </Stack>
                    </Grid>

                    <Grid item xs={12} md={6}>
                      <Stack direction="row" alignItems="flex-start" spacing={2}>
                        <BusinessIcon color="secondary" sx={{ mt: 0.5 }} />
                        <Box>
                          <Typography variant="subtitle2" color="secondary" gutterBottom>
                            Clínica
                          </Typography>
                          <Typography variant="body1" fontWeight={500}>
                            {transaction.clinicName}
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            Plano: {transaction.planName}
                          </Typography>
                        </Box>
                      </Stack>
                    </Grid>
                  </Grid>
                </CardContent>
              </Card>

              {/* Service Details */}
              <Card variant="outlined" sx={{ mb: 3 }}>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Detalhes do Serviço
                  </Typography>
                  
                  <Stack spacing={2}>
                    <Box>
                      <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                        Descrição do Serviço
                      </Typography>
                      <Typography variant="body1">
                        {transaction.serviceDescription}
                      </Typography>
                    </Box>

                    {transaction.serviceType && (
                      <Box>
                        <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                          Tipo de Serviço
                        </Typography>
                        <Typography variant="body1">
                          {transaction.serviceType}
                        </Typography>
                      </Box>
                    )}

                    <Grid container spacing={2}>
                      <Grid item xs={6}>
                        <Stack direction="row" alignItems="center" spacing={1}>
                          <AttachMoneyIcon fontSize="small" color="success" />
                          <Box>
                            <Typography variant="subtitle2" color="text.secondary">
                              Valor Cobrado
                            </Typography>
                            <Typography variant="h6" color="success.main">
                              R$ {transaction.amount.toFixed(2)}
                            </Typography>
                          </Box>
                        </Stack>
                      </Grid>

                      <Grid item xs={6}>
                        <Stack direction="row" alignItems="center" spacing={1}>
                          <CreditCardIcon fontSize="small" color="primary" />
                          <Box>
                            <Typography variant="subtitle2" color="text.secondary">
                              Créditos Utilizados
                            </Typography>
                            <Typography variant="h6" color="primary.main">
                              {transaction.creditsUsed}
                            </Typography>
                          </Box>
                        </Stack>
                      </Grid>
                    </Grid>
                  </Stack>
                </CardContent>
              </Card>

              {/* Validation/Cancellation Details */}
              {(transaction.validationNotes || transaction.cancellationReason) && (
                <Card variant="outlined" sx={{ mb: 3 }}>
                  <CardContent>
                    <Typography variant="h6" gutterBottom>
                      Observações
                    </Typography>
                    
                    {transaction.validationNotes && (
                      <Box sx={{ mb: 2 }}>
                        <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                          Notas de Validação
                        </Typography>
                        <Typography variant="body1">
                          {transaction.validationNotes}
                        </Typography>
                      </Box>
                    )}

                    {transaction.cancellationReason && (
                      <Box>
                        <Typography variant="subtitle2" color="error.main" gutterBottom>
                          Motivo do Cancelamento
                        </Typography>
                        <Typography variant="body1" color="error.main">
                          {transaction.cancellationReason}
                        </Typography>
                      </Box>
                    )}
                  </CardContent>
                </Card>
              )}

              {/* Technical Details */}
              <Card variant="outlined">
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Informações Técnicas
                  </Typography>
                  
                  <Grid container spacing={2}>
                    {transaction.latitude && transaction.longitude && (
                      <Grid item xs={12}>
                        <Stack direction="row" alignItems="center" spacing={1}>
                          <LocationIcon fontSize="small" color="action" />
                          <Box>
                            <Typography variant="subtitle2" color="text.secondary">
                              Localização
                            </Typography>
                            <Typography variant="body2" fontFamily="monospace">
                              {transaction.latitude.toFixed(6)}, {transaction.longitude.toFixed(6)}
                            </Typography>
                          </Box>
                          <Tooltip title="Copiar coordenadas">
                            <IconButton
                              size="small"
                              onClick={() => copyToClipboard(
                                `${transaction.latitude},${transaction.longitude}`,
                                'Coordenadas'
                              )}
                            >
                              <ContentCopyIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        </Stack>
                      </Grid>
                    )}

                    {transaction.ipAddress && (
                      <Grid item xs={12} sm={6}>
                        <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                          Endereço IP
                        </Typography>
                        <Typography variant="body2" fontFamily="monospace">
                          {transaction.ipAddress}
                        </Typography>
                      </Grid>
                    )}

                    {transaction.qrToken && (
                      <Grid item xs={12} sm={6}>
                        <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                          Token QR
                        </Typography>
                        <Typography variant="body2" fontFamily="monospace">
                          {transaction.qrToken}
                        </Typography>
                      </Grid>
                    )}

                    {transaction.userAgent && (
                      <Grid item xs={12}>
                        <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                          User Agent
                        </Typography>
                        <Typography variant="body2" fontFamily="monospace" fontSize="0.75rem">
                          {transaction.userAgent}
                        </Typography>
                      </Grid>
                    )}
                  </Grid>
                </CardContent>
              </Card>
            </Grid>

            {/* Right Column - Timeline */}
            <Grid item xs={12} md={4}>
              <Card variant="outlined" sx={{ position: 'sticky', top: 20 }}>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Histórico da Transação
                  </Typography>

                  <Timeline position="right">
                    {timelineEvents.map((event, index) => (
                      <TimelineItem key={index}>
                        <TimelineOppositeContent color="text.secondary" variant="body2">
                          {formatDate(event.date)}
                        </TimelineOppositeContent>
                        
                        <TimelineSeparator>
                          <TimelineDot color={event.color as any}>
                            {event.icon}
                          </TimelineDot>
                          {index < timelineEvents.length - 1 && <TimelineConnector />}
                        </TimelineSeparator>
                        
                        <TimelineContent>
                          <Typography variant="subtitle2" fontWeight={600}>
                            {event.title}
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            {event.description}
                          </Typography>
                        </TimelineContent>
                      </TimelineItem>
                    ))}
                  </Timeline>

                  <Divider sx={{ my: 2 }} />
                  
                  <Box>
                    <Typography variant="body2" color="text.secondary" gutterBottom>
                      Última atualização
                    </Typography>
                    <Typography variant="body2">
                      {formatDateLong(transaction.updatedAt)}
                    </Typography>
                  </Box>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        </Box>
      </DialogContent>

      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={onClose}>
          Fechar
        </Button>
        
        {onEdit && canEdit && (
          <Button
            variant="outlined"
            onClick={() => {
              onEdit(transaction)
              onClose()
            }}
          >
            Editar
          </Button>
        )}
        
        {onCancel && canCancel && (
          <Button
            variant="contained"
            color="error"
            onClick={() => {
              onCancel(transaction)
              onClose()
            }}
          >
            Cancelar Transação
          </Button>
        )}
      </DialogActions>
    </Dialog>
  )
}