import { useState, useEffect, useMemo } from 'react'
import {
  Box,
  Typography,
  Stack,
  Grid,
  Fade,
  Container,
} from '@mui/material'
import { useNotification } from '@/hooks/useNotification'
import { userService } from '@/services/user.service'
import { clinicService } from '@/services/clinic.service'
import { User, UserRole } from '@/types/user'
import { useDebounce } from '@/hooks/useDebounce'
import UserDialog from './UserDialog'
import ConfirmDialog from '@/components/ConfirmDialog'
import UserDashboard from './components/UserDashboard'
import UserFilters, { UserFilters as UserFiltersType } from './components/UserFilters'
import UserTable from './components/UserTable'
import UserCard from './components/UserCard'

export default function Users() {
  const { showNotification } = useNotification()
  const [users, setUsers] = useState<User[]>([])
  const [clinics, setClinics] = useState<Array<{ id: string; name: string }>>([])
  const [loading, setLoading] = useState(true)
  const [dashboardLoading, setDashboardLoading] = useState(true)
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)
  const [totalCount, setTotalCount] = useState(0)
  const [viewMode, setViewMode] = useState<'table' | 'cards'>('table')
  const [sortBy, setSortBy] = useState('fullName')
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('asc')
  
  const [filters, setFilters] = useState<UserFiltersType>({
    search: '',
    role: '',
    isActive: undefined,
    isEmailVerified: undefined,
    clinicId: undefined,
    createdAfter: undefined,
    createdBefore: undefined,
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
  }, [page, rowsPerPage, debouncedSearch, filters, sortBy, sortOrder])

  useEffect(() => {
    loadClinics()
    loadDashboardData()
  }, [])

  const loadUsers = async () => {
    try {
      setLoading(true)
      const response = await userService.getUsers({
        page: page + 1,
        limit: rowsPerPage,
        search: debouncedSearch,
        role: filters.role || undefined,
        isActive: filters.isActive,
        isEmailVerified: filters.isEmailVerified,
        clinicId: filters.clinicId,
        createdAfter: filters.createdAfter,
        createdBefore: filters.createdBefore,
        sortBy,
        sortOrder,
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

  const loadClinics = async () => {
    try {
      const response = await clinicService.getClinics({ limit: 100 })
      setClinics(response.data.map(c => ({ id: c.id, name: c.name })))
    } catch (error) {
      console.error('Error loading clinics:', error)
    }
  }

  const loadDashboardData = async () => {
    try {
      setDashboardLoading(true)
      // Dashboard data would be loaded here
      // For now, we'll simulate the loading
      await new Promise(resolve => setTimeout(resolve, 1000))
    } catch (error) {
      console.error('Error loading dashboard data:', error)
    } finally {
      setDashboardLoading(false)
    }
  }

  const handleChangePage = (newPage: number) => {
    setPage(newPage)
  }

  const handleChangeRowsPerPage = (newRowsPerPage: number) => {
    setRowsPerPage(newRowsPerPage)
    setPage(0)
  }

  const handleFiltersChange = (newFilters: UserFiltersType) => {
    setFilters(newFilters)
    setPage(0)
  }

  const handleSortChange = (newSortBy: string, newSortOrder: 'asc' | 'desc') => {
    setSortBy(newSortBy)
    setSortOrder(newSortOrder)
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

  const handleBulkAction = async (action: string, userIds: string[]) => {
    try {
      switch (action) {
        case 'activate':
          await Promise.all(userIds.map(id => userService.toggleUserStatus(id, true)))
          showNotification(`${userIds.length} usuários ativados com sucesso`, 'success')
          break
        case 'deactivate':
          await Promise.all(userIds.map(id => userService.toggleUserStatus(id, false)))
          showNotification(`${userIds.length} usuários desativados com sucesso`, 'success')
          break
        case 'delete':
          await Promise.all(userIds.map(id => userService.deleteUser(id)))
          showNotification(`${userIds.length} usuários excluídos com sucesso`, 'success')
          break
      }
      loadUsers()
    } catch (error) {
      showNotification('Erro ao executar ação em lote', 'error')
    }
  }

  const handleDialogClose = (shouldReload?: boolean) => {
    setDialogOpen(false)
    setSelectedUser(null)
    if (shouldReload) {
      loadUsers()
      loadDashboardData() // Reload dashboard when users change
    }
  }

  // Calculate dashboard statistics
  const dashboardStats = useMemo(() => {
    const stats = {
      total: totalCount,
      active: 0,
      inactive: 0,
      new: 0, // Users created in last 7 days
      byRole: {
        Administrator: 0,
        ClinicOrigin: 0,
        ClinicPartner: 0,
        Patient: 0,
      } as Record<UserRole, number>,
      recentUsers: users.slice(0, 5),
      trends: {
        totalChange: 5.2, // Mock data - would come from API
        activeChange: 3.1, // Mock data - would come from API
      }
    }

    const sevenDaysAgo = new Date()
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7)

    users.forEach(user => {
      if (user.isActive) stats.active++
      else stats.inactive++
      
      if (new Date(user.createdAt) > sevenDaysAgo) {
        stats.new++
      }
      
      stats.byRole[user.role]++
    })

    return stats
  }, [users, totalCount])

  // Create clinic map for faster lookups
  const clinicsMap = useMemo(() => {
    const map = new Map<string, string>()
    clinics.forEach(clinic => {
      map.set(clinic.id, clinic.name)
    })
    return map
  }, [clinics])

  return (
    <Container maxWidth="xl">
      <Fade in timeout={600}>
        <Box>
          {/* Page Header */}
          <Stack direction="row" justifyContent="space-between" alignItems="center" mb={4}>
            <Box>
              <Typography variant="h4" component="h1" fontWeight={700} gutterBottom>
                Gerenciamento de Usuários
              </Typography>
              <Typography variant="body1" color="textSecondary">
                Gerencie usuários do sistema, suas permissões e acesso às clínicas
              </Typography>
            </Box>
          </Stack>

          {/* Dashboard Overview */}
          <UserDashboard stats={dashboardStats} loading={dashboardLoading} />

          {/* Filters */}
          <UserFilters
            filters={filters}
            onFiltersChange={handleFiltersChange}
            onRefresh={loadUsers}
            onAddUser={handleAddUser}
            viewMode={viewMode}
            onViewModeChange={setViewMode}
            sortBy={sortBy}
            sortOrder={sortOrder}
            onSortChange={handleSortChange}
            totalCount={totalCount}
            loading={loading}
            clinics={clinics}
          />

          {/* Content */}
          {viewMode === 'table' ? (
            <UserTable
              users={users}
              loading={loading}
              page={page}
              rowsPerPage={rowsPerPage}
              totalCount={totalCount}
              onChangePage={handleChangePage}
              onChangeRowsPerPage={handleChangeRowsPerPage}
              onEditUser={handleEditUser}
              onDeleteUser={handleDeleteUser}
              onToggleStatus={handleToggleStatus}
              onResetPassword={handleResetPassword}
              onBulkAction={handleBulkAction}
              clinicsMap={clinicsMap}
            />
          ) : (
            <Box>
              <Grid container spacing={3}>
                {loading ? (
                  Array.from(new Array(rowsPerPage)).map((_, index) => (
                    <Grid item xs={12} sm={6} md={4} lg={3} key={index}>
                      <Box sx={{ height: 280, bgcolor: 'grey.100', borderRadius: 1 }} />
                    </Grid>
                  ))
                ) : users.length === 0 ? (
                  <Grid item xs={12}>
                    <Box sx={{ textAlign: 'center', py: 6 }}>
                      <Typography variant="h6" color="textSecondary" gutterBottom>
                        Nenhum usuário encontrado
                      </Typography>
                      <Typography variant="body2" color="textSecondary">
                        Tente ajustar os filtros ou criar um novo usuário
                      </Typography>
                    </Box>
                  </Grid>
                ) : (
                  users.map((user) => (
                    <Grid item xs={12} sm={6} md={4} lg={3} key={user.id}>
                      <UserCard
                        user={user}
                        onEdit={handleEditUser}
                        onDelete={handleDeleteUser}
                        onToggleStatus={handleToggleStatus}
                        onResetPassword={handleResetPassword}
                        clinicName={user.clinicId ? clinicsMap.get(user.clinicId) : undefined}
                      />
                    </Grid>
                  ))
                )}
              </Grid>

              {/* Pagination for Cards View */}
              {!loading && users.length > 0 && (
                <Stack direction="row" justifyContent="center" mt={4}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    <Typography variant="body2" color="textSecondary">
                      Página {page + 1} de {Math.ceil(totalCount / rowsPerPage)}
                    </Typography>
                    <Stack direction="row" spacing={1}>
                      {/* Pagination controls would go here */}
                    </Stack>
                  </Box>
                </Stack>
              )}
            </Box>
          )}

          {/* Dialogs */}
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
      </Fade>
    </Container>
  )
}