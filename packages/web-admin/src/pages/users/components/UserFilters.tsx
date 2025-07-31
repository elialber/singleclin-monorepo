import React, { useState } from 'react'
import {
  Box,
  Card,
  TextField,
  InputAdornment,
  IconButton,
  Tooltip,
  Stack,
  Chip,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Button,
  Collapse,
  Typography,
  Divider,
  Switch,
  FormControlLabel,
  Badge,
  useTheme,
  alpha,
} from '@mui/material'
import {
  Search,
  FilterList,
  Clear,
  ExpandMore,
  ExpandLess,
  Refresh,
  ViewList,
  ViewModule,
  Sort,
  Add,
} from '@mui/icons-material'
import { UserRole } from '@/types/user'

export interface UserFilters {
  search: string
  role: string
  isActive?: boolean
  isEmailVerified?: boolean
  clinicId?: string
  createdAfter?: string
  createdBefore?: string
}

interface UserFiltersProps {
  filters: UserFilters
  onFiltersChange: (filters: UserFilters) => void
  onRefresh: () => void
  onAddUser: () => void
  viewMode: 'table' | 'cards'
  onViewModeChange: (mode: 'table' | 'cards') => void
  sortBy: string
  sortOrder: 'asc' | 'desc'
  onSortChange: (sortBy: string, sortOrder: 'asc' | 'desc') => void
  totalCount: number
  loading?: boolean
  clinics?: Array<{ id: string; name: string }>
}

const roleOptions: Array<{ value: UserRole; label: string }> = [
  { value: 'Administrator', label: 'Administrador' },
  { value: 'ClinicOrigin', label: 'Clínica Origem' },
  { value: 'ClinicPartner', label: 'Clínica Parceira' },
  { value: 'Patient', label: 'Paciente' },
]

const sortOptions = [
  { value: 'fullName', label: 'Nome' },
  { value: 'email', label: 'Email' },
  { value: 'role', label: 'Perfil' },
  { value: 'createdAt', label: 'Data de Criação' },
  { value: 'isActive', label: 'Status' },
]

