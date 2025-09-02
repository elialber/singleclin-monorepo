import { useState, useCallback } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import {
  Box,
  Typography,
  Paper,
  Grid,
  Card,
  CardContent,
  Button,
  Chip,
  Divider,
  Stack,
  IconButton,
  CircularProgress,
  Alert,
  Avatar,
  Tabs,
  Tab,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  TextField,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  LinearProgress,
  Tooltip,
} from '@mui/material'
import {
  ArrowBack as ArrowBackIcon,
  Person as PersonIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  LocalHospital as ClinicIcon,
  CalendarToday as CalendarIcon,
  CreditCard as CreditCardIcon,
  Add as AddIcon,
  History as HistoryIcon,
  AccountBalance as BalanceIcon,
  CheckCircle as CheckCircleIcon,
  Schedule as ScheduleIcon,
  Cancel as CancelIcon,
} from '@mui/icons-material'
import { formatDate, formatCurrency, formatPhone } from '@/utils/format'
import { usePatient } from '@/hooks/usePatients'
import { useUserPlans, usePurchasePlan, useCancelUserPlan } from '@/hooks/useUserPlans'
import { useActivePlans } from '@/hooks/usePlans'
import { useNotification } from '@/hooks/useNotification'
import { PurchasePlanRequest } from '@/types/userplan'
import { Plan } from '@/types/plan'

interface TabPanelProps {
  children?: React.ReactNode
  index: number
  value: number
}

function TabPanel({ children, value, index }: TabPanelProps) {
  return (
    <div role="tabpanel" hidden={value !== index}>
      {value === index && <Box sx={{ py: 3 }}>{children}</Box>}
    </div>
  )
}

