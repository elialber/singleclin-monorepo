import React from 'react'
import {
  Box,
  Card,
  CardContent,
  Grid,
  Typography,
  LinearProgress,
  Stack,
  Chip,
  Avatar,
  AvatarGroup,
  useTheme,
} from '@mui/material'
import {
  People,
  PersonAdd,
  PersonOff,
  AdminPanelSettings,
  LocalHospital,
  AccountCircle,
  TrendingUp,
  Schedule,
} from '@mui/icons-material'
import { User, UserRole } from '@/types/user'

interface UserStats {
  total: number
  active: number
  inactive: number
  new: number
  byRole: Record<UserRole, number>
  recentUsers: User[]
  trends: {
    totalChange: number
    activeChange: number
  }
}

interface UserDashboardProps {
  stats: UserStats
  loading?: boolean
}

const roleIcons: Record<UserRole, React.ReactElement> = {
  Administrator: <AdminPanelSettings fontSize="small" />,
  ClinicOrigin: <LocalHospital fontSize="small" />,
  ClinicPartner: <LocalHospital fontSize="small" />,
  Patient: <AccountCircle fontSize="small" />,
}

const roleColors: Record<UserRole, string> = {
  Administrator: '#f44336',
  ClinicOrigin: '#ff9800',
  ClinicPartner: '#2196f3',
  Patient: '#4caf50',
}