export default function UserFilters({
  filters,
  onFiltersChange,
  onRefresh,
  onAddUser,
  viewMode,
  onViewModeChange,
  sortBy,
  sortOrder,
  onSortChange,
  totalCount,
  loading,
  clinics = [],
}: UserFiltersProps) {
  const theme = useTheme()
  const [expandedFilters, setExpandedFilters] = useState(false)

  const handleFilterChange = (field: keyof UserFilters, value: any) => {
    onFiltersChange({ ...filters, [field]: value })
  }

  const clearFilters = () => {
    onFiltersChange({
      search: '',
      role: '',
      isActive: undefined,
      isEmailVerified: undefined,
      clinicId: undefined,
      createdAfter: undefined,
      createdBefore: undefined,
    })
  }

  const getActiveFiltersCount = () => {
    let count = 0
    if (filters.search) count++
    if (filters.role) count++
    if (filters.isActive !== undefined) count++
    if (filters.isEmailVerified !== undefined) count++
    if (filters.clinicId) count++
    if (filters.createdAfter) count++
    if (filters.createdBefore) count++
    return count
  }

  const activeFiltersCount = getActiveFiltersCount()

  return (
    <Card sx={{ mb: 3 }}>
      <Box sx={{ p: 3 }}>
        {/* Header Row */}
        <Stack
          direction={{ xs: 'column', md: 'row' }}
          spacing={2}
          alignItems={{ xs: 'stretch', md: 'center' }}
          mb={2}
        >
          {/* Search */}
          <TextField
            fullWidth
            placeholder="Buscar por nome, email ou telefone..."
            value={filters.search}
            onChange={(e) => handleFilterChange('search', e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <Search color="disabled" />
                </InputAdornment>
              ),
              endAdornment: filters.search && (
                <InputAdornment position="end">
                  <IconButton
                    size="small"
                    onClick={() => handleFilterChange('search', '')}
                  >
                    <Clear fontSize="small" />
                  </IconButton>
                </InputAdornment>
              ),
            }}
            sx={{
              '& .MuiOutlinedInput-root': {
                bgcolor: alpha(theme.palette.primary.main, 0.02),
              },
            }}
          />

          {/* Quick Filters */}
          <Stack direction="row" spacing={1} flexShrink={0}>
            <FormControl size="small" sx={{ minWidth: 120 }}>
              <InputLabel>Perfil</InputLabel>
              <Select
                value={filters.role || ''}
                label="Perfil"
                onChange={(e) => handleFilterChange('role', e.target.value)}
              >
                <MenuItem value="">Todos</MenuItem>
                {roleOptions.map((option) => (
                  <MenuItem key={option.value} value={option.value}>
                    {option.label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            <FormControl size="small" sx={{ minWidth: 100 }}>
              <InputLabel>Status</InputLabel>
              <Select
                value={filters.isActive === undefined ? '' : filters.isActive.toString()}
                label="Status"
                onChange={(e) =>
                  handleFilterChange(
                    'isActive',
                    e.target.value === '' ? undefined : e.target.value === 'true'
                  )
                }
              >
                <MenuItem value="">Todos</MenuItem>
                <MenuItem value="true">Ativos</MenuItem>
                <MenuItem value="false">Inativos</MenuItem>
              </Select>
            </FormControl>
          </Stack>
        </Stack>

        {/* Action Bar */}
        <Stack
          direction={{ xs: 'column', md: 'row' }}
          spacing={2}
          alignItems={{ xs: 'stretch', md: 'center' }}
          justifyContent="space-between"
        >
          {/* Left Actions */}
          <Stack direction="row" spacing={1} alignItems="center">
            <Badge badgeContent={activeFiltersCount} color="primary">
              <Button
                variant={expandedFilters ? 'contained' : 'outlined'}
                size="small"
                startIcon={expandedFilters ? <ExpandLess /> : <ExpandMore />}
                onClick={() => setExpandedFilters(!expandedFilters)}
                sx={{ minWidth: 'auto' }}
              >
                <FilterList />
              </Button>
            </Badge>

            {activeFiltersCount > 0 && (
              <Button
                variant="outlined"
                size="small"
                startIcon={<Clear />}
                onClick={clearFilters}
                color="secondary"
              >
                Limpar
              </Button>
            )}

            <Divider orientation="vertical" flexItem />

            <Typography variant="body2" color="textSecondary">
              {totalCount.toLocaleString()} usuários encontrados
            </Typography>
          </Stack>

          {/* Right Actions */}
          <Stack direction="row" spacing={1} alignItems="center">
            <FormControl size="small" sx={{ minWidth: 120 }}>
              <InputLabel>Ordenar por</InputLabel>
              <Select
                value={sortBy}
                label="Ordenar por"
                onChange={(e) => onSortChange(e.target.value, sortOrder)}
              >
                {sortOptions.map((option) => (
                  <MenuItem key={option.value} value={option.value}>
                    {option.label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            <Tooltip title={`Ordem ${sortOrder === 'asc' ? 'crescente' : 'decrescente'}`}>
              <IconButton
                size="small"
                onClick={() => onSortChange(sortBy, sortOrder === 'asc' ? 'desc' : 'asc')}
                sx={{
                  bgcolor: alpha(theme.palette.primary.main, 0.1),
                  '&:hover': { bgcolor: alpha(theme.palette.primary.main, 0.2) },
                }}
              >
                <Sort
                  sx={{
                    transform: sortOrder === 'desc' ? 'rotate(180deg)' : 'none',
                    transition: 'transform 0.3s ease',
                  }}
                />
              </IconButton>
            </Tooltip>

            <Divider orientation="vertical" flexItem />

            <Stack direction="row" spacing={0.5}>
              <Tooltip title="Visualização em tabela">
                <IconButton
                  size="small"
                  onClick={() => onViewModeChange('table')}
                  color={viewMode === 'table' ? 'primary' : 'default'}
                >
                  <ViewList />
                </IconButton>
              </Tooltip>
              <Tooltip title="Visualização em cards">
                <IconButton
                  size="small"
                  onClick={() => onViewModeChange('cards')}
                  color={viewMode === 'cards' ? 'primary' : 'default'}
                >
                  <ViewModule />
                </IconButton>
              </Tooltip>
            </Stack>

            <Tooltip title="Recarregar">
              <IconButton
                onClick={onRefresh}
                disabled={loading}
                sx={{
                  bgcolor: alpha(theme.palette.secondary.main, 0.1),
                  '&:hover': { bgcolor: alpha(theme.palette.secondary.main, 0.2) },
                }}
              >
                <Refresh />
              </IconButton>
            </Tooltip>

            <Button
              variant="contained"
              startIcon={<Add />}
              onClick={onAddUser}
              sx={{ minWidth: 'auto' }}
            >
              Novo
            </Button>
          </Stack>
        </Stack>

        {/* Active Filters Display */}
        {activeFiltersCount > 0 && (
          <Box mt={2}>
            <Stack direction="row" spacing={1} flexWrap="wrap">
              <Typography variant="body2" color="textSecondary" sx={{ alignSelf: 'center' }}>
                Filtros ativos:
              </Typography>
              {filters.search && (
                <Chip
                  label={`Busca: "${filters.search}"`}
                  size="small"
                  onDelete={() => handleFilterChange('search', '')}
                  color="primary"
                  variant="outlined"
                />
              )}
              {filters.role && (
                <Chip
                  label={`Perfil: ${roleOptions.find(r => r.value === filters.role)?.label}`}
                  size="small"
                  onDelete={() => handleFilterChange('role', '')}
                  color="primary"
                  variant="outlined"
                />
              )}
              {filters.isActive !== undefined && (
                <Chip
                  label={`Status: ${filters.isActive ? 'Ativo' : 'Inativo'}`}
                  size="small"
                  onDelete={() => handleFilterChange('isActive', undefined)}
                  color="primary"
                  variant="outlined"
                />
              )}
            </Stack>
          </Box>
        )}

        {/* Expanded Filters */}
        <Collapse in={expandedFilters}>
          <Box mt={3}>
            <Divider sx={{ mb: 3 }} />
            <Typography variant="h6" gutterBottom fontWeight={600}>
              Filtros Avançados
            </Typography>
            
            <Stack spacing={3}>
              <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
                <FormControl size="small" fullWidth>
                  <InputLabel>Email Verificado</InputLabel>
                  <Select
                    value={filters.isEmailVerified === undefined ? '' : filters.isEmailVerified.toString()}
                    label="Email Verificado"
                    onChange={(e) =>
                      handleFilterChange(
                        'isEmailVerified',
                        e.target.value === '' ? undefined : e.target.value === 'true'
                      )
                    }
                  >
                    <MenuItem value="">Todos</MenuItem>
                    <MenuItem value="true">Verificado</MenuItem>
                    <MenuItem value="false">Não Verificado</MenuItem>
                  </Select>
                </FormControl>

                {clinics.length > 0 && (
                  <FormControl size="small" fullWidth>
                    <InputLabel>Clínica</InputLabel>
                    <Select
                      value={filters.clinicId || ''}
                      label="Clínica"
                      onChange={(e) => handleFilterChange('clinicId', e.target.value)}
                    >
                      <MenuItem value="">Todas</MenuItem>
                      {clinics.map((clinic) => (
                        <MenuItem key={clinic.id} value={clinic.id}>
                          {clinic.name}
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                )}
              </Stack>

              <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
                <TextField
                  size="small"
                  fullWidth
                  label="Criado após"
                  type="date"
                  value={filters.createdAfter || ''}
                  onChange={(e) => handleFilterChange('createdAfter', e.target.value)}
                  InputLabelProps={{ shrink: true }}
                />
                <TextField
                  size="small"
                  fullWidth
                  label="Criado antes"
                  type="date"
                  value={filters.createdBefore || ''}
                  onChange={(e) => handleFilterChange('createdBefore', e.target.value)}
                  InputLabelProps={{ shrink: true }}
                />
              </Stack>
            </Stack>
          </Box>
        </Collapse>
      </Box>
    </Card>
  )
}