export default function PatientDetails() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { showNotification } = useNotification()
  
  const [currentTab, setCurrentTab] = useState(0)
  const [purchaseDialogOpen, setPurchaseDialogOpen] = useState(false)
  const [cancelDialogOpen, setCancelDialogOpen] = useState(false)
  const [selectedPlan, setSelectedPlan] = useState<Plan | null>(null)
  const [selectedUserPlan, setSelectedUserPlan] = useState<any>(null)
  const [paymentMethod, setPaymentMethod] = useState('')
  const [notes, setNotes] = useState('')
  const [cancelReason, setCancelReason] = useState('')

  // Queries
  const { data: patient, isLoading: patientLoading, error: patientError } = usePatient(id!)
  const { data: userPlans, isLoading: plansLoading } = useUserPlans(id!)
  const { data: availablePlans, isLoading: availablePlansLoading } = useActivePlans()
  
  // Mutations
  const purchasePlan = usePurchasePlan()
  const cancelUserPlan = useCancelUserPlan()

  // Handlers
  const handleBack = useCallback(() => {
    navigate('/patients')
  }, [navigate])

  const handleTabChange = useCallback((_: React.SyntheticEvent, newValue: number) => {
    setCurrentTab(newValue)
  }, [])

  const handleOpenPurchaseDialog = useCallback(() => {
    setPurchaseDialogOpen(true)
  }, [])

  const handleClosePurchaseDialog = useCallback(() => {
    setPurchaseDialogOpen(false)
    setSelectedPlan(null)
    setPaymentMethod('')
    setNotes('')
  }, [])

  const handlePurchasePlan = useCallback(async () => {
    if (!selectedPlan || !id) return

    const request: PurchasePlanRequest = {
      planId: selectedPlan.id,
      paymentMethod: paymentMethod || undefined,
      notes: notes || undefined
    }

    try {
      await purchasePlan.mutateAsync({ userId: id, request })
      handleClosePurchaseDialog()
    } catch (error) {
      // Error is handled by the mutation hook
    }
  }, [selectedPlan, id, paymentMethod, notes, purchasePlan, handleClosePurchaseDialog])

  const handleOpenCancelDialog = useCallback((userPlan: any) => {
    setSelectedUserPlan(userPlan)
    setCancelDialogOpen(true)
  }, [])

  const handleCloseCancelDialog = useCallback(() => {
    setCancelDialogOpen(false)
    setSelectedUserPlan(null)
    setCancelReason('')
  }, [])

  const handleCancelPlan = useCallback(async () => {
    if (!selectedUserPlan || !id) return

    try {
      await cancelUserPlan.mutateAsync({
        userId: id,
        userPlanId: selectedUserPlan.id,
        reason: cancelReason || undefined
      })
      handleCloseCancelDialog()
    } catch (error) {
      // Error is handled by the mutation hook
    }
  }, [selectedUserPlan, id, cancelReason, cancelUserPlan, handleCloseCancelDialog])

  // Loading state
  if (patientLoading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress size={40} />
      </Box>
    )
  }

  // Error state
  if (patientError || !patient) {
    return (
      <Box>
        <Button
          startIcon={<ArrowBackIcon />}
          onClick={handleBack}
          sx={{ mb: 2 }}
        >
          Voltar
        </Button>
        <Alert severity="error">
          {patientError?.message || 'Paciente não encontrado'}
        </Alert>
      </Box>
    )
  }

  const activePlans = Array.isArray(userPlans) ? userPlans.filter(plan => plan.isActive && !plan.isExpired) : []
  const hasActivePlans = activePlans.length > 0

  return (
    <Box>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Box display="flex" alignItems="center" gap={2}>
          <IconButton onClick={handleBack} size="small">
            <ArrowBackIcon />
          </IconButton>
          <Box>
            <Typography variant="h4" fontWeight={600}>
              {patient.fullName}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Detalhes do paciente
            </Typography>
          </Box>
        </Box>
        
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleOpenPurchaseDialog}
          disabled={availablePlansLoading}
        >
          Atribuir Plano
        </Button>
      </Box>

      {/* Patient Info */}
      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} md={8}>
          <Paper sx={{ p: 3 }}>
            <Box display="flex" alignItems="center" gap={2} mb={3}>
              <Avatar sx={{ width: 64, height: 64, bgcolor: 'primary.main' }}>
                <PersonIcon fontSize="large" />
              </Avatar>
              <Box flex={1}>
                <Typography variant="h5" fontWeight={600} mb={1}>
                  {patient.fullName}
                </Typography>
                <Chip
                  label={patient.isActive ? 'Ativo' : 'Inativo'}
                  size="small"
                  color={patient.isActive ? 'success' : 'default'}
                  variant={patient.isActive ? 'filled' : 'outlined'}
                />
              </Box>
            </Box>

            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <Box display="flex" alignItems="center" gap={1} mb={2}>
                  <EmailIcon color="action" />
                  <Typography variant="body2" color="text.secondary">
                    {patient.email}
                  </Typography>
                </Box>
              </Grid>
              
              {patient.phoneNumber && (
                <Grid item xs={12} sm={6}>
                  <Box display="flex" alignItems="center" gap={1} mb={2}>
                    <PhoneIcon color="action" />
                    <Typography variant="body2" color="text.secondary">
                      {formatPhone(patient.phoneNumber)}
                    </Typography>
                  </Box>
                </Grid>
              )}

              <Grid item xs={12} sm={6}>
                <Box display="flex" alignItems="center" gap={1} mb={2}>
                  <CalendarIcon color="action" />
                  <Typography variant="body2" color="text.secondary">
                    Cadastrado em {formatDate(patient.createdAt)}
                  </Typography>
                </Box>
              </Grid>

              {patient.clinicId && (
                <Grid item xs={12} sm={6}>
                  <Box display="flex" alignItems="center" gap={1} mb={2}>
                    <ClinicIcon color="action" />
                    <Typography variant="body2" color="text.secondary">
                      Associado à clínica
                    </Typography>
                  </Box>
                </Grid>
              )}
            </Grid>
          </Paper>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" gap={1} mb={2}>
                <BalanceIcon color="primary" />
                <Typography variant="h6" fontWeight={600}>
                  Resumo de Planos
                </Typography>
              </Box>
              
              {plansLoading ? (
                <CircularProgress size={24} />
              ) : hasActivePlans ? (
                <Box>
                  <Typography variant="h4" color="primary.main" fontWeight={700} mb={1}>
                    {activePlans.reduce((total, plan) => total + plan.creditsRemaining, 0)}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" mb={2}>
                    Créditos disponíveis
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {activePlans.length} plano(s) ativo(s)
                  </Typography>
                </Box>
              ) : (
                <Box>
                  <Typography variant="body2" color="text.secondary" mb={2}>
                    Nenhum plano ativo
                  </Typography>
                  <Button
                    variant="outlined"
                    size="small"
                    startIcon={<AddIcon />}
                    onClick={handleOpenPurchaseDialog}
                    fullWidth
                  >
                    Atribuir primeiro plano
                  </Button>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Tabs */}
      <Paper sx={{ mb: 3 }}>
        <Tabs value={currentTab} onChange={handleTabChange}>
          <Tab 
            icon={<CreditCardIcon />} 
            label="Planos Ativos" 
            iconPosition="start"
          />
          <Tab 
            icon={<HistoryIcon />} 
            label="Histórico de Transações" 
            iconPosition="start"
          />
        </Tabs>

        <TabPanel value={currentTab} index={0}>
          {/* Active Plans Tab */}
          {plansLoading ? (
            <Box display="flex" justifyContent="center" py={4}>
              <CircularProgress />
            </Box>
          ) : activePlans.length === 0 ? (
            <Box textAlign="center" py={4}>
              <Typography variant="body2" color="text.secondary" mb={2}>
                Este paciente ainda não possui planos ativos
              </Typography>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={handleOpenPurchaseDialog}
              >
                Atribuir primeiro plano
              </Button>
            </Box>
          ) : (
            <Grid container spacing={3}>
              {activePlans.map((userPlan) => (
                <Grid item xs={12} md={6} lg={4} key={userPlan.id}>
                  <Card sx={{ height: '100%' }}>
                    <CardContent>
                      <Box display="flex" justifyContent="between" alignItems="start" mb={2}>
                        <Typography variant="h6" fontWeight={600}>
                          {userPlan.plan.name}
                        </Typography>
                        <Chip
                          icon={<CheckCircleIcon />}
                          label="Ativo"
                          size="small"
                          color="success"
                          variant="filled"
                        />
                      </Box>

                      <Typography variant="body2" color="text.secondary" mb={2}>
                        {userPlan.plan.description}
                      </Typography>

                      {/* Progress Bar */}
                      <Box mb={2}>
                        <Box display="flex" justifyContent="between" alignItems="center" mb={1}>
                          <Typography variant="body2" fontWeight={500}>
                            Créditos utilizados
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            {userPlan.creditsUsed} / {userPlan.credits}
                          </Typography>
                        </Box>
                        <LinearProgress
                          variant="determinate"
                          value={(userPlan.creditsUsed / userPlan.credits) * 100}
                          sx={{ height: 8, borderRadius: 1 }}
                        />
                      </Box>

                      <Stack spacing={1}>
                        <Box display="flex" justifyContent="between">
                          <Typography variant="body2" color="text.secondary">
                            Créditos restantes:
                          </Typography>
                          <Typography variant="body2" fontWeight={600} color="primary">
                            {userPlan.creditsRemaining}
                          </Typography>
                        </Box>

                        <Box display="flex" justifyContent="between">
                          <Typography variant="body2" color="text.secondary">
                            Valor pago:
                          </Typography>
                          <Typography variant="body2" fontWeight={600}>
                            {formatCurrency(userPlan.amountPaid)}
                          </Typography>
                        </Box>

                        <Box display="flex" justifyContent="between">
                          <Typography variant="body2" color="text.secondary">
                            Expira em:
                          </Typography>
                          <Typography variant="body2" fontWeight={600}>
                            {formatDate(userPlan.expirationDate)}
                          </Typography>
                        </Box>

                        {userPlan.paymentMethod && (
                          <Box display="flex" justifyContent="between">
                            <Typography variant="body2" color="text.secondary">
                              Pagamento:
                            </Typography>
                            <Typography variant="body2">
                              {userPlan.paymentMethod}
                            </Typography>
                          </Box>
                        )}
                        
                        <Divider sx={{ my: 1 }} />
                        
                        <Button
                          variant="outlined"
                          color="error"
                          size="small"
                          startIcon={<CancelIcon />}
                          onClick={() => handleOpenCancelDialog(userPlan)}
                          fullWidth
                        >
                          Cancelar Plano
                        </Button>
                      </Stack>
                    </CardContent>
                  </Card>
                </Grid>
              ))}
            </Grid>
          )}
        </TabPanel>

        <TabPanel value={currentTab} index={1}>
          {/* Transactions Tab */}
          <Box>
            <Typography variant="body2" color="text.secondary" textAlign="center" py={4}>
              Histórico de transações será implementado em breve
            </Typography>
          </Box>
        </TabPanel>
      </Paper>

      {/* Purchase Plan Dialog */}
      <Dialog 
        open={purchaseDialogOpen} 
        onClose={handleClosePurchaseDialog}
        maxWidth="sm" 
        fullWidth
      >
        <DialogTitle>Atribuir Plano</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" mb={3}>
            Selecione um plano para atribuir ao paciente {patient.fullName}
          </Typography>

          <FormControl fullWidth margin="normal">
            <InputLabel>Plano</InputLabel>
            <Select
              value={selectedPlan?.id || ''}
              onChange={(e) => {
                const plan = availablePlans?.find(p => p.id === e.target.value)
                setSelectedPlan(plan || null)
              }}
              label="Plano"
            >
              {availablePlans?.map((plan) => (
                <MenuItem key={plan.id} value={plan.id}>
                  <Box>
                    <Typography variant="subtitle2">{plan.name}</Typography>
                    <Typography variant="body2" color="text.secondary">
                      {plan.credits} créditos - {formatCurrency(plan.price)}
                    </Typography>
                  </Box>
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          <FormControl fullWidth margin="normal">
            <InputLabel>Método de Pagamento (Opcional)</InputLabel>
            <Select
              value={paymentMethod}
              onChange={(e) => setPaymentMethod(e.target.value)}
              label="Método de Pagamento (Opcional)"
            >
              <MenuItem value="">Não especificado</MenuItem>
              <MenuItem value="Cartão de Crédito">Cartão de Crédito</MenuItem>
              <MenuItem value="Cartão de Débito">Cartão de Débito</MenuItem>
              <MenuItem value="PIX">PIX</MenuItem>
              <MenuItem value="Boleto">Boleto</MenuItem>
              <MenuItem value="Dinheiro">Dinheiro</MenuItem>
              <MenuItem value="Cortesia">Cortesia</MenuItem>
            </Select>
          </FormControl>

          <TextField
            fullWidth
            label="Observações (Opcional)"
            multiline
            rows={3}
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            margin="normal"
            placeholder="Adicione observações sobre esta atribuição de plano..."
          />

          {selectedPlan && (
            <Paper sx={{ p: 2, mt: 2, bgcolor: 'grey.50' }}>
              <Typography variant="subtitle2" fontWeight={600} mb={1}>
                Resumo da Atribuição
              </Typography>
              <Stack spacing={1}>
                <Box display="flex" justifyContent="between">
                  <Typography variant="body2">Plano:</Typography>
                  <Typography variant="body2" fontWeight={600}>
                    {selectedPlan.name}
                  </Typography>
                </Box>
                <Box display="flex" justifyContent="between">
                  <Typography variant="body2">Créditos:</Typography>
                  <Typography variant="body2" fontWeight={600}>
                    {selectedPlan.credits}
                  </Typography>
                </Box>
                <Box display="flex" justifyContent="between">
                  <Typography variant="body2">Valor:</Typography>
                  <Typography variant="body2" fontWeight={600}>
                    {formatCurrency(selectedPlan.price)}
                  </Typography>
                </Box>
                <Box display="flex" justifyContent="between">
                  <Typography variant="body2">Validade:</Typography>
                  <Typography variant="body2" fontWeight={600}>
                    {selectedPlan.validityDays} dias
                  </Typography>
                </Box>
              </Stack>
            </Paper>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClosePurchaseDialog}>
            Cancelar
          </Button>
          <Button
            variant="contained"
            onClick={handlePurchasePlan}
            disabled={!selectedPlan || purchasePlan.isPending}
          >
            {purchasePlan.isPending ? 'Processando...' : 'Atribuir Plano'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Cancel Plan Dialog */}
      <Dialog 
        open={cancelDialogOpen} 
        onClose={handleCloseCancelDialog}
        maxWidth="sm" 
        fullWidth
      >
        <DialogTitle>Cancelar Plano</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" mb={2}>
            Tem certeza que deseja cancelar o plano <strong>{selectedUserPlan?.plan?.name}</strong> do paciente {patient.fullName}?
          </Typography>
          
          <Alert severity="warning" sx={{ mb: 3 }}>
            Esta ação não pode ser desfeita. O paciente perderá todos os créditos restantes deste plano.
          </Alert>

          {selectedUserPlan && (
            <Paper sx={{ p: 2, mb: 2, bgcolor: 'grey.50' }}>
              <Typography variant="subtitle2" fontWeight={600} mb={1}>
                Detalhes do Plano
              </Typography>
              <Stack spacing={1}>
                <Box display="flex" justifyContent="between">
                  <Typography variant="body2">Plano:</Typography>
                  <Typography variant="body2" fontWeight={600}>
                    {selectedUserPlan.plan?.name}
                  </Typography>
                </Box>
                <Box display="flex" justifyContent="between">
                  <Typography variant="body2">Créditos restantes:</Typography>
                  <Typography variant="body2" fontWeight={600} color="error">
                    {selectedUserPlan.creditsRemaining}
                  </Typography>
                </Box>
                <Box display="flex" justifyContent="between">
                  <Typography variant="body2">Valor pago:</Typography>
                  <Typography variant="body2" fontWeight={600}>
                    {formatCurrency(selectedUserPlan.amountPaid)}
                  </Typography>
                </Box>
                <Box display="flex" justifyContent="between">
                  <Typography variant="body2">Data de expiração:</Typography>
                  <Typography variant="body2" fontWeight={600}>
                    {formatDate(selectedUserPlan.expirationDate)}
                  </Typography>
                </Box>
              </Stack>
            </Paper>
          )}

          <TextField
            fullWidth
            label="Motivo do cancelamento (opcional)"
            multiline
            rows={3}
            value={cancelReason}
            onChange={(e) => setCancelReason(e.target.value)}
            placeholder="Descreva o motivo do cancelamento do plano..."
            margin="normal"
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseCancelDialog}>
            Manter Plano
          </Button>
          <Button
            variant="contained"
            color="error"
            onClick={handleCancelPlan}
            disabled={cancelUserPlan.isPending}
          >
            {cancelUserPlan.isPending ? 'Cancelando...' : 'Confirmar Cancelamento'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  )
}