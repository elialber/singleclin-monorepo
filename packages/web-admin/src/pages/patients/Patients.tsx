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
  Card,
  CardContent,
  CardActions,
  Grid,
  ToggleButton,
  ToggleButtonGroup,
} from '@mui/material'
import {
  Search as SearchIcon,
  Visibility as VisibilityIcon,
  VisibilityOff as VisibilityOffIcon,
  Refresh as RefreshIcon,
  FilterList as FilterIcon,
  ExpandLess as ExpandLessIcon,
  ExpandMore as ExpandMoreIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  ViewList as ViewListIcon,
  ViewModule as ViewModuleIcon,
  Person as PersonIcon,
  LocalHospital as ClinicIcon,
} from '@mui/icons-material'
import { Patient } from '@/types/patient'
import { 
  usePatients, 
 
  useTogglePatientStatus, 
} from '@/hooks/usePatients'
import { PatientQueryParams } from '@/services/patient.service'
import ConfirmDialog from '@/components/ConfirmDialog'
import { useDebounce } from '@/hooks/useDebounce'
import { formatDate, formatPhone } from '@/utils/format'

export default function Patients() {
  // State for filters and pagination
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)
  const [search, setSearch] = useState('')
  const [activeFilter, setActiveFilter] = useState<boolean | undefined>(undefined)
  
  // View mode
  const [viewMode, setViewMode] = useState<'list' | 'cards'>('list')

  // Adjust rowsPerPage when view mode changes
  const handleViewModeChange = useCallback((newViewMode: 'list' | 'cards') => {
    if (!newViewMode) return
    
    setViewMode(newViewMode)
    
    // Adjust pagination for better UX
    if (newViewMode === 'cards' && rowsPerPage < 6) {
      setRowsPerPage(12)
    } else if (newViewMode === 'list' && rowsPerPage > 50) {
      setRowsPerPage(10)
    }
    setPage(0)
  }, [rowsPerPage])
  
  // Advanced filters
  const [showAdvancedFilters, setShowAdvancedFilters] = useState(false)
  const [hasPlanFilter, setHasPlanFilter] = useState<boolean | undefined>(undefined)
  
  // Sorting
  const [sortBy, setSortBy] = useState<'fullName' | 'email' | 'isActive' | 'createdAt'>('createdAt')
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('desc')
  
  // Debounce search to avoid excessive API calls
  const debouncedSearch = useDebounce(search, 500)
  
  // Dialog states
  
  // Confirm dialog states
  const [confirmDialogOpen, setConfirmDialogOpen] = useState(false)
  const [confirmDialogTitle, setConfirmDialogTitle] = useState('')
  const [confirmDialogMessage, setConfirmDialogMessage] = useState('')
  const [confirmDialogAction, setConfirmDialogAction] = useState<(() => void) | null>(null)
  
  // Create query params
  const queryParams = useMemo<PatientQueryParams>(() => ({
    page: page + 1,
    limit: rowsPerPage,
    search: debouncedSearch || undefined,
    isActive: activeFilter,
    hasPlan: hasPlanFilter,
  }), [page, rowsPerPage, debouncedSearch, activeFilter, hasPlanFilter])
  
  // TanStack Query hooks
  const { data: patientsResponse, isLoading, error, refetch } = usePatients(queryParams)
  const toggleStatus = useTogglePatientStatus()

  // Extract data from response
  const patients = patientsResponse?.data ?? []
  const total = patientsResponse?.total ?? 0

  // Event handlers
  const handleChangePage = useCallback((_: unknown, newPage: number) => {
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

  const handleHasPlanFilterChange = useCallback((value: string) => {
    setHasPlanFilter(value === 'all' ? undefined : value === 'yes')
    setPage(0)
  }, [])

  const handleSort = useCallback((field: typeof sortBy) => {
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
    setHasPlanFilter(undefined)
    setSortBy('createdAt')
    setSortDirection('desc')
    setPage(0)
  }, [])

  const handleRefresh = useCallback(() => {
    refetch()
  }, [refetch])




  const handleToggleStatus = useCallback((patient: Patient) => {
    const action = patient.isActive ? 'desativar' : 'ativar'
    setConfirmDialogTitle(`Confirmar ${action}`)
    setConfirmDialogMessage(`Tem certeza que deseja ${action} o paciente "${patient.fullName}"?`)
    setConfirmDialogAction(() => () => toggleStatus.mutate(patient.id))
    setConfirmDialogOpen(true)
  }, [toggleStatus])

  const handleCloseDialogs = useCallback(() => {
    setConfirmDialogOpen(false)
    setConfirmDialogAction(null)
  }, [])

  // Loading state
  if (isLoading && patients.length === 0) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress size={40} />
      </Box>
    )
  }

  return (
    <Box>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Box>
          <Typography variant="h4" fontWeight={600} gutterBottom>
            Pacientes
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Consulte os pacientes do sistema
          </Typography>
        </Box>
      </Box>

      {/* Filters */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems="center" mb={2}>
          <TextField
            placeholder="Buscar por nome ou email..."
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

          <FormControl sx={{ minWidth: 120 }}>
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
              disabled={!search && activeFilter === undefined && hasPlanFilter === undefined}
            >
              Limpar
            </Button>
          </Tooltip>

          <Tooltip title="Atualizar lista">
            <IconButton onClick={handleRefresh} disabled={isLoading}>
              <RefreshIcon />
            </IconButton>
          </Tooltip>

          <ToggleButtonGroup
            value={viewMode}
            exclusive
            onChange={(_, newViewMode) => handleViewModeChange(newViewMode)}
            size="small"
          >
            <ToggleButton value="list" aria-label="Lista">
              <Tooltip title="Visualização em lista">
                <ViewListIcon />
              </Tooltip>
            </ToggleButton>
            <ToggleButton value="cards" aria-label="Cards">
              <Tooltip title="Visualização em cards">
                <ViewModuleIcon />
              </Tooltip>
            </ToggleButton>
          </ToggleButtonGroup>
        </Stack>

        <Collapse in={showAdvancedFilters}>
          <Divider sx={{ mb: 2 }} />
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems="center">
            <FormControl sx={{ minWidth: 150 }}>
              <InputLabel>Possui Plano</InputLabel>
              <Select
                value={hasPlanFilter === undefined ? 'all' : hasPlanFilter ? 'yes' : 'no'}
                onChange={(e) => handleHasPlanFilterChange(e.target.value)}
                label="Possui Plano"
                size="small"
              >
                <MenuItem value="all">Todos</MenuItem>
                <MenuItem value="yes">Com plano</MenuItem>
                <MenuItem value="no">Sem plano</MenuItem>
              </Select>
            </FormControl>
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
              <strong>Acesso negado:</strong> Você não tem permissão para gerenciar pacientes. 
              Entre em contato com um administrador para obter acesso.
            </>
          ) : (
            <>
              Erro ao carregar pacientes: {error.message}
              <Button size="small" onClick={handleRefresh} sx={{ ml: 1 }}>
                Tentar novamente
              </Button>
            </>
          )}
        </Alert>
      )}

      {/* Content */}
      {viewMode === 'cards' ? (
        // Cards View
        <Box>
          {isLoading && patients.length === 0 ? (
            <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
              <CircularProgress size={40} />
              <Typography variant="body2" sx={{ ml: 2 }}>
                Carregando pacientes...
              </Typography>
            </Box>
          ) : patients.length === 0 ? (
            <Paper sx={{ p: 4, textAlign: 'center' }}>
              <Typography variant="body2" color="text.secondary">
                {debouncedSearch 
                  ? `Nenhum paciente encontrado para "${debouncedSearch}"`
                  : 'Nenhum paciente cadastrado'
                }
              </Typography>
            </Paper>
          ) : (
            <Grid container spacing={3}>
              {patients.map((patient) => (
                <Grid item xs={12} sm={6} md={4} lg={3} key={patient.id}>
                  <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
                    <CardContent sx={{ flex: 1 }}>
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                        <Typography variant="h6" fontWeight={600} noWrap sx={{ flex: 1, mr: 1 }}>
                          {patient.fullName}
                        </Typography>
                        <Chip
                          label={patient.isActive ? 'Ativo' : 'Inativo'}
                          size="small"
                          color={patient.isActive ? 'success' : 'default'}
                          variant={patient.isActive ? 'filled' : 'outlined'}
                        />
                      </Box>

                      {patient.hasPlan && (
                        <Chip
                          label="Com plano"
                          size="small"
                          color="info"
                          variant="filled"
                          sx={{ mb: 2 }}
                        />
                      )}

                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <EmailIcon fontSize="small" color="action" />
                          <Typography variant="body2" color="text.secondary" noWrap>
                            {patient.email}
                          </Typography>
                        </Box>
                        
                        {patient.phoneNumber && (
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <PhoneIcon fontSize="small" color="action" />
                            <Typography variant="body2" color="text.secondary">
                              {formatPhone(patient.phoneNumber)}
                            </Typography>
                          </Box>
                        )}

                        {patient.clinicId && (
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <ClinicIcon fontSize="small" color="action" />
                            <Typography variant="body2" color="text.secondary">
                              Associado à clínica
                            </Typography>
                          </Box>
                        )}
                      </Box>

                      <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 2 }}>
                        Criado em {formatDate(patient.createdAt)}
                      </Typography>
                    </CardContent>

                    <CardActions sx={{ p: 2, pt: 0, justifyContent: 'flex-end' }}>
                      
                      <Tooltip title={patient.isActive ? 'Desativar' : 'Ativar'}>
                        <IconButton
                          size="small"
                          onClick={() => handleToggleStatus(patient)}
                          disabled={toggleStatus.isPending}
                        >
                          {patient.isActive ? (
                            <VisibilityOffIcon fontSize="small" />
                          ) : (
                            <VisibilityIcon fontSize="small" />
                          )}
                        </IconButton>
                      </Tooltip>
                      
                    </CardActions>
                  </Card>
                </Grid>
              ))}
            </Grid>
          )}

          {/* Pagination for Cards */}
          {patients.length > 0 && (
            <Paper sx={{ mt: 2 }}>
              <TablePagination
                component="div"
                count={total}
                page={page}
                onPageChange={handleChangePage}
                rowsPerPage={rowsPerPage}
                onRowsPerPageChange={handleChangeRowsPerPage}
                rowsPerPageOptions={[6, 12, 24, 48]}
                labelRowsPerPage="Cards por página:"
                labelDisplayedRows={({ from, to, count }) => 
                  `${from}-${to} de ${count !== -1 ? count : `mais de ${to}`}`
                }
              />
            </Paper>
          )}
        </Box>
      ) : (
        // Table View
        <Paper>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>
                  <TableSortLabel
                    active={sortBy === 'fullName'}
                    direction={sortBy === 'fullName' ? sortDirection : 'asc'}
                    onClick={() => handleSort('fullName')}
                  >
                    Nome
                  </TableSortLabel>
                </TableCell>
                <TableCell>
                  <TableSortLabel
                    active={sortBy === 'email'}
                    direction={sortBy === 'email' ? sortDirection : 'asc'}
                    onClick={() => handleSort('email')}
                  >
                    Email
                  </TableSortLabel>
                </TableCell>
                <TableCell>Telefone</TableCell>
                <TableCell align="center">
                  <TableSortLabel
                    active={sortBy === 'isActive'}
                    direction={sortBy === 'isActive' ? sortDirection : 'asc'}
                    onClick={() => handleSort('isActive')}
                  >
                    Status
                  </TableSortLabel>
                </TableCell>
                <TableCell>Clínica</TableCell>
                <TableCell align="center">
                  <TableSortLabel
                    active={sortBy === 'createdAt'}
                    direction={sortBy === 'createdAt' ? sortDirection : 'asc'}
                    onClick={() => handleSort('createdAt')}
                  >
                    Criado em
                  </TableSortLabel>
                </TableCell>
                <TableCell align="center" width="140">Ações</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {isLoading && patients.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={7} align="center" sx={{ py: 4 }}>
                    <CircularProgress size={32} />
                    <Typography variant="body2" sx={{ mt: 1 }}>
                      Carregando pacientes...
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : patients.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={7} align="center" sx={{ py: 4 }}>
                    <Typography variant="body2" color="text.secondary">
                      {debouncedSearch 
                        ? `Nenhum paciente encontrado para "${debouncedSearch}"`
                        : 'Nenhum paciente cadastrado'
                      }
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                patients.map((patient) => (
                  <TableRow key={patient.id} hover>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <PersonIcon fontSize="small" color="action" />
                        <Box>
                          <Typography variant="subtitle2" fontWeight={500}>
                            {patient.fullName}
                          </Typography>
                          {patient.hasPlan && (
                            <Chip
                              label="Com plano"
                              size="small"
                              color="info"
                              variant="outlined"
                              sx={{ mt: 0.5 }}
                            />
                          )}
                        </Box>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" color="text.secondary">
                        {patient.email}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      {patient.phoneNumber ? (
                        <Typography variant="body2" color="text.secondary">
                          {formatPhone(patient.phoneNumber)}
                        </Typography>
                      ) : (
                        <Typography variant="body2" color="text.disabled">
                          —
                        </Typography>
                      )}
                    </TableCell>
                    <TableCell align="center">
                      <Chip
                        label={patient.isActive ? 'Ativo' : 'Inativo'}
                        size="small"
                        color={patient.isActive ? 'success' : 'default'}
                        variant={patient.isActive ? 'filled' : 'outlined'}
                      />
                    </TableCell>
                    <TableCell>
                      {patient.clinicId ? (
                        <Chip
                          label="Associado"
                          size="small"
                          color="default"
                          variant="outlined"
                        />
                      ) : (
                        <Typography variant="body2" color="text.disabled">
                          —
                        </Typography>
                      )}
                    </TableCell>
                    <TableCell align="center">
                      <Typography variant="body2" color="text.secondary">
                        {formatDate(patient.createdAt)}
                      </Typography>
                    </TableCell>
                    <TableCell align="center">
                      <Stack direction="row" spacing={0.5} justifyContent="center">
                        
                        <Tooltip title={patient.isActive ? 'Desativar' : 'Ativar'}>
                          <IconButton
                            size="small"
                            onClick={() => handleToggleStatus(patient)}
                            disabled={toggleStatus.isPending}
                          >
                            {patient.isActive ? (
                              <VisibilityOffIcon fontSize="small" />
                            ) : (
                              <VisibilityIcon fontSize="small" />
                            )}
                          </IconButton>
                        </Tooltip>
                        
                      </Stack>
                    </TableCell>
                  </TableRow>
                ))
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
      )}

      {/* Dialogs */}

      <ConfirmDialog
        open={confirmDialogOpen}
        onClose={handleCloseDialogs}
        onConfirm={() => {
          confirmDialogAction?.()
          setConfirmDialogOpen(false)
        }}
        title={confirmDialogTitle}
        message={confirmDialogMessage}
        loading={toggleStatus.isPending}
      />
    </Box>
  )
}