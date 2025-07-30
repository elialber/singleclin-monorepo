import { useState, useEffect } from 'react'
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  IconButton,
  Tooltip,
  Avatar,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  ListItemSecondaryAction,
  Pagination,
  CircularProgress,
  Alert,
  Skeleton,
  Divider,
} from '@mui/material'
import {
  Search as SearchIcon,
  FilterList as FilterListIcon,
  Clear as ClearIcon,
  Visibility as VisibilityIcon,
  Person as PersonIcon,
  Email as EmailIcon,
  Phone as PhoneIcon,
  CalendarToday as CalendarTodayIcon,
  CreditCard as CreditCardIcon,
  Close as CloseIcon,
} from '@mui/icons-material'
// Removed date-fns imports due to compatibility issues
import { Patient, PatientFilters, PatientDetails } from '@/types/patient'
import { patientService } from '@/services/patient.service'
import { useNotification } from '@/contexts/NotificationContext'
import { useDebounce } from '@/hooks/useDebounce'

export default function Patients() {
  const [patients, setPatients] = useState<Patient[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  
  // Pagination
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(0)
  const [total, setTotal] = useState(0)
  const itemsPerPage = 20
  
  // Filters
  const [filters, setFilters] = useState<PatientFilters>({})
  const [tempFilters, setTempFilters] = useState<PatientFilters>({})
  const [showFilters, setShowFilters] = useState(false)
  const [search, setSearch] = useState('')
  
  // Patient details modal
  const [selectedPatient, setSelectedPatient] = useState<PatientDetails | null>(null)
  const [detailsOpen, setDetailsOpen] = useState(false)
  const [loadingDetails, setLoadingDetails] = useState(false)
  
  const { showError } = useNotification()
  
  // Debounce search to reduce API calls
  const debouncedSearch = useDebounce(search, 500)
  const debouncedFilters = useDebounce(filters, 300)

  useEffect(() => {
    loadPatients()
  }, [debouncedSearch, debouncedFilters, page])

  const loadPatients = async () => {
    try {
      setLoading(true)
      setError(null)
      
      const response = await patientService.getPatients({
        ...debouncedFilters,
        search: debouncedSearch || undefined,
        page,
        limit: itemsPerPage,
      })
      
      setPatients(response.data)
      setTotal(response.total)
      setTotalPages(Math.ceil(response.total / itemsPerPage))
    } catch (err: any) {
      console.error('Error loading patients:', err)
      setError('Erro ao carregar pacientes')
      showError('Erro ao carregar pacientes')
    } finally {
      setLoading(false)
    }
  }

  const loadPatientDetails = async (patientId: string) => {
    try {
      setLoadingDetails(true)
      const details = await patientService.getPatientDetails(patientId)
      setSelectedPatient(details)
    } catch (err: any) {
      console.error('Error loading patient details:', err)
      showError('Erro ao carregar detalhes do paciente')
    } finally {
      setLoadingDetails(false)
    }
  }

  const handleFilterChange = (field: keyof PatientFilters, value: any) => {
    setTempFilters(prev => ({
      ...prev,
      [field]: value === '' ? undefined : value,
    }))
  }

  const applyFilters = () => {
    setFilters(tempFilters)
    setPage(1) // Reset to first page
    setShowFilters(false)
  }

  const clearFilters = () => {
    const emptyFilters = {}
    setTempFilters(emptyFilters)
    setFilters(emptyFilters)
    setSearch('')
    setPage(1)
    setShowFilters(false)
  }

  const handleViewDetails = async (patient: Patient) => {
    setDetailsOpen(true)
    setSelectedPatient(null)
    await loadPatientDetails(patient.id)
  }

  const formatDateString = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('pt-BR')
  }

  const getInitials = (name: string) => {
    return name
      .split(' ')
      .map(n => n[0])
      .join('')
      .toUpperCase()
      .slice(0, 2)
  }

  const activeFiltersCount = Object.values(filters).filter(value => 
    value !== undefined && value !== ''
  ).length + (search ? 1 : 0)

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Box>
          <Typography variant="h4" fontWeight={600} gutterBottom>
            Pacientes
          </Typography>
          <Typography variant="body1" color="text.secondary">
            {total > 0 && `${total} pacientes encontrados`}
          </Typography>
        </Box>
        
        <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
          <TextField
            placeholder="Buscar pacientes..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            size="small"
            sx={{ minWidth: 250 }}
            InputProps={{
              startAdornment: <SearchIcon sx={{ color: 'text.secondary', mr: 1 }} />,
              endAdornment: search && (
                <IconButton size="small" onClick={() => setSearch('')}>
                  <ClearIcon />
                </IconButton>
              ),
            }}
          />
          
          <Button
            variant="outlined"
            startIcon={<FilterListIcon />}
            onClick={() => setShowFilters(true)}
            color={activeFiltersCount > 0 ? 'primary' : 'inherit'}
          >
            Filtros
            {activeFiltersCount > 0 && (
              <Chip 
                label={activeFiltersCount} 
                size="small" 
                sx={{ ml: 1, height: 20 }}
              />
            )}
          </Button>
        </Box>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {/* Patients List */}
      <Card>
        <CardContent sx={{ p: 0 }}>
          {loading ? (
            // Loading skeleton
            <List>
              {Array.from({ length: 10 }).map((_, index) => (
                <ListItem key={index}>
                  <ListItemAvatar>
                    <Skeleton variant="circular" width={40} height={40} />
                  </ListItemAvatar>
                  <ListItemText
                    primary={<Skeleton variant="text" width="40%" />}
                    secondary={<Skeleton variant="text" width="60%" />}
                  />
                  <ListItemSecondaryAction>
                    <Skeleton variant="rectangular" width={80} height={32} />
                  </ListItemSecondaryAction>
                </ListItem>
              ))}
            </List>
          ) : patients.length === 0 ? (
            <Box sx={{ py: 8, textAlign: 'center' }}>
              <PersonIcon sx={{ fontSize: 48, color: 'text.secondary', mb: 2 }} />
              <Typography variant="h6" color="text.secondary">
                Nenhum paciente encontrado
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {activeFiltersCount > 0 
                  ? 'Tente ajustar os filtros ou termo de busca'
                  : 'Os pacientes aparecerão aqui quando se cadastrarem'
                }
              </Typography>
            </Box>
          ) : (
            <List>
              {patients.map((patient, index) => (
                <div key={patient.id}>
                  <ListItem>
                    <ListItemAvatar>
                      <Avatar sx={{ bgcolor: 'primary.main' }}>
                        {getInitials(patient.fullName)}
                      </Avatar>
                    </ListItemAvatar>
                    <ListItemText
                      primary={
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Typography variant="body1" fontWeight={500}>
                            {patient.fullName}
                          </Typography>
                          <Chip
                            label={patient.isActive ? 'Ativo' : 'Inativo'}
                            color={patient.isActive ? 'success' : 'default'}
                            size="small"
                          />
                          {patient.hasPlan && (
                            <Chip
                              label="Com plano"
                              color="info"
                              size="small"
                              variant="outlined"
                            />
                          )}
                        </Box>
                      }
                      secondary={
                        <Box>
                          <Typography variant="body2" color="text.secondary">
                            {patient.email}
                          </Typography>
                          {patient.phone && (
                            <Typography variant="body2" color="text.secondary">
                              {patient.phone}
                            </Typography>
                          )}
                          <Typography variant="caption" color="text.secondary">
                            Cadastrado em {formatDateString(patient.createdAt)}
                          </Typography>
                        </Box>
                      }
                    />
                    <ListItemSecondaryAction>
                      <Tooltip title="Ver detalhes">
                        <Button
                          variant="outlined"
                          size="small"
                          startIcon={<VisibilityIcon />}
                          onClick={() => handleViewDetails(patient)}
                        >
                          Detalhes
                        </Button>
                      </Tooltip>
                    </ListItemSecondaryAction>
                  </ListItem>
                  {index < patients.length - 1 && <Divider />}
                </div>
              ))}
            </List>
          )}
          
          {/* Pagination */}
          {totalPages > 1 && (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 3 }}>
              <Pagination
                count={totalPages}
                page={page}
                onChange={(_, newPage) => setPage(newPage)}
                color="primary"
                showFirstButton
                showLastButton
              />
            </Box>
          )}
        </CardContent>
      </Card>

      {/* Filters Dialog */}
      <Dialog 
        open={showFilters} 
        onClose={() => setShowFilters(false)} 
        maxWidth="sm" 
        fullWidth
      >
        <DialogTitle>
          Filtrar Pacientes
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={3} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Status</InputLabel>
                <Select
                  value={tempFilters.isActive !== undefined ? tempFilters.isActive.toString() : ''}
                  onChange={(e) => handleFilterChange('isActive', e.target.value === '' ? undefined : e.target.value === 'true')}
                  label="Status"
                >
                  <MenuItem value="">Todos</MenuItem>
                  <MenuItem value="true">Ativo</MenuItem>
                  <MenuItem value="false">Inativo</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Possui Plano</InputLabel>
                <Select
                  value={tempFilters.hasPlan !== undefined ? tempFilters.hasPlan.toString() : ''}
                  onChange={(e) => handleFilterChange('hasPlan', e.target.value === '' ? undefined : e.target.value === 'true')}
                  label="Possui Plano"
                >
                  <MenuItem value="">Todos</MenuItem>
                  <MenuItem value="true">Com plano</MenuItem>
                  <MenuItem value="false">Sem plano</MenuItem>
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        </DialogContent>
        <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 1, p: 2 }}>
          <Button onClick={() => setShowFilters(false)}>
            Cancelar
          </Button>
          <Button onClick={clearFilters} startIcon={<ClearIcon />}>
            Limpar
          </Button>
          <Button onClick={applyFilters} variant="contained">
            Aplicar Filtros
          </Button>
        </Box>
      </Dialog>

      {/* Patient Details Dialog */}
      <Dialog
        open={detailsOpen}
        onClose={() => setDetailsOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          Detalhes do Paciente
          <IconButton onClick={() => setDetailsOpen(false)}>
            <CloseIcon />
          </IconButton>
        </DialogTitle>
        <DialogContent>
          {loadingDetails ? (
            <Box sx={{ py: 4 }}>
              <CircularProgress sx={{ display: 'block', mx: 'auto' }} />
            </Box>
          ) : selectedPatient ? (
            <Grid container spacing={3} sx={{ mt: 1 }}>
              {/* Basic Info */}
              <Grid item xs={12}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                  <Avatar sx={{ bgcolor: 'primary.main', width: 64, height: 64 }}>
                    {getInitials(selectedPatient.fullName)}
                  </Avatar>
                  <Box>
                    <Typography variant="h5" fontWeight={600}>
                      {selectedPatient.fullName}
                    </Typography>
                    <Box sx={{ display: 'flex', gap: 1, mt: 1 }}>
                      <Chip
                        label={selectedPatient.isActive ? 'Ativo' : 'Inativo'}
                        color={selectedPatient.isActive ? 'success' : 'default'}
                        size="small"
                      />
                      <Chip
                        label={selectedPatient.hasPlan ? 'Com plano' : 'Sem plano'}
                        color={selectedPatient.hasPlan ? 'info' : 'default'}
                        size="small"
                        variant="outlined"
                      />
                    </Box>
                  </Box>
                </Box>
              </Grid>

              {/* Contact Info */}
              <Grid item xs={12} md={6}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                  <EmailIcon color="primary" />
                  <Box>
                    <Typography variant="subtitle2" color="text.secondary">
                      Email
                    </Typography>
                    <Typography variant="body1">
                      {selectedPatient.email}
                    </Typography>
                  </Box>
                </Box>
              </Grid>

              {selectedPatient.phone && (
                <Grid item xs={12} md={6}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                    <PhoneIcon color="primary" />
                    <Box>
                      <Typography variant="subtitle2" color="text.secondary">
                        Telefone
                      </Typography>
                      <Typography variant="body1">
                        {selectedPatient.phone}
                      </Typography>
                    </Box>
                  </Box>
                </Grid>
              )}

              <Grid item xs={12} md={6}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                  <CalendarTodayIcon color="primary" />
                  <Box>
                    <Typography variant="subtitle2" color="text.secondary">
                      Data de Cadastro
                    </Typography>
                    <Typography variant="body1">
                      {formatDateString(selectedPatient.createdAt)}
                    </Typography>
                  </Box>
                </Box>
              </Grid>

              {/* Plans Info */}
              {selectedPatient.plans && selectedPatient.plans.length > 0 && (
                <Grid item xs={12}>
                  <Typography variant="h6" sx={{ mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
                    <CreditCardIcon color="primary" />
                    Planos Ativos
                  </Typography>
                  <Grid container spacing={2}>
                    {selectedPatient.plans.map((userPlan) => (
                      <Grid item xs={12} md={6} key={userPlan.id}>
                        <Card variant="outlined">
                          <CardContent>
                            <Typography variant="subtitle1" fontWeight={600}>
                              {userPlan.planName}
                            </Typography>
                            <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                              {userPlan.planDescription}
                            </Typography>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                              <Typography variant="body2">
                                Créditos restantes: <strong>{userPlan.remainingCredits}</strong>
                              </Typography>
                              <Chip
                                label={userPlan.isActive ? 'Ativo' : 'Inativo'}
                                color={userPlan.isActive ? 'success' : 'default'}
                                size="small"
                              />
                            </Box>
                            <Typography variant="caption" color="text.secondary">
                              Adquirido em {formatDateString(userPlan.purchaseDate)}
                            </Typography>
                          </CardContent>
                        </Card>
                      </Grid>
                    ))}
                  </Grid>
                </Grid>
              )}

              {/* Recent Transactions */}
              {selectedPatient.recentTransactions && selectedPatient.recentTransactions.length > 0 && (
                <Grid item xs={12}>
                  <Typography variant="h6" sx={{ mb: 2 }}>
                    Transações Recentes
                  </Typography>
                  <List>
                    {selectedPatient.recentTransactions.map((transaction, index) => (
                      <div key={transaction.id}>
                        <ListItem>
                          <ListItemText
                            primary={
                              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                <Typography variant="body1">
                                  {transaction.clinicName} • {transaction.planName}
                                </Typography>
                                <Chip
                                  label={transaction.status === 'Validated' ? 'Validada' : 
                                         transaction.status === 'Pending' ? 'Pendente' : 'Cancelada'}
                                  color={transaction.status === 'Validated' ? 'success' : 
                                         transaction.status === 'Pending' ? 'warning' : 'error'}
                                  size="small"
                                />
                              </Box>
                            }
                            secondary={
                              <Box>
                                <Typography variant="body2" color="text.secondary">
                                  {transaction.creditsUsed} créditos • {formatDateString(transaction.transactionDate)}
                                </Typography>
                              </Box>
                            }
                          />
                        </ListItem>
                        {index < selectedPatient.recentTransactions!.length - 1 && <Divider />}
                      </div>
                    ))}
                  </List>
                </Grid>
              )}
            </Grid>
          ) : (
            <Typography>Erro ao carregar detalhes do paciente</Typography>
          )}
        </DialogContent>
      </Dialog>
    </Box>
  )
}