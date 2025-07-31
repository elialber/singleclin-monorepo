import { useState, useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { useNavigate } from 'react-router-dom'
import {
  Box,
  TextField,
  Button,
  Typography,
  Alert,
  InputAdornment,
  IconButton,
  CircularProgress,
} from '@mui/material'
import {
  Email as EmailIcon,
  Lock as LockIcon,
  Visibility,
  VisibilityOff,
  Google as GoogleIcon,
} from '@mui/icons-material'
import { Divider } from '@mui/material'
import { useAuth } from "@/hooks/useAuth"
import { useNotification } from "@/hooks/useNotification"

interface LoginFormData {
  email: string
  password: string
}

import { GoogleLoginButton } from '@/components/GoogleLoginButton'

export default function Login() {
  const { login, isAuthenticated } = useAuth()
  const { showError, showSuccess } = useNotification()
  const navigate = useNavigate()
  const [showPassword, setShowPassword] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormData>()

  // Redirect if already authenticated
  useEffect(() => {
    if (isAuthenticated) {
      navigate('/dashboard')
    }
  }, [isAuthenticated, navigate])

  const handleLogin = async (data: LoginFormData) => {
    try {
      setIsLoading(true)
      setError('')
      await login(data.email, data.password)
      showSuccess('Login realizado com sucesso!')
    } catch (err: unknown) {
      console.error('Login error:', err)
      
      let message = 'Erro ao fazer login. Tente novamente.'
      
      if (err.response?.status === 401) {
        message = 'Email ou senha incorretos'
      } else if (err.response?.status === 403) {
        message = 'Acesso negado. Verifique suas permissões.'
      } else if (err.response?.data?.message) {
        message = err.response.data.message
      } else if (err.response?.data?.detail) {
        message = err.response.data.detail
      } else if (err.message) {
        message = err.message
      }
      
      setError(message)
      showError(message)
    } finally {
      setIsLoading(false)
    }
  }


  return (
    <Box component="form" onSubmit={handleSubmit(handleLogin)} sx={{ mt: 1 }}>
      <Typography component="h2" variant="h5" align="center" sx={{ mb: 3 }}>
        Faça login em sua conta
      </Typography>

      {error && (
        <Alert 
          severity="error" 
          sx={{ mb: 2 }}
          onClose={() => setError('')}
        >
          {error}
        </Alert>
      )}

      <TextField
        margin="normal"
        required
        fullWidth
        id="email"
        label="Email"
        autoComplete="email"
        autoFocus
        error={!!errors.email}
        helperText={errors.email?.message}
        InputProps={{
          startAdornment: (
            <InputAdornment position="start">
              <EmailIcon color="action" />
            </InputAdornment>
          ),
        }}
        {...register('email', {
          required: 'Email é obrigatório',
          pattern: {
            value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
            message: 'Email inválido',
          },
        })}
      />

      <TextField
        margin="normal"
        required
        fullWidth
        label="Senha"
        type={showPassword ? 'text' : 'password'}
        id="password"
        autoComplete="current-password"
        error={!!errors.password}
        helperText={errors.password?.message}
        InputProps={{
          startAdornment: (
            <InputAdornment position="start">
              <LockIcon color="action" />
            </InputAdornment>
          ),
          endAdornment: (
            <InputAdornment position="end">
              <IconButton
                aria-label="toggle password visibility"
                onClick={() => setShowPassword(!showPassword)}
                edge="end"
              >
                {showPassword ? <VisibilityOff /> : <Visibility />}
              </IconButton>
            </InputAdornment>
          ),
        }}
        {...register('password', {
          required: 'Senha é obrigatória',
          minLength: {
            value: 6,
            message: 'Senha deve ter no mínimo 6 caracteres',
          },
        })}
      />

      <Button
        type="submit"
        fullWidth
        variant="contained"
        sx={{ mt: 3, mb: 2, py: 1.5 }}
        disabled={isLoading}
      >
        {isLoading ? (
          <CircularProgress size={24} color="inherit" />
        ) : (
          'Entrar'
        )}
      </Button>

      <Divider sx={{ my: 2 }}>ou</Divider>

      <GoogleLoginButton />

      <Box sx={{ mt: 2, textAlign: 'center' }}>
        <Typography variant="body2" color="text.secondary">
          Esqueceu sua senha?{' '}
          <Button
            variant="text"
            size="small"
            sx={{ textTransform: 'none' }}
            disabled
          >
            Recuperar senha
          </Button>
        </Typography>
      </Box>
    </Box>
  )
}