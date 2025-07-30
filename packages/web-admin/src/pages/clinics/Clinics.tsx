import { useState, useEffect, useCallback } from 'react'
import {
  Box,
  Typography,
  Paper,
  Card,
  CardContent,
  Grid,
  TextField,
  InputAdornment,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  CircularProgress,
  Pagination,
  Alert,
  Button,
} from '@mui/material'
import {
  Search as SearchIcon,
  LocationOn as LocationIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  LocalHospital as HospitalIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material'
import { Clinic, ClinicFilters } from '@/types/clinic'
import { clinicService } from '@/services/clinic.service'
import { useNotification } from "@/contexts/NotificationContext"

const CLINICS_PER_PAGE = 12

export default function Clinics() {
  const [clinics, setClinics] = useState<Clinic[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)
  const [totalPages, setTotalPages] = useState(0)
  
  // Filters
  const [filters, setFilters] = useState<ClinicFilters>({
    name: '',
    type: undefined,
    city: '',
    isActive: undefined,
  })
  const [filtersDebounce, setFiltersDebounce] = useState<ClinicFilters>(filters)

  const { showError } = useNotification()

  // Debounce filters
  useEffect(() => {
    const timer = setTimeout(() => {
      setFiltersDebounce(filters)
    }, 500)
    return () => clearTimeout(timer)
  }, [filters])

  // Load clinics when page or filters change
  useEffect(() => {
    loadClinics()
  }, [page, filtersDebounce, loadClinics])

  const loadClinics = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await clinicService.getClinics({
        page,
        limit: CLINICS_PER_PAGE,
        ...filtersDebounce,
        name: filtersDebounce.name || undefined,
        city: filtersDebounce.city || undefined,
      })
      setClinics(response.data)
      setTotal(response.total)
      setTotalPages(Math.ceil(response.total / CLINICS_PER_PAGE))
    } catch (err: unknown) {
      console.error('Error loading clinics:', err)
      setError('Erro ao carregar clínicas')
      showError('Erro ao carregar clínicas')
    } finally {
      setLoading(false)
    }
  }, [page, filtersDebounce, showError])

  const handlePageChange = (_: React.ChangeEvent<unknown>, newPage: number) => {
    setPage(newPage)
  }

  const handleFilterChange = (field: keyof ClinicFilters, value: string) => {
    setFilters(prev => ({ ...prev, [field]: value }))
    setPage(1) // Reset to first page when filters change
  }

  const clearFilters = () => {
    setFilters({
      name: '',
      type: undefined,
      city: '',
      isActive: undefined,
    })
    setPage(1)
  }

  const getTypeColor = (type: string) => {
    return type === 'Origin' ? 'primary' : 'secondary'
  }

  const getTypeLabel = (type: string) => {
    return type === 'Origin' ? 'Origem' : 'Parceira'
  }

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        <Typography variant="h4" fontWeight={600} gutterBottom>
          Clínicas
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Visualize e gerencie as clínicas parceiras
        </Typography>
      </Box>

      {/* Filters */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="h6" gutterBottom>
          Filtros
        </Typography>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} sm={6} md={3}>
            <TextField
              label="Nome da clínica"
              value={filters.name}
              onChange={(e) => handleFilterChange('name', e.target.value)}
              fullWidth
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon />
                  </InputAdornment>
                ),
              }}
            />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <FormControl fullWidth>
              <InputLabel>Tipo</InputLabel>
              <Select
                value={filters.type || ''}
                onChange={(e) => handleFilterChange('type', e.target.value || undefined)}
                label="Tipo"
              >
                <MenuItem value="">Todos</MenuItem>
                <MenuItem value="Origin">Origem</MenuItem>
                <MenuItem value="Partner">Parceira</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <TextField
              label="Cidade"
              value={filters.city}
              onChange={(e) => handleFilterChange('city', e.target.value)}
              fullWidth
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <LocationIcon />
                  </InputAdornment>
                ),
              }}
            />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <FormControl fullWidth>
              <InputLabel>Status</InputLabel>
              <Select
                value={filters.isActive === undefined ? '' : filters.isActive.toString()}
                onChange={(e) => {
                  const value = e.target.value
                  handleFilterChange('isActive', value === '' ? undefined : value === 'true')
                }}
                label="Status"
              >
                <MenuItem value="">Todos</MenuItem>
                <MenuItem value="true">Ativo</MenuItem>
                <MenuItem value="false">Inativo</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12}>
            <Box sx={{ display: 'flex', gap: 1 }}>
              <Button
                variant="outlined"
                startIcon={<RefreshIcon />}
                onClick={loadClinics}
                disabled={loading}
              >
                Atualizar
              </Button>
              <Button
                variant="text"
                onClick={clearFilters}
              >
                Limpar Filtros
              </Button>
            </Box>
          </Grid>
        </Grid>
      </Paper>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {/* Results info */}
      <Box sx={{ mb: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Typography variant="body2" color="text.secondary">
          {total > 0 ? `${total} clínica${total > 1 ? 's' : ''} encontrada${total > 1 ? 's' : ''}` : 'Nenhuma clínica encontrada'}
        </Typography>
        {totalPages > 1 && (
          <Typography variant="body2" color="text.secondary">
            Página {page} de {totalPages}
          </Typography>
        )}
      </Box>

      {/* Loading */}
      {loading && (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
          <CircularProgress />
        </Box>
      )}

      {/* Clinics Grid */}
      {!loading && (
        <Grid container spacing={3}>
          {clinics.map((clinic) => (
            <Grid item xs={12} sm={6} md={4} key={clinic.id}>
              <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
                <CardContent sx={{ flexGrow: 1 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                    <Box sx={{ flexGrow: 1 }}>
                      <Typography variant="h6" component="h3" gutterBottom>
                        {clinic.name}
                      </Typography>
                      <Box sx={{ display: 'flex', gap: 1, mb: 2 }}>
                        <Chip
                          label={getTypeLabel(clinic.type)}
                          color={getTypeColor(clinic.type) as 'default' | 'primary' | 'secondary' | 'error' | 'info' | 'success' | 'warning'}
                          size="small"
                        />
                        <Chip
                          label={clinic.isActive ? 'Ativo' : 'Inativo'}
                          color={clinic.isActive ? 'success' : 'default'}
                          size="small"
                        />
                      </Box>
                    </Box>
                    <HospitalIcon color="action" />
                  </Box>

                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                    <LocationIcon fontSize="small" color="action" sx={{ mr: 1 }} />
                    <Typography variant="body2" color="text.secondary">
                      {clinic.address}, {clinic.city} - {clinic.state}
                    </Typography>
                  </Box>

                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                    <EmailIcon fontSize="small" color="action" sx={{ mr: 1 }} />
                    <Typography variant="body2" color="text.secondary">
                      {clinic.email}
                    </Typography>
                  </Box>

                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                    <PhoneIcon fontSize="small" color="action" sx={{ mr: 1 }} />
                    <Typography variant="body2" color="text.secondary">
                      {clinic.phone}
                    </Typography>
                  </Box>

                  <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                    <strong>Registro:</strong> {clinic.registrationNumber}
                  </Typography>

                  <Typography variant="body2" color="text.secondary">
                    <strong>Médico Responsável:</strong> {clinic.responsibleDoctor}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}

      {/* Empty state */}
      {!loading && clinics.length === 0 && (
        <Box sx={{ textAlign: 'center', py: 8 }}>
          <HospitalIcon sx={{ fontSize: 80, color: 'text.disabled', mb: 2 }} />
          <Typography variant="h6" color="text.secondary" gutterBottom>
            Nenhuma clínica encontrada
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {Object.values(filters).some(v => v !== '' && v !== undefined)
              ? 'Tente ajustar os filtros para encontrar clínicas'
              : 'Não há clínicas cadastradas no sistema'
            }
          </Typography>
        </Box>
      )}

      {/* Pagination */}
      {totalPages > 1 && (
        <Box sx={{ display: 'flex', justifyContent: 'center', mt: 4 }}>
          <Pagination
            count={totalPages}
            page={page}
            onChange={handlePageChange}
            color="primary"
            size="large"
          />
        </Box>
      )}
    </Box>
  )
}