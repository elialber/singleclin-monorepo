import { useState, useCallback, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
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
  Avatar,
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
  LocationOn as LocationIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  ViewList as ViewListIcon,
  ViewModule as ViewModuleIcon,
} from '@mui/icons-material'
import { Clinic, ClinicImage, ClinicType, getClinicTypeLabel, getClinicTypeColor } from '@/types/clinic'
import { 
  useClinics, 
  useDeleteClinic, 
  useToggleClinicStatus, 
} from '@/hooks/useClinics'
import { ClinicQueryParams } from '@/services/clinic.service'
import ConfirmDialog from '@/components/ConfirmDialog'
import { useDebounce } from '@/hooks/useDebounce'
import { formatDate, formatPhone, formatCNPJ } from '@/utils/format'
import ImageCarousel, { ClinicImage as CarouselImage } from '@/components/clinic/ImageCarousel'

// Helper function to get clinic images for carousel
function getClinicImages(clinic: Clinic): CarouselImage[] {
  // Use the new images array from the clinic
  if (clinic.images && clinic.images.length > 0) {
    return clinic.images.map(image => ({
      url: image.imageUrl,
      altText: image.altText || `Imagem da clínica ${clinic.name}`,
      title: image.description || `${clinic.name} - Imagem`
    }))
  }
  
  // Fallback to deprecated imageUrl for backward compatibility
  if (clinic.imageUrl) {
    return [
      {
        url: clinic.imageUrl,
        altText: `Imagem principal da clínica ${clinic.name}`,
        title: `${clinic.name} - Imagem principal`
      }
    ]
  }
  
  return []
}

