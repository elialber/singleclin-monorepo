import { useState, useCallback, useMemo } from 'react'
import {
  Box,
  Typography,
  Button,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  Container,
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
  Stack,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  TableSortLabel,
  Collapse,
  Divider,
} from '@mui/material'
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  Visibility as VisibilityIcon,
  VisibilityOff as VisibilityOffIcon,
  Refresh as RefreshIcon,
  FilterList as FilterIcon,
  ExpandLess as ExpandLessIcon,
  ExpandMore as ExpandMoreIcon,
} from '@mui/icons-material'
import { Plan } from '@/types/plan'
import { usePlans, useDeletePlan, useTogglePlanStatus, useInvalidatePlans } from '@/hooks/usePlans'
import { PlanQueryParams } from '@/services/plan.service'
import PlanFormDialog from '@/components/PlanFormDialog'
import ConfirmDialog from '@/components/ConfirmDialog'
import { useDebounce } from '@/hooks/useDebounce'
import { formatCurrency, formatDate } from '@/utils/format'

export default function Plans() {
  // State for filters and pagination
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)
  const [search, setSearch] = useState('')
  const [activeFilter, setActiveFilter] = useState<boolean | undefined>(undefined)
  
  // Advanced filters
  const [showAdvancedFilters, setShowAdvancedFilters] = useState(false)
  const [minPrice, setMinPrice] = useState<number | undefined>(undefined)
  const [maxPrice, setMaxPrice] = useState<number | undefined>(undefined)
  const [minCredits, setMinCredits] = useState<number | undefined>(undefined)
  const [maxCredits, setMaxCredits] = useState<number | undefined>(undefined)
  
  // Sorting
  const [sortBy, setSortBy] = useState<PlanQueryParams['sortBy']>('createdat')
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('desc')
  
  // Debounce search to avoid excessive API calls
  const debouncedSearch = useDebounce(search, 500)
  const debouncedMinPrice = useDebounce(minPrice, 500)
  const debouncedMaxPrice = useDebounce(maxPrice, 500)
  const debouncedMinCredits = useDebounce(minCredits, 500)
  const debouncedMaxCredits = useDebounce(maxCredits, 500)
  
  // Dialog states
  const [planDialogOpen, setPlanDialogOpen] = useState(false)
  const [selectedPlan, setSelectedPlan] = useState<Plan | null>(null)
  
  // Confirm dialog states
  const [confirmDialogOpen, setConfirmDialogOpen] = useState(false)
  const [confirmDialogTitle, setConfirmDialogTitle] = useState('')
  const [confirmDialogMessage, setConfirmDialogMessage] = useState('')
  const [confirmDialogAction, setConfirmDialogAction] = useState<(() => void) | null>(null)
  
  // Create query params
  const queryParams = useMemo<PlanQueryParams>(() => ({
    pageNumber: page + 1,
    pageSize: rowsPerPage,
    searchTerm: debouncedSearch || undefined,
    isActive: activeFilter,
    minPrice: debouncedMinPrice,
    maxPrice: debouncedMaxPrice,
    minCredits: debouncedMinCredits,
    maxCredits: debouncedMaxCredits,
    isFeatured: undefined,
    sortBy,
    sortDirection
  }), [page, rowsPerPage, debouncedSearch, activeFilter, debouncedMinPrice, debouncedMaxPrice, debouncedMinCredits, debouncedMaxCredits, sortBy, sortDirection])
  
  // TanStack Query hooks
  const { data: plansResponse, isLoading, error, refetch } = usePlans(queryParams)
  const deletePlan = useDeletePlan()
  const toggleStatus = useTogglePlanStatus()
  const invalidatePlans = useInvalidatePlans()

  // Extract data from response
  const plans = plansResponse?.data ?? []
  const total = plansResponse?.total ?? 0

  // Event handlers
  const handleChangePage = useCallback((event: unknown, newPage: number) => {
    setPage(newPage)
  }, [])

  const handleChangeRowsPerPage = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10))
    setPage(0)
  }, [])

  const handleSearchChange = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    setSearch(event.target.value)
    setPage(0) // Reset to first page when searching
  }, [])

  const handleActiveFilterChange = useCallback((value: string) => {
    setActiveFilter(value === 'all' ? undefined : value === 'active')
    setPage(0)
  }, [])


  const handleMinPriceChange = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const value = event.target.value
    setMinPrice(value ? Number(value) : undefined)
    setPage(0)
  }, [])

  const handleMaxPriceChange = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const value = event.target.value
    setMaxPrice(value ? Number(value) : undefined)
    setPage(0)
  }, [])

  const handleMinCreditsChange = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const value = event.target.value
    setMinCredits(value ? Number(value) : undefined)
    setPage(0)
  }, [])

  const handleMaxCreditsChange = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const value = event.target.value
    setMaxCredits(value ? Number(value) : undefined)
    setPage(0)
  }, [])

  const handleSort = useCallback((field: PlanQueryParams['sortBy']) => {
    if (sortBy === field) {
      setSortDirection(prev => prev === 'asc' ? 'desc' : 'asc')
    } else {
      setSortBy(field)
      setSortDirection('asc')
    }
    setPage(0)
  }, [sortBy])

  const handleClearFilters = useCallback(() => {
    setSearch('')
    setActiveFilter(undefined)
    setMinPrice(undefined)
    setMaxPrice(undefined)
    setMinCredits(undefined)
    setMaxCredits(undefined)
    setSortBy('createdat')
    setSortDirection('desc')
    setPage(0)
  }, [])

  const handleRefresh = useCallback(() => {
    refetch()
  }, [refetch])

  const handleCreatePlan = useCallback(() => {
    setSelectedPlan(null)
    setPlanDialogOpen(true)
  }, [])

  const handleEditPlan = useCallback((plan: Plan) => {
    setSelectedPlan(plan)
    setPlanDialogOpen(true)
  }, [])

  const handleDeletePlan = useCallback((plan: Plan) => {
    setConfirmDialogTitle('Confirmar exclusão')
    setConfirmDialogMessage(`Tem certeza que deseja excluir o plano "${plan.name}"? Esta ação não pode ser desfeita.`)
    setConfirmDialogAction(() => () => deletePlan.mutate(plan.id))
    setConfirmDialogOpen(true)
  }, [deletePlan])

  const handleToggleStatus = useCallback((plan: Plan) => {
    const action = plan.isActive ? 'desativar' : 'ativar'
    setConfirmDialogTitle(`Confirmar ${action}`)
    setConfirmDialogMessage(`Tem certeza que deseja ${action} o plano "${plan.name}"?`)
    setConfirmDialogAction(() => () => toggleStatus.mutate(plan.id))
    setConfirmDialogOpen(true)
  }, [toggleStatus])

  const handleCloseDialogs = useCallback(() => {
    setPlanDialogOpen(false)
    setConfirmDialogOpen(false)
    setSelectedPlan(null)
    setConfirmDialogAction(null)
  }, [])

  // Loading state
  if (isLoading && plans.length === 0) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress size={40} />
      </Box>
    )
  }

  return (
    <Container maxWidth="xl">
      <Box>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Box>
          <Typography variant="h4" fontWeight={600} gutterBottom>
            Planos
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Gerencie os planos de crédito disponíveis para os clientes
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleCreatePlan}
          size="large"
          disabled={error?.message?.includes('403') || error?.message?.includes('Forbidden')}
        >
          Novo Plano
        </Button>
      </Box>

      {/* Filters */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems="center" mb={2}>
          <TextField
            placeholder="Buscar planos..."
            value={search}
            onChange={handleSearchChange}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon />
                </InputAdornment>
              ),
            }}
            sx={{ minWidth: 300, flex: 1 }}
          />
          
          <FormControl sx={{ minWidth: 150 }}>
            <InputLabel>Status</InputLabel>
            <Select
              value={activeFilter === undefined ? 'all' : activeFilter ? 'active' : 'inactive'}
              onChange={(e) => handleActiveFilterChange(e.target.value)}
              label="Status"
              size="small"
            >
              <MenuItem value="all">Todos</MenuItem>
              <MenuItem value="active">Ativos</MenuItem>
              <MenuItem value="inactive">Inativos</MenuItem>
            </Select>
          </FormControl>

          <Button
            variant="outlined"
            startIcon={<FilterIcon />}
            endIcon={showAdvancedFilters ? <ExpandLessIcon /> : <ExpandMoreIcon />}
            onClick={() => setShowAdvancedFilters(!showAdvancedFilters)}
          >
            Filtros
          </Button>

          <Tooltip title="Limpar filtros">
            <Button
              variant="outlined"
              onClick={handleClearFilters}
              disabled={!search && activeFilter === undefined && !minPrice && !maxPrice && !minCredits && !maxCredits}
            >
              Limpar
            </Button>
          </Tooltip>

          <Tooltip title="Atualizar lista">
            <IconButton onClick={handleRefresh} disabled={isLoading}>
              <RefreshIcon />
            </IconButton>
          </Tooltip>
        </Stack>

        <Collapse in={showAdvancedFilters}>
          <Divider sx={{ mb: 2 }} />
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems="center">
            <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
              <Typography variant="body2" color="text.secondary" minWidth="60px">
                Preço:
              </Typography>
              <TextField
                placeholder="Min"
                type="number"
                value={minPrice || ''}
                onChange={handleMinPriceChange}
                size="small"
                sx={{ width: 100 }}
                InputProps={{
                  startAdornment: <InputAdornment position="start">R$</InputAdornment>,
                }}
              />
              <Typography variant="body2" color="text.secondary">
                até
              </Typography>
              <TextField
                placeholder="Max"
                type="number"
                value={maxPrice || ''}
                onChange={handleMaxPriceChange}
                size="small"
                sx={{ width: 100 }}
                InputProps={{
                  startAdornment: <InputAdornment position="start">R$</InputAdornment>,
                }}
              />
            </Box>

            <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
              <Typography variant="body2" color="text.secondary" minWidth="60px">
                Créditos:
              </Typography>
              <TextField
                placeholder="Min"
                type="number"
                value={minCredits || ''}
                onChange={handleMinCreditsChange}
                size="small"
                sx={{ width: 80 }}
              />
              <Typography variant="body2" color="text.secondary">
                até
              </Typography>
              <TextField
                placeholder="Max"
                type="number"
                value={maxCredits || ''}
                onChange={handleMaxCreditsChange}
                size="small"
                sx={{ width: 80 }}
              />
            </Box>

          </Stack>
        </Collapse>
      </Paper>

      {/* Error Alert */}
      {error && (
        <Alert 
          severity={error.message?.includes('403') || error.message?.includes('Forbidden') ? 'warning' : 'error'} 
          sx={{ mb: 2 }}
        >
          {error.message?.includes('403') || error.message?.includes('Forbidden') ? (
            <>
              <strong>Acesso negado:</strong> Você não tem permissão para gerenciar planos. 
              Entre em contato com um administrador para obter acesso.
            </>
          ) : (
            <>
              Erro ao carregar planos: {error.message}
              <Button size="small" onClick={handleRefresh} sx={{ ml: 1 }}>
                Tentar novamente
              </Button>
            </>
          )}
        </Alert>
      )}

      {/* Table */}
      <Paper>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>
                  <TableSortLabel
                    active={sortBy === 'name'}
                    direction={sortBy === 'name' ? sortDirection : 'asc'}
                    onClick={() => handleSort('name')}
                  >
                    Nome
                  </TableSortLabel>
                </TableCell>
                <TableCell>Descrição</TableCell>
                <TableCell align="center">
                  <TableSortLabel
                    active={sortBy === 'credits'}
                    direction={sortBy === 'credits' ? sortDirection : 'asc'}
                    onClick={() => handleSort('credits')}
                  >
                    Créditos
                  </TableSortLabel>
                </TableCell>
                <TableCell align="center">
                  <TableSortLabel
                    active={sortBy === 'price'}
                    direction={sortBy === 'price' ? sortDirection : 'asc'}
                    onClick={() => handleSort('price')}
                  >
                    Preço
                  </TableSortLabel>
                </TableCell>
                <TableCell align="center">Valor/Crédito</TableCell>
                <TableCell align="center">
                  <TableSortLabel
                    active={sortBy === 'isactive'}
                    direction={sortBy === 'isactive' ? sortDirection : 'asc'}
                    onClick={() => handleSort('isactive')}
                  >
                    Status
                  </TableSortLabel>
                </TableCell>
                <TableCell align="center">
                  <TableSortLabel
                    active={sortBy === 'createdat'}
                    direction={sortBy === 'createdat' ? sortDirection : 'asc'}
                    onClick={() => handleSort('createdat')}
                  >
                    Criado em
                  </TableSortLabel>
                </TableCell>
                <TableCell align="center" width="120">Ações</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {isLoading && plans.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={8} align="center" sx={{ py: 4 }}>
                    <CircularProgress size={32} />
                    <Typography variant="body2" sx={{ mt: 1 }}>
                      Carregando planos...
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : plans.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={8} align="center" sx={{ py: 4 }}>
                    <Typography variant="body2" color="text.secondary">
                      {debouncedSearch 
                        ? `Nenhum plano encontrado para "${debouncedSearch}"`
                        : 'Nenhum plano cadastrado'
                      }
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                plans.map((plan) => {
                  const pricePerCredit = plan.credits > 0 ? plan.price / plan.credits : 0
                  
                  return (
                    <TableRow key={plan.id} hover>
                      <TableCell>
                        <Typography variant="subtitle2" fontWeight={500}>
                          {plan.name}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Typography 
                          variant="body2" 
                          sx={{ 
                            maxWidth: 250,
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                            whiteSpace: 'nowrap'
                          }}
                          title={plan.description}
                        >
                          {plan.description}
                        </Typography>
                      </TableCell>
                      <TableCell align="center">
                        <Chip
                          label={plan.credits}
                          size="small"
                          variant="outlined"
                          color="primary"
                        />
                      </TableCell>
                      <TableCell align="center">
                        <Typography variant="body2" fontWeight={500}>
                          {formatCurrency(plan.price)}
                        </Typography>
                      </TableCell>
                      <TableCell align="center">
                        <Typography variant="body2" color="text.secondary">
                          {formatCurrency(pricePerCredit)}
                        </Typography>
                      </TableCell>
                      <TableCell align="center">
                        <Chip
                          label={plan.isActive ? 'Ativo' : 'Inativo'}
                          size="small"
                          color={plan.isActive ? 'success' : 'default'}
                          variant={plan.isActive ? 'filled' : 'outlined'}
                        />
                      </TableCell>
                      <TableCell align="center">
                        <Typography variant="body2" color="text.secondary">
                          {formatDate(plan.createdAt)}
                        </Typography>
                      </TableCell>
                      <TableCell align="center">
                        <Stack direction="row" spacing={0.5} justifyContent="center">
                          <Tooltip title="Editar">
                            <IconButton
                              size="small"
                              onClick={() => handleEditPlan(plan)}
                            >
                              <EditIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                          
                          <Tooltip title={plan.isActive ? 'Desativar' : 'Ativar'}>
                            <IconButton
                              size="small"
                              onClick={() => handleToggleStatus(plan)}
                              disabled={toggleStatus.isPending}
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
                              onClick={() => handleDeletePlan(plan)}
                              disabled={deletePlan.isPending}
                            >
                              <DeleteIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        </Stack>
                      </TableCell>
                    </TableRow>
                  )
                })
              )}
            </TableBody>
          </Table>
        </TableContainer>

        {/* Pagination */}
        <TablePagination
          component="div"
          count={total}
          page={page}
          onPageChange={handleChangePage}
          rowsPerPage={rowsPerPage}
          onRowsPerPageChange={handleChangeRowsPerPage}
          rowsPerPageOptions={[5, 10, 25, 50]}
          labelRowsPerPage="Itens por página:"
          labelDisplayedRows={({ from, to, count }) => 
            `${from}-${to} de ${count !== -1 ? count : `mais de ${to}`}`
          }
        />
      </Paper>

      {/* Dialogs */}
      <PlanFormDialog
        open={planDialogOpen}
        onClose={handleCloseDialogs}
        plan={selectedPlan}
      />

      <ConfirmDialog
        open={confirmDialogOpen}
        onClose={handleCloseDialogs}
        onConfirm={() => {
          confirmDialogAction?.()
          setConfirmDialogOpen(false)
        }}
        title={confirmDialogTitle}
        message={confirmDialogMessage}
        loading={deletePlan.isPending || toggleStatus.isPending}
      />
      </Box>
    </Container>
  )
}