export default function UserDashboard({ stats, loading }: UserDashboardProps) {
  const theme = useTheme()

  const metrics = [
    {
      title: 'Total de Usuários',
      value: stats.total,
      change: stats.trends.totalChange,
      icon: <People />,
      color: theme.palette.primary.main,
    },
    {
      title: 'Usuários Ativos',
      value: stats.active,
      change: stats.trends.activeChange,
      icon: <PersonAdd />,
      color: theme.palette.success.main,
    },
    {
      title: 'Usuários Inativos',
      value: stats.inactive,
      change: 0,
      icon: <PersonOff />,
      color: theme.palette.warning.main,
    },
    {
      title: 'Novos (7 dias)',
      value: stats.new,
      change: 0,
      icon: <Schedule />,
      color: theme.palette.info.main,
    },
  ]

  if (loading) {
    return (
      <Grid container spacing={3} sx={{ mb: 3 }}>
        {[1, 2, 3, 4].map((i) => (
          <Grid item xs={12} sm={6} md={3} key={i}>
            <Card>
              <CardContent>
                <Box sx={{ height: 80 }}>
                  <LinearProgress />
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    )
  }

  return (
    <Grid container spacing={3} sx={{ mb: 3 }}>
      {/* Metrics Cards */}
      {metrics.map((metric, index) => (
        <Grid item xs={12} sm={6} md={3} key={index}>
          <Card
            sx={{
              height: '100%',
              background: `linear-gradient(135deg, ${metric.color}15 0%, ${metric.color}05 100%)`,
              border: `1px solid ${metric.color}30`,
              transition: 'all 0.3s ease',
              '&:hover': {
                transform: 'translateY(-2px)',
                boxShadow: theme.shadows[8],
                border: `1px solid ${metric.color}50`,
              },
            }}
          >
            <CardContent>
              <Stack direction="row" justifyContent="space-between" alignItems="flex-start">
                <Box>
                  <Typography color="textSecondary" gutterBottom variant="body2" fontWeight={500}>
                    {metric.title}
                  </Typography>
                  <Typography variant="h4" fontWeight="bold" color={metric.color}>
                    {metric.value.toLocaleString()}
                  </Typography>
                  {metric.change !== 0 && (
                    <Stack direction="row" alignItems="center" spacing={0.5} mt={1}>
                      <TrendingUp
                        fontSize="small"
                        color={metric.change > 0 ? 'success' : 'error'}
                      />
                      <Typography
                        variant="caption"
                        color={metric.change > 0 ? 'success.main' : 'error.main'}
                        fontWeight={600}
                      >
                        {metric.change > 0 ? '+' : ''}{metric.change}%
                      </Typography>
                      <Typography variant="caption" color="textSecondary">
                        vs último período
                      </Typography>
                    </Stack>
                  )}
                </Box>
                <Avatar
                  sx={{
                    bgcolor: metric.color,
                    width: 48,
                    height: 48,
                  }}
                >
                  {metric.icon}
                </Avatar>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
      ))}

      {/* Role Distribution */}
      <Grid item xs={12} md={6}>
        <Card sx={{ height: '100%' }}>
          <CardContent>
            <Typography variant="h6" gutterBottom fontWeight={600}>
              Distribuição por Perfil
            </Typography>
            <Stack spacing={2}>
              {Object.entries(stats.byRole).map(([role, count]) => {
                const percentage = stats.total > 0 ? (count / stats.total) * 100 : 0
                const roleKey = role as UserRole
                
                return (
                  <Box key={role}>
                    <Stack direction="row" justifyContent="space-between" alignItems="center" mb={1}>
                      <Stack direction="row" alignItems="center" spacing={1}>
                        <Avatar
                          sx={{
                            bgcolor: roleColors[roleKey],
                            width: 24,
                            height: 24,
                          }}
                        >
                          {roleIcons[roleKey]}
                        </Avatar>
                        <Typography variant="body2" fontWeight={500}>
                          {roleKey === 'Administrator' ? 'Administrador' :
                           roleKey === 'ClinicOrigin' ? 'Clínica Origem' :
                           roleKey === 'ClinicPartner' ? 'Clínica Parceira' : 'Paciente'}
                        </Typography>
                      </Stack>
                      <Chip
                        label={`${count} (${percentage.toFixed(1)}%)`}
                        size="small"
                        sx={{
                          bgcolor: `${roleColors[roleKey]}20`,
                          color: roleColors[roleKey],
                          fontWeight: 600,
                        }}
                      />
                    </Stack>
                    <LinearProgress
                      variant="determinate"
                      value={percentage}
                      sx={{
                        height: 6,
                        borderRadius: 3,
                        bgcolor: `${roleColors[roleKey]}20`,
                        '& .MuiLinearProgress-bar': {
                          bgcolor: roleColors[roleKey],
                          borderRadius: 3,
                        },
                      }}
                    />
                  </Box>
                )
              })}
            </Stack>
          </CardContent>
        </Card>
      </Grid>

      {/* Recent Users */}
      <Grid item xs={12} md={6}>
        <Card sx={{ height: '100%' }}>
          <CardContent>
            <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
              <Typography variant="h6" fontWeight={600}>
                Usuários Recentes
              </Typography>
              <AvatarGroup max={4} spacing="small">
                {stats.recentUsers.slice(0, 4).map((user) => (
                  <Avatar
                    key={user.id}
                    src={user.photoUrl}
                    alt={user.fullName}
                    sx={{ width: 32, height: 32 }}
                  >
                    {user.fullName.charAt(0)}
                  </Avatar>
                ))}
              </AvatarGroup>
            </Stack>
            
            <Stack spacing={2}>
              {stats.recentUsers.slice(0, 5).map((user) => (
                <Stack
                  key={user.id}
                  direction="row"
                  spacing={2}
                  alignItems="center"
                  sx={{
                    p: 1,
                    borderRadius: 1,
                    transition: 'background-color 0.2s',
                    '&:hover': {
                      bgcolor: 'action.hover',
                    },
                  }}
                >
                  <Avatar
                    src={user.photoUrl}
                    alt={user.fullName}
                    sx={{ width: 32, height: 32 }}
                  >
                    {user.fullName.charAt(0)}
                  </Avatar>
                  <Box sx={{ flexGrow: 1, minWidth: 0 }}>
                    <Typography variant="body2" fontWeight={500} noWrap>
                      {user.fullName}
                    </Typography>
                    <Typography variant="caption" color="textSecondary" noWrap>
                      {user.email}
                    </Typography>
                  </Box>
                  <Stack alignItems="flex-end" spacing={0.5}>
                    <Chip
                      size="small"
                      label={
                        user.role === 'Administrator' ? 'Admin' :
                        user.role === 'ClinicOrigin' ? 'Origem' :
                        user.role === 'ClinicPartner' ? 'Parceira' : 'Paciente'
                      }
                      sx={{
                        bgcolor: `${roleColors[user.role]}20`,
                        color: roleColors[user.role],
                        fontSize: '10px',
                        height: 20,
                      }}
                    />
                    <Typography variant="caption" color="textSecondary">
                      {new Date(user.createdAt).toLocaleDateString('pt-BR', {
                        day: 'numeric',
                        month: 'short',
                      })}
                    </Typography>
                  </Stack>
                </Stack>
              ))}
            </Stack>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  )
}