export default function Clinics() {
  const navigate = useNavigate()
  
  // State for filters and pagination
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)
  const [search, setSearch] = useState('')
  const [activeFilter, setActiveFilter] = useState<boolean | undefined>(undefined)
  const [typeFilter, setTypeFilter] = useState<ClinicType | undefined>(undefined)
  
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
  const [cityFilter, setCityFilter] = useState('')
  const [stateFilter, setStateFilter] = useState('')
  
  // Sorting
  const [sortBy, setSortBy] = useState<ClinicQueryParams['sortBy']>('createdat')
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('desc')
  
  // Debounce search to avoid excessive API calls
  const debouncedSearch = useDebounce(search, 500)
  const debouncedCityFilter = useDebounce(cityFilter, 500)
  const debouncedStateFilter = useDebounce(stateFilter, 500)
  
  // Dialog states (removed clinic dialog - now using stepper page)
  
  // Confirm dialog states
  const [confirmDialogOpen, setConfirmDialogOpen] = useState(false)
  const [confirmDialogTitle, setConfirmDialogTitle] = useState('')
  const [confirmDialogMessage, setConfirmDialogMessage] = useState('')
  const [confirmDialogAction, setConfirmDialogAction] = useState<(() => void) | null>(null)
  
  // Create query params
  const queryParams = useMemo<ClinicQueryParams>(() => ({
    pageNumber: page + 1,
    pageSize: rowsPerPage,
    searchTerm: debouncedSearch || undefined,
    isActive: activeFilter,
    type: typeFilter,
    city: debouncedCityFilter || undefined,
    state: debouncedStateFilter || undefined,
    sortBy,
    sortDirection
  }), [page, rowsPerPage, debouncedSearch, activeFilter, typeFilter, debouncedCityFilter, debouncedStateFilter, sortBy, sortDirection])
  
  // TanStack Query hooks
  const { data: clinicsResponse, isLoading, error, refetch } = useClinics(queryParams)
  const deleteClinic = useDeleteClinic()
  const toggleStatus = useToggleClinicStatus()

  // Extract data from response
  const clinics = clinicsResponse?.data ?? []
  const total = clinicsResponse?.totalCount ?? 0

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

  const handleTypeFilterChange = useCallback((value: string) => {
    setTypeFilter(value === 'all' ? undefined : parseInt(value) as ClinicType)
    setPage(0)
  }, [])

  const handleCityFilterChange = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    setCityFilter(event.target.value)
    setPage(0)
  }, [])

  const handleStateFilterChange = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    setStateFilter(event.target.value)
    setPage(0)
  }, [])

  const handleSort = useCallback((field: ClinicQueryParams['sortBy']) => {
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
    setTypeFilter(undefined)
    setCityFilter('')
    setStateFilter('')
    setSortBy('createdat')
    setSortDirection('desc')
    setPage(0)
  }, [])

  const handleRefresh = useCallback(() => {
    refetch()
  }, [refetch])

  const handleCreateClinic = useCallback(() => {
    navigate('/clinics/new')
  }, [navigate])

  const handleEditClinic = useCallback((clinic: Clinic) => {
    navigate(`/clinics/${clinic.id}/edit`)
  }, [navigate])

  const handleDeleteClinic = useCallback((clinic: Clinic) => {
    setConfirmDialogTitle('Confirmar exclusão')
    setConfirmDialogMessage(`Tem certeza que deseja excluir a clínica "${clinic.name}"? Esta ação não pode ser desfeita.`)
    setConfirmDialogAction(() => () => deleteClinic.mutate(clinic.id))
    setConfirmDialogOpen(true)
  }, [deleteClinic])

  const handleToggleStatus = useCallback((clinic: Clinic) => {
    const action = clinic.isActive ? 'desativar' : 'ativar'
    setConfirmDialogTitle(`Confirmar ${action}`)
    setConfirmDialogMessage(`Tem certeza que deseja ${action} a clínica "${clinic.name}"?`)
    setConfirmDialogAction(() => () => toggleStatus.mutate(clinic.id))
    setConfirmDialogOpen(true)
  }, [toggleStatus])

  const handleCloseDialogs = useCallback(() => {
    setConfirmDialogOpen(false)
    setConfirmDialogAction(null)
  }, [])

  // Loading state
  if (isLoading && clinics.length === 0) {
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
            Clínicas
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Gerencie as clínicas parceiras do sistema
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleCreateClinic}
          size="large"
          disabled={error?.message?.includes('403') || error?.message?.includes('Forbidden')}
        >
          Nova Clínica
        </Button>
      </Box>

      {/* Filters */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems="center" mb={2}>
          <TextField
            placeholder="Buscar clínicas..."
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
            <InputLabel>Tipo</InputLabel>
            <Select
              value={typeFilter === undefined ? 'all' : typeFilter.toString()}
              onChange={(e) => handleTypeFilterChange(e.target.value)}
              label="Tipo"
              size="small"
            >
              <MenuItem value="all">Todos</MenuItem>
              <MenuItem value={ClinicType.Regular.toString()}>Regular</MenuItem>
              <MenuItem value={ClinicType.Origin.toString()}>Origem</MenuItem>
              <MenuItem value={ClinicType.Partner.toString()}>Parceira</MenuItem>
              <MenuItem value={ClinicType.Administrative.toString()}>Administrativa</MenuItem>
            </Select>
          </FormControl>

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
              disabled={!search && activeFilter === undefined && typeFilter === undefined && !cityFilter && !stateFilter}
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
            <TextField
              placeholder="Filtrar por cidade..."
              value={cityFilter}
              onChange={handleCityFilterChange}
              size="small"
              sx={{ minWidth: 200 }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <LocationIcon />
                  </InputAdornment>
                ),
              }}
            />

            <TextField
              placeholder="Filtrar por estado..."
              value={stateFilter}
              onChange={handleStateFilterChange}
              size="small"
              sx={{ minWidth: 150 }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <LocationIcon />
                  </InputAdornment>
                ),
              }}
            />
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
              <strong>Acesso negado:</strong> Você não tem permissão para gerenciar clínicas. 
              Entre em contato com um administrador para obter acesso.
            </>
          ) : (
            <>
              Erro ao carregar clínicas: {error.message}
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
          {isLoading && clinics.length === 0 ? (
            <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
              <CircularProgress size={40} />
              <Typography variant="body2" sx={{ ml: 2 }}>
                Carregando clínicas...
              </Typography>
            </Box>
          ) : clinics.length === 0 ? (
            <Paper sx={{ p: 4, textAlign: 'center' }}>
              <Typography variant="body2" color="text.secondary">
                {debouncedSearch 
                  ? `Nenhuma clínica encontrada para "${debouncedSearch}"`
                  : 'Nenhuma clínica cadastrada'
                }
              </Typography>
            </Paper>
          ) : (
            <Grid container spacing={3}>
              {clinics.map((clinic) => (
                <Grid item xs={12} sm={6} md={4} lg={3} key={clinic.id}>
                  <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
                    <CardContent sx={{ flex: 1 }}>
                      {/* Clinic Image Carousel */}
                      <Box sx={{ mb: 2 }}>
                        <ImageCarousel
                          images={getClinicImages(clinic)}
                          clinicName={clinic.name}
                          height={160}
                          width="100%"
                          borderRadius={8}
                          showControls={true}
                          allowFullscreen={true}
                          fallbackMessage="Sem imagem"
                        />
                      </Box>

                      {/* Clinic Header */}
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 1 }}>
                        <Typography variant="h6" fontWeight={600} noWrap sx={{ flex: 1, mr: 1 }}>
                          {clinic.name}
                        </Typography>
                        <Chip
                          label={clinic.isActive ? 'Ativo' : 'Inativo'}
                          size="small"
                          color={clinic.isActive ? 'success' : 'default'}
                          variant={clinic.isActive ? 'filled' : 'outlined'}
                        />
                      </Box>

                      <Chip
                        label={getClinicTypeLabel(clinic.type)}
                        size="small"
                        color={getClinicTypeColor(clinic.type)}
                        variant="filled"
                        sx={{ mb: 2 }}
                      />

                      <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                        {clinic.address}
                      </Typography>

                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                        {clinic.phoneNumber && (
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <PhoneIcon fontSize="small" color="action" />
                            <Typography variant="body2" color="text.secondary">
                              {formatPhone(clinic.phoneNumber)}
                            </Typography>
                          </Box>
                        )}
                        {clinic.email && (
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <EmailIcon fontSize="small" color="action" />
                            <Typography variant="body2" color="text.secondary" noWrap>
                              {clinic.email}
                            </Typography>
                          </Box>
                        )}
                        {clinic.cnpj && (
                          <Typography variant="body2" color="text.secondary">
                            CNPJ: {formatCNPJ(clinic.cnpj)}
                          </Typography>
                        )}
                      </Box>

                      <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 2 }}>
                        Criado em {formatDate(clinic.createdAt)}
                      </Typography>
                    </CardContent>

                    <CardActions sx={{ p: 2, pt: 0, justifyContent: 'flex-end' }}>
                      <Tooltip title="Editar">
                        <IconButton
                          size="small"
                          onClick={() => handleEditClinic(clinic)}
                        >
                          <EditIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                      
                      <Tooltip title={clinic.isActive ? 'Desativar' : 'Ativar'}>
                        <IconButton
                          size="small"
                          onClick={() => handleToggleStatus(clinic)}
                          disabled={toggleStatus.isPending}
                        >
                          {clinic.isActive ? (
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
                          onClick={() => handleDeleteClinic(clinic)}
                          disabled={deleteClinic.isPending}
                        >
                          <DeleteIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                    </CardActions>
                  </Card>
                </Grid>
              ))}
            </Grid>
          )}

          {/* Pagination for Cards */}
          {clinics.length > 0 && (
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
                <TableCell width="120">Imagens</TableCell>
                <TableCell>
                  <TableSortLabel
                    active={sortBy === 'name'}
                    direction={sortBy === 'name' ? sortDirection : 'asc'}
                    onClick={() => handleSort('name')}
                  >
                    Nome
                  </TableSortLabel>
                </TableCell>
                <TableCell>
                  <TableSortLabel
                    active={sortBy === 'type'}
                    direction={sortBy === 'type' ? sortDirection : 'asc'}
                    onClick={() => handleSort('type')}
                  >
                    Tipo
                  </TableSortLabel>
                </TableCell>
                <TableCell>
                  <TableSortLabel
                    active={sortBy === 'address'}
                    direction={sortBy === 'address' ? sortDirection : 'asc'}
                    onClick={() => handleSort('address')}
                  >
                    Endereço
                  </TableSortLabel>
                </TableCell>
                <TableCell>Contato</TableCell>
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
                <TableCell align="center" width="140">Ações</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {isLoading && clinics.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={8} align="center" sx={{ py: 4 }}>
                    <CircularProgress size={32} />
                    <Typography variant="body2" sx={{ mt: 1 }}>
                      Carregando clínicas...
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : clinics.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={8} align="center" sx={{ py: 4 }}>
                    <Typography variant="body2" color="text.secondary">
                      {debouncedSearch 
                        ? `Nenhuma clínica encontrada para "${debouncedSearch}"`
                        : 'Nenhuma clínica cadastrada'
                      }
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                clinics.map((clinic) => (
                  <TableRow key={clinic.id} hover>
                    <TableCell>
                      <ImageCarousel
                        images={getClinicImages(clinic)}
                        clinicName={clinic.name}
                        height={60}
                        width={80}
                        borderRadius={4}
                        showControls={getClinicImages(clinic).length > 1}
                        allowFullscreen={true}
                        fallbackMessage="Sem imagem"
                      />
                    </TableCell>
                    <TableCell>
                      <Typography variant="subtitle2" fontWeight={500}>
                        {clinic.name}
                      </Typography>
                      {clinic.cnpj && (
                        <Typography variant="body2" color="text.secondary">
                          CNPJ: {formatCNPJ(clinic.cnpj)}
                        </Typography>
                      )}
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={getClinicTypeLabel(clinic.type)}
                        size="small"
                        color={getClinicTypeColor(clinic.type)}
                        variant="filled"
                      />
                    </TableCell>
                    <TableCell>
                      <Typography 
                        variant="body2" 
                        sx={{ 
                          maxWidth: 200,
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                          whiteSpace: 'nowrap'
                        }}
                        title={clinic.address}
                      >
                        {clinic.address}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5 }}>
                        {clinic.phoneNumber && (
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                            <PhoneIcon fontSize="small" color="action" />
                            <Typography variant="body2" color="text.secondary">
                              {formatPhone(clinic.phoneNumber)}
                            </Typography>
                          </Box>
                        )}
                        {clinic.email && (
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                            <EmailIcon fontSize="small" color="action" />
                            <Typography variant="body2" color="text.secondary">
                              {clinic.email}
                            </Typography>
                          </Box>
                        )}
                      </Box>
                    </TableCell>
                    <TableCell align="center">
                      <Chip
                        label={clinic.isActive ? 'Ativo' : 'Inativo'}
                        size="small"
                        color={clinic.isActive ? 'success' : 'default'}
                        variant={clinic.isActive ? 'filled' : 'outlined'}
                      />
                    </TableCell>
                    <TableCell align="center">
                      <Typography variant="body2" color="text.secondary">
                        {formatDate(clinic.createdAt)}
                      </Typography>
                    </TableCell>
                    <TableCell align="center">
                      <Stack direction="row" spacing={0.5} justifyContent="center">
                        <Tooltip title="Editar">
                          <IconButton
                            size="small"
                            onClick={() => handleEditClinic(clinic)}
                          >
                            <EditIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                        
                        <Tooltip title={clinic.isActive ? 'Desativar' : 'Ativar'}>
                          <IconButton
                            size="small"
                            onClick={() => handleToggleStatus(clinic)}
                            disabled={toggleStatus.isPending}
                          >
                            {clinic.isActive ? (
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
                            onClick={() => handleDeleteClinic(clinic)}
                            disabled={deleteClinic.isPending}
                          >
                            <DeleteIcon fontSize="small" />
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
        loading={deleteClinic.isPending || toggleStatus.isPending}
      />
    </Box>
  )
}