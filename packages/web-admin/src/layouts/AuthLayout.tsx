import { Outlet, Navigate } from 'react-router-dom'
import { Box, Container, Paper, Typography, useTheme } from '@mui/material'
import { LocalHospital as LocalHospitalIcon } from '@mui/icons-material'
import { useAuth } from '@/contexts/AuthContext'

export default function AuthLayout() {
  const theme = useTheme()
  const { isAuthenticated } = useAuth()

  // If already authenticated, redirect to dashboard
  if (isAuthenticated) {
    return <Navigate to="/dashboard" replace />
  }

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: theme.palette.background.default,
        backgroundImage: `linear-gradient(135deg, ${theme.palette.primary.main}20 0%, ${theme.palette.primary.light}10 100%)`,
      }}
    >
      <Container component="main" maxWidth="xs">
        <Paper
          elevation={3}
          sx={{
            p: 4,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            borderRadius: 2,
          }}
        >
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              mb: 3,
            }}
          >
            <LocalHospitalIcon
              sx={{
                fontSize: 48,
                color: theme.palette.primary.main,
                mr: 2,
              }}
            />
            <Box>
              <Typography
                component="h1"
                variant="h4"
                fontWeight={700}
                color="primary"
              >
                SingleClin
              </Typography>
              <Typography
                variant="caption"
                color="text.secondary"
                sx={{ letterSpacing: 1 }}
              >
                PORTAL ADMINISTRATIVO
              </Typography>
            </Box>
          </Box>
          <Outlet />
        </Paper>
        <Typography
          variant="body2"
          color="text.secondary"
          align="center"
          sx={{ mt: 3 }}
        >
          © {new Date().getFullYear()} SingleClin. Todos os direitos reservados.
        </Typography>
      </Container>
    </Box>
  )
}