import { useState } from 'react'
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  Typography,
  Box,
  Stack,
  Chip,
  FormControlLabel,
  Checkbox,
  Alert,
  Divider,
  Card,
  CardContent,
  Grid,
} from '@mui/material'
import {
  Cancel as CancelIcon,
  Warning as WarningIcon,
  CreditCard as CreditCardIcon,
  AttachMoney as AttachMoneyIcon,
  Person as PersonIcon,
  Business as BusinessIcon,
} from '@mui/icons-material'
import { LoadingButton } from '@mui/lab'
import { Transaction, TransactionCancel } from '@/types/transaction'
import { useCancelTransaction } from '@/hooks/useTransactions'
import { format, parseISO } from 'date-fns'
import { ptBR } from 'date-fns/locale'

interface TransactionCancelModalProps {
  open: boolean
  transaction: Transaction | null
  onClose: () => void
}

export default function TransactionCancelModal({
  open,
  transaction,
  onClose,
}: TransactionCancelModalProps) {
  const [formData, setFormData] = useState<TransactionCancel>({
    cancellationReason: '',
    notes: '',
    refundCredits: true,
  })
  const [errors, setErrors] = useState<Record<string, string>>({})

  const cancelMutation = useCancelTransaction()

  const handleClose = () => {
    setFormData({
      cancellationReason: '',
      notes: '',
      refundCredits: true,
    })
    setErrors({})
    onClose()
  }

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {}

    if (!formData.cancellationReason.trim()) {
      newErrors.cancellationReason = 'Motivo do cancelamento é obrigatório'
    } else if (formData.cancellationReason.trim().length < 3) {
      newErrors.cancellationReason = 'Motivo deve ter pelo menos 3 caracteres'
    } else if (formData.cancellationReason.trim().length > 500) {
      newErrors.cancellationReason = 'Motivo não pode exceder 500 caracteres'
    }

    // Check for generic reasons
    const genericReasons = ['erro', 'error', 'cancel', 'cancelar', 'test', 'teste', 'wrong', 'errado']
    if (genericReasons.some(generic => 
      formData.cancellationReason.toLowerCase().includes(generic) && 
      formData.cancellationReason.trim().length < 10
    )) {
      newErrors.cancellationReason = 'Por favor, forneça um motivo mais específico'
    }

    if (formData.notes && formData.notes.length > 1000) {
      newErrors.notes = 'Observações não podem exceder 1000 caracteres'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async () => {
    if (!transaction || !validateForm()) return

    try {
      await cancelMutation.mutateAsync({
        id: transaction.id,
        data: formData,
      })
      handleClose()
    } catch (error) {
      // Error handling is done by the hook
    }
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

  const canCancel = transaction && (transaction.status === 'Pending' || transaction.status === 'Validated')

  if (!transaction) return null

  return (
    <Dialog
      open={open}
      onClose={handleClose}
      maxWidth="md"
      fullWidth
      PaperProps={{
        sx: { borderRadius: 2 }
      }}
    >
      <DialogTitle>
        <Stack direction="row" alignItems="center" spacing={2}>
          <CancelIcon color="error" />
          <Box>
            <Typography variant="h6" fontWeight={600}>
              Cancelar Transação
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {transaction.code}
            </Typography>
          </Box>
        </Stack>
      </DialogTitle>

      <DialogContent dividers>
        {/* Transaction Details Card */}
        <Card variant="outlined" sx={{ mb: 3 }}>
          <CardContent>
            <Typography variant="subtitle1" fontWeight={600} gutterBottom>
              Detalhes da Transação
            </Typography>
            
            <Grid container spacing={3}>
              <Grid item xs={12} md={6}>
                <Stack spacing={2}>
                  <Box>
                    <Stack direction="row" alignItems="center" spacing={1} mb={1}>
                      <PersonIcon fontSize="small" color="action" />
                      <Typography variant="body2" color="text.secondary">
                        Paciente
                      </Typography>
                    </Stack>
                    <Typography variant="body1" fontWeight={500}>
                      {transaction.patientName}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {transaction.patientEmail}
                    </Typography>
                  </Box>

                  <Box>
                    <Stack direction="row" alignItems="center" spacing={1} mb={1}>
                      <BusinessIcon fontSize="small" color="action" />
                      <Typography variant="body2" color="text.secondary">
                        Clínica
                      </Typography>
                    </Stack>
                    <Typography variant="body1" fontWeight={500}>
                      {transaction.clinicName}
                    </Typography>
                  </Box>
                </Stack>
              </Grid>

              <Grid item xs={12} md={6}>
                <Stack spacing={2}>
                  <Box>
                    <Stack direction="row" alignItems="center" spacing={1} mb={1}>
                      <AttachMoneyIcon fontSize="small" color="action" />
                      <Typography variant="body2" color="text.secondary">
                        Valor
                      </Typography>
                    </Stack>
                    <Typography variant="h6" color="primary.main">
                      R$ {transaction.amount.toFixed(2)}
                    </Typography>
                  </Box>

                  <Box>
                    <Stack direction="row" alignItems="center" spacing={1} mb={1}>
                      <CreditCardIcon fontSize="small" color="action" />
                      <Typography variant="body2" color="text.secondary">
                        Créditos
                      </Typography>
                    </Stack>
                    <Typography variant="body1" fontWeight={500}>
                      {transaction.creditsUsed} crédito{transaction.creditsUsed !== 1 ? 's' : ''}
                    </Typography>
                  </Box>
                </Stack>
              </Grid>

              <Grid item xs={12}>
                <Box>
                  <Typography variant="body2" color="text.secondary" gutterBottom>
                    Status
                  </Typography>
                  <Chip
                    label={getStatusLabel(transaction.status)}
                    color={getStatusColor(transaction.status)}
                    size="small"
                  />
                </Box>
              </Grid>

              <Grid item xs={12}>
                <Box>
                  <Typography variant="body2" color="text.secondary" gutterBottom>
                    Serviço
                  </Typography>
                  <Typography variant="body1">
                    {transaction.serviceDescription}
                  </Typography>
                  {transaction.serviceType && (
                    <Typography variant="body2" color="text.secondary">
                      Tipo: {transaction.serviceType}
                    </Typography>
                  )}
                </Box>
              </Grid>

              <Grid item xs={12}>
                <Box>
                  <Typography variant="body2" color="text.secondary" gutterBottom>
                    Data de Criação
                  </Typography>
                  <Typography variant="body2">
                    {formatDate(transaction.createdAt)}
                  </Typography>
                  {transaction.validationDate && (
                    <Typography variant="body2" color="text.secondary">
                      Validada em: {formatDate(transaction.validationDate)}
                    </Typography>
                  )}
                </Box>
              </Grid>
            </Grid>
          </CardContent>
        </Card>

        {/* Cancellation Warning */}
        {!canCancel ? (
          <Alert severity="error" sx={{ mb: 3 }}>
            <Typography variant="body2">
              Esta transação não pode ser cancelada. Apenas transações pendentes ou validadas podem ser canceladas.
            </Typography>
          </Alert>
        ) : (
          <Alert severity="warning" icon={<WarningIcon />} sx={{ mb: 3 }}>
            <Typography variant="body2" fontWeight={500}>
              Atenção: Esta ação não pode ser desfeita
            </Typography>
            <Typography variant="body2">
              Ao cancelar esta transação, ela será marcada como cancelada e 
              {formData.refundCredits ? ' os créditos serão devolvidos ao plano do paciente.' : ' os créditos NÃO serão devolvidos.'}
            </Typography>
          </Alert>
        )}

        {canCancel && (
          <Stack spacing={3}>
            {/* Cancellation Reason */}
            <TextField
              label="Motivo do Cancelamento *"
              multiline
              rows={3}
              value={formData.cancellationReason}
              onChange={(e) => setFormData(prev => ({ ...prev, cancellationReason: e.target.value }))}
              error={!!errors.cancellationReason}
              helperText={errors.cancellationReason || 'Descreva o motivo do cancelamento (3-500 caracteres)'}
              fullWidth
              placeholder="Ex: Paciente não compareceu ao atendimento agendado"
            />

            {/* Additional Notes */}
            <TextField
              label="Observações Adicionais"
              multiline
              rows={2}
              value={formData.notes}
              onChange={(e) => setFormData(prev => ({ ...prev, notes: e.target.value }))}
              error={!!errors.notes}
              helperText={errors.notes || 'Informações adicionais sobre o cancelamento (opcional)'}
              fullWidth
              placeholder="Ex: Reagendamento solicitado para próxima semana"
            />

            <Divider />

            {/* Refund Option */}
            <Box>
              <FormControlLabel
                control={
                  <Checkbox
                    checked={formData.refundCredits}
                    onChange={(e) => setFormData(prev => ({ ...prev, refundCredits: e.target.checked }))}
                    color="primary"
                  />
                }
                label={
                  <Box>
                    <Typography variant="body1" fontWeight={500}>
                      Devolver créditos ao paciente
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Se marcado, os {transaction.creditsUsed} crédito{transaction.creditsUsed !== 1 ? 's' : ''} será{transaction.creditsUsed !== 1 ? 'ão' : ''} devolvido{transaction.creditsUsed !== 1 ? 's' : ''} ao plano do paciente
                    </Typography>
                  </Box>
                }
              />

              {!formData.refundCredits && (
                <Alert severity="info" sx={{ mt: 2 }}>
                  <Typography variant="body2">
                    Os créditos não serão devolvidos. Esta opção deve ser usada apenas em casos específicos
                    como no-show do paciente ou violação de termos.
                  </Typography>
                </Alert>
              )}
            </Box>
          </Stack>
        )}
      </DialogContent>

      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={handleClose} disabled={cancelMutation.isPending}>
          Cancelar
        </Button>
        
        {canCancel && (
          <LoadingButton
            onClick={handleSubmit}
            loading={cancelMutation.isPending}
            variant="contained"
            color="error"
            startIcon={<CancelIcon />}
            disabled={!formData.cancellationReason.trim()}
          >
            {cancelMutation.isPending ? 'Cancelando...' : 'Cancelar Transação'}
          </LoadingButton>
        )}
      </DialogActions>
    </Dialog>
  )
}