import React from 'react'
import {
  Card,
  CardContent,
  Avatar,
  Typography,
  Chip,
  Stack,
  IconButton,
  Tooltip,
  Box,
  Badge,
  Divider,
  useTheme,
  alpha,
} from '@mui/material'
import {
  Edit,
  Delete,
  PersonOff,
  Person,
  Lock,
  Email,
  Phone,
  LocationCity,
  VerifiedUser,
  Schedule,
  MoreVert,
} from '@mui/icons-material'
import { User, UserRole } from '@/types/user'

interface UserCardProps {
  user: User
  onEdit: (user: User) => void
  onDelete: (user: User) => void
  onToggleStatus: (user: User) => void
  onResetPassword: (user: User) => void
  clinicName?: string
}

const roleColors: Record<UserRole, string> = {
  Administrator: '#f44336',
  ClinicOrigin: '#ff9800',
  ClinicPartner: '#2196f3',
  Patient: '#4caf50',
}

const roleLabels: Record<UserRole, string> = {
  Administrator: 'Administrador',
  ClinicOrigin: 'Clínica Origem',
  ClinicPartner: 'Clínica Parceira',
  Patient: 'Paciente',
}

export default function UserCard({
  user,
  onEdit,
  onDelete,
  onToggleStatus,
  onResetPassword,
  clinicName,
}: UserCardProps) {
  const theme = useTheme()
  const roleColor = roleColors[user.role]

  return (
    <Card
      sx={{
        height: '100%',
        transition: 'all 0.3s ease',
        border: `1px solid ${alpha(roleColor, 0.2)}`,
        position: 'relative',
        overflow: 'visible',
        '&:hover': {
          transform: 'translateY(-4px)',
          boxShadow: theme.shadows[12],
          border: `1px solid ${alpha(roleColor, 0.4)}`,
          '& .user-actions': {
            opacity: 1,
            transform: 'translateX(0)',
          },
        },
      }}
    >
      {/* Status Indicator */}
      <Box
        sx={{
          position: 'absolute',
          top: -2,
          left: -2,
          right: -2,
          height: 4,
          background: user.isActive
            ? `linear-gradient(90deg, ${roleColor}, ${alpha(roleColor, 0.7)})`
            : theme.palette.grey[300],
          borderRadius: '4px 4px 0 0',
        }}
      />

      <CardContent sx={{ p: 3 }}>
        <Stack spacing={2}>
          {/* Header with Avatar and Basic Info */}
          <Stack direction="row" spacing={2} alignItems="flex-start">
            <Badge
              overlap="circular"
              anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
              badgeContent={
                user.isEmailVerified ? (
                  <VerifiedUser
                    sx={{
                      color: theme.palette.success.main,
                      fontSize: 16,
                      bgcolor: theme.palette.background.paper,
                      borderRadius: '50%',
                    }}
                  />
                ) : null
              }
            >
              <Avatar
                src={user.photoUrl}
                alt={user.fullName}
                sx={{
                  width: 56,
                  height: 56,
                  bgcolor: alpha(roleColor, 0.1),
                  color: roleColor,
                  fontSize: '1.5rem',
                  fontWeight: 600,
                  border: `3px solid ${alpha(roleColor, 0.2)}`,
                }}
              >
                {user.fullName.charAt(0).toUpperCase()}
              </Avatar>
            </Badge>

            <Box sx={{ flexGrow: 1, minWidth: 0 }}>
              <Typography
                variant="h6"
                fontWeight={600}
                noWrap
                sx={{ color: theme.palette.text.primary }}
              >
                {user.fullName}
              </Typography>
              <Typography
                variant="body2"
                color="textSecondary"
                noWrap
                sx={{ mb: 1 }}
              >
                {user.email}
              </Typography>
              
              <Stack direction="row" spacing={1} alignItems="center">
                <Chip
                  label={roleLabels[user.role]}
                  size="small"
                  sx={{
                    bgcolor: alpha(roleColor, 0.1),
                    color: roleColor,
                    fontWeight: 600,
                    fontSize: '0.75rem',
                  }}
                />
                <Chip
                  label={user.isActive ? 'Ativo' : 'Inativo'}
                  size="small"
                  color={user.isActive ? 'success' : 'default'}
                  variant={user.isActive ? 'filled' : 'outlined'}
                />
              </Stack>
            </Box>

            {/* Quick Actions */}
            <Stack
              className="user-actions"
              direction="row"
              spacing={0.5}
              sx={{
                opacity: 0,
                transform: 'translateX(10px)',
                transition: 'all 0.3s ease',
              }}
            >
              <Tooltip title="Editar">
                <IconButton
                  size="small"
                  onClick={() => onEdit(user)}
                  sx={{
                    bgcolor: alpha(theme.palette.primary.main, 0.1),
                    '&:hover': { bgcolor: alpha(theme.palette.primary.main, 0.2) },
                  }}
                >
                  <Edit fontSize="small" />
                </IconButton>
              </Tooltip>
              <Tooltip title={user.isActive ? 'Desativar' : 'Ativar'}>
                <IconButton
                  size="small"
                  onClick={() => onToggleStatus(user)}
                  sx={{
                    bgcolor: alpha(theme.palette.warning.main, 0.1),
                    '&:hover': { bgcolor: alpha(theme.palette.warning.main, 0.2) },
                  }}
                >
                  {user.isActive ? <PersonOff fontSize="small" /> : <Person fontSize="small" />}
                </IconButton>
              </Tooltip>
            </Stack>
          </Stack>

          <Divider sx={{ mx: -1 }} />

          {/* Contact Information */}
          <Stack spacing={1.5}>
            {user.phoneNumber && (
              <Stack direction="row" alignItems="center" spacing={1}>
                <Phone fontSize="small" color="disabled" />
                <Typography variant="body2" color="textSecondary">
                  {user.phoneNumber}
                </Typography>
              </Stack>
            )}

            {clinicName && (
              <Stack direction="row" alignItems="center" spacing={1}>
                <LocationCity fontSize="small" color="disabled" />
                <Typography variant="body2" color="textSecondary" noWrap>
                  {clinicName}
                </Typography>
              </Stack>
            )}

            <Stack direction="row" alignItems="center" spacing={1}>
              <Schedule fontSize="small" color="disabled" />
              <Typography variant="body2" color="textSecondary">
                Criado em {new Date(user.createdAt).toLocaleDateString('pt-BR')}
              </Typography>
            </Stack>
          </Stack>

          <Divider sx={{ mx: -1 }} />

          {/* Footer Actions */}
          <Stack direction="row" justifyContent="space-between" alignItems="center">
            <Stack direction="row" spacing={1}>
              {!user.isEmailVerified && (
                <Chip
                  label="Email não verificado"
                  size="small"
                  color="warning"
                  variant="outlined"
                  sx={{ fontSize: '0.7rem' }}
                />
              )}
            </Stack>

            <Stack direction="row" spacing={0.5}>
              <Tooltip title="Resetar senha">
                <IconButton
                  size="small"
                  onClick={() => onResetPassword(user)}
                  sx={{ color: theme.palette.text.secondary }}
                >
                  <Lock fontSize="small" />
                </IconButton>
              </Tooltip>
              <Tooltip title="Excluir">
                <IconButton
                  size="small"
                  onClick={() => onDelete(user)}
                  sx={{ color: theme.palette.error.main }}
                >
                  <Delete fontSize="small" />
                </IconButton>
              </Tooltip>
            </Stack>
          </Stack>
        </Stack>
      </CardContent>
    </Card>
  )
}