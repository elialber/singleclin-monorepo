import { useState, useEffect } from 'react'
import {
  Box,
  Card,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  TextField,
  InputAdornment,
  IconButton,
  Chip,
  Button,
  Tooltip,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Typography,
  Stack,
  Skeleton,
  Alert,
} from '@mui/material'
import {
  Search,
  Add,
  Edit,
  Delete,
  FilterList,
  Refresh,
  PersonOff,
  Person,
  Lock,
} from '@mui/icons-material'
import { useNotification } from '@/hooks/useNotification'
import { userService, UserFilters } from '@/services/user.service'
import { User, UserRole } from '@/types/user'
import { useDebounce } from '@/hooks/useDebounce'
import UserDialog from './UserDialog'
import ConfirmDialog from '@/components/ConfirmDialog'

const roleLabels: Record<UserRole, string> = {
  Administrator: 'Administrador',
  ClinicOrigin: 'Clínica Origem',
  ClinicPartner: 'Clínica Parceira',
  Patient: 'Paciente',
}

const roleColors: Record<UserRole, 'error' | 'warning' | 'info' | 'success'> = {
  Administrator: 'error',
  ClinicOrigin: 'warning',
  ClinicPartner: 'info',
  Patient: 'success',
}

export default function Users() {
  const { showNotification } = useNotification()
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)
  const [totalCount, setTotalCount] = useState(0)
  const [filters, setFilters] = useState<UserFilters>({
    search: '',
    role: '',
    isActive: undefined,
  })
  const [dialogOpen, setDialogOpen] = useState(false)
  const [selectedUser, setSelectedUser] = useState<User | null>(null)
  const [confirmDialog, setConfirmDialog] = useState<{
    open: boolean
    title: string
    message: string
    onConfirm: () => void
  }>({ open: false, title: '', message: '', onConfirm: () => {} })

  const debouncedSearch = useDebounce(filters.search, 500)

  useEffect(() => {
    loadUsers()
  }, [page, rowsPerPage, debouncedSearch, filters.role, filters.isActive])

  const loadUsers = async () => {
    try {
      setLoading(true)
      const response = await userService.getUsers({
        page: page + 1,
        limit: rowsPerPage,
        search: debouncedSearch,
        role: filters.role || undefined,
        isActive: filters.isActive,
      })
      setUsers(response.data)
      setTotalCount(response.total)
    } catch (error) {
      showNotification('Erro ao carregar usuários', 'error')
      console.error(error)
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

  const handleFilterChange = (field: keyof UserFilters, value: any) => {
    setFilters(prev => ({ ...prev, [field]: value }))
    setPage(0)
  }

  const handleAddUser = () => {
    setSelectedUser(null)
    setDialogOpen(true)
  }

  const handleEditUser = (user: User) => {
    setSelectedUser(user)
    setDialogOpen(true)
  }

  const handleDeleteUser = (user: User) => {
    setConfirmDialog({
      open: true,
      title: 'Excluir usuário',
      message: `Tem certeza que deseja excluir o usuário "${user.fullName}"?`,
      onConfirm: async () => {
        try {
          await userService.deleteUser(user.id)
          showNotification('Usuário excluído com sucesso', 'success')
          loadUsers()
        } catch (error) {
          showNotification('Erro ao excluir usuário', 'error')
        }
      },
    })
  }

  const handleToggleStatus = async (user: User) => {
    try {
      await userService.toggleUserStatus(user.id, !user.isActive)
      showNotification(
        `Usuário ${!user.isActive ? 'ativado' : 'desativado'} com sucesso`,
        'success'
      )
      loadUsers()
    } catch (error) {
      showNotification('Erro ao alterar status do usuário', 'error')
    }
  }

  const handleResetPassword = (user: User) => {
    setConfirmDialog({
      open: true,
      title: 'Resetar senha',
      message: `Tem certeza que deseja resetar a senha do usuário "${user.fullName}"?`,
      onConfirm: async () => {
        try {
          await userService.resetPassword(user.id)
          showNotification('Email de reset de senha enviado com sucesso', 'success')
        } catch (error) {
          showNotification('Erro ao resetar senha', 'error')
        }
      },
    })
  }

  const handleDialogClose = (shouldReload?: boolean) => {
    setDialogOpen(false)
    setSelectedUser(null)
    if (shouldReload) {
      loadUsers()
    }
  }

  const clearFilters = () => {
    setFilters({
      search: '',
      role: '',
      isActive: undefined,
    })
    setPage(0)
  }

  const hasActiveFilters = filters.search || filters.role || filters.isActive !== undefined

  return (
    <Box>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" component="h1">
          Usuários
        </Typography>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={handleAddUser}
        >
          Novo Usuário
        </Button>
      </Stack>

      <Card>
        <Box p={2}>
          <Stack spacing={2}>
            <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
              <TextField
                fullWidth
                placeholder="Buscar por nome, email ou telefone..."
                value={filters.search}
                onChange={(e) => handleFilterChange('search', e.target.value)}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <Search />
                    </InputAdornment>
                  ),
                }}
              />
              <FormControl sx={{ minWidth: 200 }}>
                <InputLabel>Perfil</InputLabel>
                <Select
                  value={filters.role || ''}
                  label="Perfil"
                  onChange={(e) => handleFilterChange('role', e.target.value)}
                >
                  <MenuItem value="">Todos</MenuItem>
                  {Object.entries(roleLabels).map(([value, label]) => (
                    <MenuItem key={value} value={value}>
                      {label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
              <FormControl sx={{ minWidth: 150 }}>
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
              {hasActiveFilters && (
                <Button
                  variant="outlined"
                  onClick={clearFilters}
                  startIcon={<FilterList />}
                >
                  Limpar
                </Button>
              )}
              <IconButton onClick={loadUsers} title="Recarregar">
                <Refresh />
              </IconButton>
            </Stack>
          </Stack>
        </Box>

        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Nome</TableCell>
                <TableCell>Email</TableCell>
                <TableCell>Perfil</TableCell>
                <TableCell>Telefone</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Criado em</TableCell>
                <TableCell align="right">Ações</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                Array.from(new Array(5)).map((_, index) => (
                  <TableRow key={index}>
                    <TableCell><Skeleton /></TableCell>
                    <TableCell><Skeleton /></TableCell>
                    <TableCell><Skeleton /></TableCell>
                    <TableCell><Skeleton /></TableCell>
                    <TableCell><Skeleton /></TableCell>
                    <TableCell><Skeleton /></TableCell>
                    <TableCell><Skeleton /></TableCell>
                  </TableRow>
                ))
              ) : users.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={7} align="center">
                    <Alert severity="info" sx={{ justifyContent: 'center' }}>
                      Nenhum usuário encontrado
                    </Alert>
                  </TableCell>
                </TableRow>
              ) : (
                users.map((user) => (
                  <TableRow key={user.id} hover>
                    <TableCell>
                      <Stack direction="row" spacing={1} alignItems="center">
                        <Typography variant="body2">{user.fullName}</Typography>
                        {!user.isEmailVerified && (
                          <Chip label="Email não verificado" size="small" color="warning" />
                        )}
                      </Stack>
                    </TableCell>
                    <TableCell>{user.email}</TableCell>
                    <TableCell>
                      <Chip
                        label={roleLabels[user.role]}
                        size="small"
                        color={roleColors[user.role]}
                      />
                    </TableCell>
                    <TableCell>{user.phoneNumber || '-'}</TableCell>
                    <TableCell>
                      <Chip
                        label={user.isActive ? 'Ativo' : 'Inativo'}
                        size="small"
                        color={user.isActive ? 'success' : 'default'}
                      />
                    </TableCell>
                    <TableCell>
                      {new Date(user.createdAt).toLocaleDateString('pt-BR')}
                    </TableCell>
                    <TableCell align="right">
                      <Stack direction="row" spacing={1} justifyContent="flex-end">
                        <Tooltip title="Editar">
                          <IconButton
                            size="small"
                            onClick={() => handleEditUser(user)}
                          >
                            <Edit fontSize="small" />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title={user.isActive ? 'Desativar' : 'Ativar'}>
                          <IconButton
                            size="small"
                            onClick={() => handleToggleStatus(user)}
                          >
                            {user.isActive ? (
                              <PersonOff fontSize="small" />
                            ) : (
                              <Person fontSize="small" />
                            )}
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Resetar senha">
                          <IconButton
                            size="small"
                            onClick={() => handleResetPassword(user)}
                          >
                            <Lock fontSize="small" />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Excluir">
                          <IconButton
                            size="small"
                            color="error"
                            onClick={() => handleDeleteUser(user)}
                          >
                            <Delete fontSize="small" />
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

        <TablePagination
          component="div"
          count={totalCount}
          page={page}
          onPageChange={handleChangePage}
          rowsPerPage={rowsPerPage}
          onRowsPerPageChange={handleChangeRowsPerPage}
          labelRowsPerPage="Linhas por página:"
          labelDisplayedRows={({ from, to, count }) =>
            `${from}-${to} de ${count !== -1 ? count : `mais de ${to}`}`
          }
        />
      </Card>

      <UserDialog
        open={dialogOpen}
        user={selectedUser}
        onClose={handleDialogClose}
      />

      <ConfirmDialog
        open={confirmDialog.open}
        title={confirmDialog.title}
        message={confirmDialog.message}
        onConfirm={() => {
          confirmDialog.onConfirm()
          setConfirmDialog({ ...confirmDialog, open: false })
        }}
        onCancel={() => setConfirmDialog({ ...confirmDialog, open: false })}
      />
    </Box>
  )
}