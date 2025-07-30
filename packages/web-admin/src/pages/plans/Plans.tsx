import { useState, useEffect } from 'react'
import {
  Box,
  Typography,
  Button,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Chip,
  TablePagination,
  TextField,
  InputAdornment,
  CircularProgress,
  Alert,
  Tooltip,
} from '@mui/material'
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  Visibility as VisibilityIcon,
  VisibilityOff as VisibilityOffIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material'
import { Plan, CreatePlanRequest, UpdatePlanRequest } from '@/types/plan'
import { planService } from '@/services/plan.service'
import { useNotification } from '@/contexts/NotificationContext'
import PlanDialog from '@/components/PlanDialog'
import ConfirmDialog from '@/components/ConfirmDialog'

export default function Plans() {
  const [plans, setPlans] = useState<Plan[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)
  const [total, setTotal] = useState(0)
  const [search, setSearch] = useState('')
  const [searchDebounce, setSearchDebounce] = useState('')
  
  // Dialog states
  const [planDialogOpen, setPlanDialogOpen] = useState(false)
  const [selectedPlan, setSelectedPlan] = useState<Plan | null>(null)
  const [planDialogLoading, setPlanDialogLoading] = useState(false)
  
  // Delete confirmation dialog
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [planToDelete, setPlanToDelete] = useState<Plan | null>(null)
  const [deleteLoading, setDeleteLoading] = useState(false)

  const { showSuccess, showError } = useNotification()

  // Debounce search
  useEffect(() => {
    const timer = setTimeout(() => {
      setSearchDebounce(search)
    }, 500)
    return () => clearTimeout(timer)
  }, [search])

  // Load plans when page, search, or rowsPerPage changes
  useEffect(() => {
    loadPlans()
  }, [page, rowsPerPage, searchDebounce])

  const loadPlans = async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await planService.getPlans({
        page: page + 1, // API expects 1-based pagination
        limit: rowsPerPage,
        search: searchDebounce || undefined,
      })
      setPlans(response.data)
      setTotal(response.total)
    } catch (err: any) {
      console.error('Error loading plans:', err)
      setError('Erro ao carregar planos')
      showError('Erro ao carregar planos')
    } finally {
      setLoading(false)
    }
  }

  const handleChangePage = (_: unknown, newPage: number) => {
    setPage(newPage)
  }

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10))
    setPage(0)
  }

  // Dialog handlers
  const handleOpenCreateDialog = () => {
    setSelectedPlan(null)
    setPlanDialogOpen(true)
  }

  const handleOpenEditDialog = (plan: Plan) => {
    setSelectedPlan(plan)
    setPlanDialogOpen(true)
  }

  const handleCloseDialog = () => {
    setPlanDialogOpen(false)
    setSelectedPlan(null)
  }

  const handleSubmitPlan = async (data: CreatePlanRequest) => {
    try {
      setPlanDialogLoading(true)
      if (selectedPlan) {
        // Update
        await planService.updatePlan(selectedPlan.id, data as UpdatePlanRequest)
        showSuccess('Plano atualizado com sucesso!')
      } else {
        // Create
        await planService.createPlan(data)
        showSuccess('Plano criado com sucesso!')
      }
      loadPlans()
    } catch (err: any) {
      console.error('Error saving plan:', err)
      const message = err.response?.data?.message || 'Erro ao salvar plano'
      showError(message)
      throw err // Re-throw to prevent dialog from closing
    } finally {
      setPlanDialogLoading(false)
    }
  }

  const handleOpenDeleteDialog = (plan: Plan) => {
    setPlanToDelete(plan)
    setDeleteDialogOpen(true)
  }

  const handleCloseDeleteDialog = () => {
    setDeleteDialogOpen(false)
    setPlanToDelete(null)
  }

  const handleDeletePlan = async () => {
    if (!planToDelete) return

    try {
      setDeleteLoading(true)
      await planService.deletePlan(planToDelete.id)
      showSuccess('Plano excluído com sucesso!')
      handleCloseDeleteDialog()
      loadPlans()
    } catch (err: any) {
      console.error('Error deleting plan:', err)
      const message = err.response?.data?.message || 'Erro ao excluir plano'
      showError(message)
    } finally {
      setDeleteLoading(false)
    }
  }

  const handleToggleStatus = async (plan: Plan) => {
    try {
      await planService.togglePlanStatus(plan.id)
      showSuccess(`Plano ${plan.isActive ? 'desativado' : 'ativado'} com sucesso!`)
      loadPlans()
    } catch (err: any) {
      console.error('Error toggling plan status:', err)
      const message = err.response?.data?.message || 'Erro ao alterar status do plano'
      showError(message)
    }
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Box>
          <Typography variant="h4" fontWeight={600} gutterBottom>
            Planos
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Gerencie os planos de tratamento disponíveis
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleOpenCreateDialog}
        >
          Novo Plano
        </Button>
      </Box>

      {/* Search and filters */}
      <Box sx={{ mb: 3, display: 'flex', gap: 2, alignItems: 'center' }}>
        <TextField
          placeholder="Buscar planos..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon />
              </InputAdornment>
            ),
          }}
          sx={{ flexGrow: 1, maxWidth: 400 }}
        />
        <Button
          variant="outlined"
          startIcon={<RefreshIcon />}
          onClick={loadPlans}
          disabled={loading}
        >
          Atualizar
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Nome</TableCell>
              <TableCell>Descrição</TableCell>
              <TableCell align="center">Créditos</TableCell>
              <TableCell align="right">Preço</TableCell>
              <TableCell align="center">Clínica</TableCell>
              <TableCell align="center">Status</TableCell>
              <TableCell align="center">Ações</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={7} align="center" sx={{ py: 4 }}>
                  <CircularProgress />
                </TableCell>
              </TableRow>
            ) : plans.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} align="center" sx={{ py: 4 }}>
                  <Typography variant="body2" color="text.secondary">
                    {search ? 'Nenhum plano encontrado' : 'Nenhum plano cadastrado'}
                  </Typography>
                </TableCell>
              </TableRow>
            ) : (
              plans.map((plan) => (
                <TableRow key={plan.id} hover>
                  <TableCell>
                    <Typography variant="body2" fontWeight={600}>
                      {plan.name}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography 
                      variant="body2" 
                      color="text.secondary"
                      sx={{ 
                        maxWidth: 200, 
                        overflow: 'hidden', 
                        textOverflow: 'ellipsis',
                      }}
                    >
                      {plan.description}
                    </Typography>
                  </TableCell>
                  <TableCell align="center">{plan.credits}</TableCell>
                  <TableCell align="right">
                    R$ {plan.price.toFixed(2).replace('.', ',')}
                  </TableCell>
                  <TableCell align="center">
                    <Typography variant="body2" color="text.secondary">
                      {plan.clinicName || 'Geral'}
                    </Typography>
                  </TableCell>
                  <TableCell align="center">
                    <Chip
                      label={plan.isActive ? 'Ativo' : 'Inativo'}
                      color={plan.isActive ? 'success' : 'default'}
                      size="small"
                    />
                  </TableCell>
                  <TableCell align="center">
                    <Tooltip title="Editar">
                      <IconButton
                        size="small"
                        onClick={() => handleOpenEditDialog(plan)}
                      >
                        <EditIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title={plan.isActive ? 'Desativar' : 'Ativar'}>
                      <IconButton
                        size="small"
                        onClick={() => handleToggleStatus(plan)}
                        color={plan.isActive ? 'warning' : 'success'}
                      >
                        {plan.isActive ? (
                          <VisibilityOffIcon fontSize="small" />
                        ) : (
                          <VisibilityIcon fontSize="small" />
                        )}
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Excluir">
                      <IconButton
                        size="small"
                        color="error"
                        onClick={() => handleOpenDeleteDialog(plan)}
                      >
                        <DeleteIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
        <TablePagination
          rowsPerPageOptions={[5, 10, 25]}
          component="div"
          count={total}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
          labelRowsPerPage="Itens por página:"
          labelDisplayedRows={({ from, to, count }) =>
            `${from}-${to} de ${count !== -1 ? count : `mais de ${to}`}`
          }
        />
      </TableContainer>

      {/* Plan Dialog */}
      <PlanDialog
        open={planDialogOpen}
        onClose={handleCloseDialog}
        onSubmit={handleSubmitPlan}
        plan={selectedPlan}
        loading={planDialogLoading}
      />

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        open={deleteDialogOpen}
        onClose={handleCloseDeleteDialog}
        onConfirm={handleDeletePlan}
        title="Excluir Plano"
        message={`Tem certeza de que deseja excluir o plano "${planToDelete?.name}"? Esta ação não pode ser desfeita.`}
        confirmText="Excluir"
        loading={deleteLoading}
      />
    </Box>
  )
}