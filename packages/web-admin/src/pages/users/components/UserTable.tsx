import React, { useState } from 'react'
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  Checkbox,
  Avatar,
  Typography,
  Chip,
  Stack,
  IconButton,
  Tooltip,
  Box,
  Skeleton,
  Alert,
  useTheme,
  alpha,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  Divider,
  Button,
  Toolbar,
  Collapse,
} from '@mui/material'
import {
  Edit,
  Delete,
  PersonOff,
  Person,
  Lock,
  MoreVert,
  SelectAll,
  Deselect,
  PersonAdd,
  Email,
  VerifiedUser,
  Warning,
} from '@mui/icons-material'
import { User, UserRole } from '@/types/user'

interface UserTableProps {
  users: User[]
  loading: boolean
  page: number
  rowsPerPage: number
  totalCount: number
  onChangePage: (page: number) => void
  onChangeRowsPerPage: (rowsPerPage: number) => void
  onEditUser: (user: User) => void
  onDeleteUser: (user: User) => void
  onToggleStatus: (user: User) => void
  onResetPassword: (user: User) => void
  onBulkAction: (action: string, userIds: string[]) => void
  clinicsMap?: Map<string, string>
}

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

export default function UserTable({
  users,
  loading,
  page,
  rowsPerPage,
  totalCount,
  onChangePage,
  onChangeRowsPerPage,
  onEditUser,
  onDeleteUser,
  onToggleStatus,
  onResetPassword,
  onBulkAction,
  clinicsMap = new Map(),
}: UserTableProps) {
  const theme = useTheme()
  const [selectedUsers, setSelectedUsers] = useState<string[]>([])
  const [actionMenuAnchor, setActionMenuAnchor] = useState<null | HTMLElement>(null)
  const [currentUser, setCurrentUser] = useState<User | null>(null)

  const handleSelectAll = () => {
    if (selectedUsers.length === users.length) {
      setSelectedUsers([])
    } else {
      setSelectedUsers(users.map(user => user.id))
    }
  }

  const handleSelectUser = (userId: string) => {
    setSelectedUsers(prev =>
      prev.includes(userId)
        ? prev.filter(id => id !== userId)
        : [...prev, userId]
    )
  }

  const handleActionMenuOpen = (event: React.MouseEvent<HTMLElement>, user: User) => {
    setActionMenuAnchor(event.currentTarget)
    setCurrentUser(user)
  }

  const handleActionMenuClose = () => {
    setActionMenuAnchor(null)
    setCurrentUser(null)
  }

  const handleBulkActivate = () => {
    onBulkAction('activate', selectedUsers)
    setSelectedUsers([])
  }

  const handleBulkDeactivate = () => {
    onBulkAction('deactivate', selectedUsers)
    setSelectedUsers([])
  }

  const handleBulkDelete = () => {
    onBulkAction('delete', selectedUsers)
    setSelectedUsers([])
  }

  const isUserSelected = (userId: string) => selectedUsers.includes(userId)
  const selectedCount = selectedUsers.length

  return (
    <Box>
      {/* Bulk Actions Toolbar */}
      <Collapse in={selectedCount > 0}>
        <Toolbar
          sx={{
            bgcolor: alpha(theme.palette.primary.main, 0.1),
            borderRadius: 1,
            mb: 2,
            minHeight: 48,
          }}
        >
          <Stack
            direction="row"
            alignItems="center"
            justifyContent="space-between"
            width="100%"
          >
            <Typography variant="body2" fontWeight={600}>
              {selectedCount} usuário{selectedCount !== 1 ? 's' : ''} selecionado{selectedCount !== 1 ? 's' : ''}
            </Typography>
            
            <Stack direction="row" spacing={1}>
              <Button
                size="small"
                startIcon={<PersonAdd />}
                onClick={handleBulkActivate}
                color="success"
                variant="outlined"
              >
                Ativar
              </Button>
              <Button
                size="small"
                startIcon={<PersonOff />}
                onClick={handleBulkDeactivate}
                color="warning"
                variant="outlined"
              >
                Desativar
              </Button>
              <Button
                size="small"
                startIcon={<Delete />}
                onClick={handleBulkDelete}
                color="error"
                variant="outlined"
              >
                Excluir
              </Button>
              <Button
                size="small"
                onClick={() => setSelectedUsers([])}
                variant="text"
              >
                Cancelar
              </Button>
            </Stack>
          </Stack>
        </Toolbar>
      </Collapse>

      <TableContainer>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell padding="checkbox">
                <Tooltip title={selectedUsers.length === users.length ? 'Desmarcar todos' : 'Selecionar todos'}>
                  <Checkbox
                    indeterminate={selectedUsers.length > 0 && selectedUsers.length < users.length}
                    checked={users.length > 0 && selectedUsers.length === users.length}
                    onChange={handleSelectAll}
                  />
                </Tooltip>
              </TableCell>
              <TableCell>
                <Typography variant="subtitle2" fontWeight={600}>
                  Usuário
                </Typography>
              </TableCell>
              <TableCell>
                <Typography variant="subtitle2" fontWeight={600}>
                  Perfil
                </Typography>
              </TableCell>
              <TableCell>
                <Typography variant="subtitle2" fontWeight={600}>
                  Contato
                </Typography>
              </TableCell>
              <TableCell>
                <Typography variant="subtitle2" fontWeight={600}>
                  Status
                </Typography>
              </TableCell>
              <TableCell>
                <Typography variant="subtitle2" fontWeight={600}>
                  Clínica
                </Typography>
              </TableCell>
              <TableCell>
                <Typography variant="subtitle2" fontWeight={600}>
                  Criado em
                </Typography>
              </TableCell>
              <TableCell align="right">
                <Typography variant="subtitle2" fontWeight={600}>
                  Ações
                </Typography>
              </TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? (
              Array.from(new Array(rowsPerPage)).map((_, index) => (
                <TableRow key={index}>
                  <TableCell padding="checkbox">
                    <Skeleton variant="circular" width={24} height={24} />
                  </TableCell>
                  <TableCell>
                    <Stack direction="row" spacing={2} alignItems="center">
                      <Skeleton variant="circular" width={40} height={40} />
                      <Box>
                        <Skeleton width={120} height={20} />
                        <Skeleton width={180} height={16} />
                      </Box>
                    </Stack>
                  </TableCell>
                  <TableCell><Skeleton width={80} height={24} /></TableCell>
                  <TableCell><Skeleton width={100} height={16} /></TableCell>
                  <TableCell><Skeleton width={60} height={24} /></TableCell>
                  <TableCell><Skeleton width={120} height={16} /></TableCell>
                  <TableCell><Skeleton width={80} height={16} /></TableCell>
                  <TableCell><Skeleton width={100} height={32} /></TableCell>
                </TableRow>
              ))
            ) : users.length === 0 ? (
              <TableRow>
                <TableCell colSpan={8} align="center" sx={{ py: 6 }}>
                  <Alert severity="info" sx={{ justifyContent: 'center', border: 'none' }}>
                    <Stack alignItems="center" spacing={1}>
                      <Typography variant="body1" fontWeight={500}>
                        Nenhum usuário encontrado
                      </Typography>
                      <Typography variant="body2" color="textSecondary">
                        Tente ajustar os filtros ou criar um novo usuário
                      </Typography>
                    </Stack>
                  </Alert>
                </TableCell>
              </TableRow>
            ) : (
              users.map((user) => (
                <TableRow
                  key={user.id}
                  hover
                  selected={isUserSelected(user.id)}
                  sx={{
                    '&.Mui-selected': {
                      bgcolor: alpha(theme.palette.primary.main, 0.05),
                    },
                    '&:hover': {
                      bgcolor: alpha(theme.palette.primary.main, 0.02),
                    },
                  }}
                >
                  <TableCell padding="checkbox">
                    <Checkbox
                      checked={isUserSelected(user.id)}
                      onChange={() => handleSelectUser(user.id)}
                    />
                  </TableCell>
                  
                  <TableCell>
                    <Stack direction="row" spacing={2} alignItems="center">
                      <Avatar
                        src={user.photoUrl}
                        alt={user.fullName}
                        sx={{ width: 40, height: 40 }}
                      >
                        {user.fullName.charAt(0)}
                      </Avatar>
                      <Box sx={{ minWidth: 0 }}>
                        <Typography variant="body2" fontWeight={500} noWrap>
                          {user.fullName}
                        </Typography>
                        <Stack direction="row" alignItems="center" spacing={1}>
                          <Typography
                            variant="caption"
                            color="textSecondary"
                            noWrap
                            sx={{ maxWidth: 200 }}
                          >
                            {user.email}
                          </Typography>
                          {user.isEmailVerified ? (
                            <VerifiedUser color="success" sx={{ fontSize: 14 }} />
                          ) : (
                            <Warning color="warning" sx={{ fontSize: 14 }} />
                          )}
                        </Stack>
                      </Box>
                    </Stack>
                  </TableCell>

                  <TableCell>
                    <Chip
                      label={roleLabels[user.role]}
                      size="small"
                      color={roleColors[user.role]}
                      sx={{ fontWeight: 500 }}
                    />
                  </TableCell>

                  <TableCell>
                    <Stack spacing={0.5}>
                      {user.phoneNumber && (
                        <Typography variant="caption" color="textSecondary">
                          {user.phoneNumber}
                        </Typography>
                      )}
                    </Stack>
                  </TableCell>

                  <TableCell>
                    <Chip
                      label={user.isActive ? 'Ativo' : 'Inativo'}
                      size="small"
                      color={user.isActive ? 'success' : 'default'}
                      variant={user.isActive ? 'filled' : 'outlined'}
                    />
                  </TableCell>

                  <TableCell>
                    <Typography variant="body2" color="textSecondary" noWrap>
                      {user.clinicId ? clinicsMap.get(user.clinicId) || 'N/A' : '-'}
                    </Typography>
                  </TableCell>

                  <TableCell>
                    <Typography variant="body2" color="textSecondary">
                      {new Date(user.createdAt).toLocaleDateString('pt-BR', {
                        day: '2-digit',
                        month: '2-digit',
                        year: 'numeric',
                      })}
                    </Typography>
                  </TableCell>

                  <TableCell align="right">
                    <Stack direction="row" spacing={0.5} justifyContent="flex-end">
                      <Tooltip title="Editar">
                        <IconButton
                          size="small"
                          onClick={() => onEditUser(user)}
                          sx={{
                            bgcolor: alpha(theme.palette.primary.main, 0.1),
                            '&:hover': { bgcolor: alpha(theme.palette.primary.main, 0.2) },
                          }}
                        >
                          <Edit fontSize="small" />
                        </IconButton>
                      </Tooltip>
                      
                      <Tooltip title="Mais ações">
                        <IconButton
                          size="small"
                          onClick={(e) => handleActionMenuOpen(e, user)}
                          sx={{
                            bgcolor: alpha(theme.palette.text.secondary, 0.1),
                            '&:hover': { bgcolor: alpha(theme.palette.text.secondary, 0.2) },
                          }}
                        >
                          <MoreVert fontSize="small" />
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
        onPageChange={(_, newPage) => onChangePage(newPage)}
        rowsPerPage={rowsPerPage}
        onRowsPerPageChange={(e) => onChangeRowsPerPage(parseInt(e.target.value, 10))}
        labelRowsPerPage="Linhas por página:"
        labelDisplayedRows={({ from, to, count }) =>
          `${from}-${to} de ${count !== -1 ? count : `mais de ${to}`}`
        }
        rowsPerPageOptions={[5, 10, 25, 50]}
        sx={{
          borderTop: `1px solid ${theme.palette.divider}`,
          '& .MuiTablePagination-toolbar': {
            paddingLeft: 2,
            paddingRight: 2,
          },
        }}
      />

      {/* Action Menu */}
      <Menu
        anchorEl={actionMenuAnchor}
        open={Boolean(actionMenuAnchor)}
        onClose={handleActionMenuClose}
        PaperProps={{
          sx: { minWidth: 200 },
        }}
      >
        {currentUser && (
          <>
            <MenuItem onClick={() => { onToggleStatus(currentUser); handleActionMenuClose() }}>
              <ListItemIcon>
                {currentUser.isActive ? <PersonOff fontSize="small" /> : <Person fontSize="small" />}
              </ListItemIcon>
              <ListItemText>{currentUser.isActive ? 'Desativar' : 'Ativar'}</ListItemText>
            </MenuItem>
            
            <MenuItem onClick={() => { onResetPassword(currentUser); handleActionMenuClose() }}>
              <ListItemIcon>
                <Lock fontSize="small" />
              </ListItemIcon>
              <ListItemText>Resetar Senha</ListItemText>
            </MenuItem>
            
            <Divider />
            
            <MenuItem
              onClick={() => { onDeleteUser(currentUser); handleActionMenuClose() }}
              sx={{ color: 'error.main' }}
            >
              <ListItemIcon>
                <Delete fontSize="small" color="error" />
              </ListItemIcon>
              <ListItemText>Excluir</ListItemText>
            </MenuItem>
          </>
        )}
      </Menu>
    </Box>
  )
}