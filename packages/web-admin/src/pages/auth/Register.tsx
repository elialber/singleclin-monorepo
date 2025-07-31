import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { useNavigate, Link } from 'react-router-dom'
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
  Person as PersonIcon,
  Visibility,
  VisibilityOff,
} from '@mui/icons-material'
import { useAuth } from "@/hooks/useAuth"
import { useNotification } from "@/hooks/useNotification"

interface RegisterFormData {
  fullName: string
  email: string
  password: string
  confirmPassword: string
}

export default function Register() {
  const { register: registerUser } = useAuth()
  const { showError, showSuccess } = useNotification()
  const navigate = useNavigate()
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')

  const {
    register,
    handleSubmit,
    watch,
    formState: { errors },
  } = useForm<RegisterFormData>()

  const password = watch('password')

  const handleRegister = async (data: RegisterFormData) => {
    try {
      setIsLoading(true)
      setError('')
      await registerUser(data.email, data.password, data.fullName)
      showSuccess('Conta criada com sucesso! Faça login para continuar.')
      navigate('/login')
    } catch (err: any) {
      console.error('Register error:', err)
      
      let message = 'Erro ao criar conta. Tente novamente.'
      
      if (err.response?.status === 400) {
        if (err.response?.data?.detail === 'Email already registered') {
          message = 'Este email já está cadastrado'
        } else if (err.response?.data?.errors) {
          // Handle validation errors
          const errors = err.response.data.errors
          message = Object.values(errors).flat().join(', ')
        } else if (err.response?.data?.message) {
          message = err.response.data.message
        }
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
    <Box component="form" onSubmit={handleSubmit(handleRegister)} sx={{ mt: 1 }}>
      <Typography component="h2" variant="h5" align="center" sx={{ mb: 3 }}>
        Criar nova conta
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
        id="fullName"
        label="Nome completo"
        autoComplete="name"
        autoFocus
        error={!!errors.fullName}
        helperText={errors.fullName?.message}
        InputProps={{
          startAdornment: (
            <InputAdornment position="start">
              <PersonIcon color="action" />
            </InputAdornment>
          ),
        }}
        {...register('fullName', {
          required: 'Nome é obrigatório',
          minLength: {
            value: 3,
            message: 'Nome deve ter no mínimo 3 caracteres',
          },
        })}
      />

      <TextField
        margin="normal"
        required
        fullWidth
        id="email"
        label="Email"
        autoComplete="email"
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
        autoComplete="new-password"
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
            value: 8,
            message: 'Senha deve ter no mínimo 8 caracteres',
          },
          pattern: {
            value: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/,
            message: 'Senha deve conter maiúsculas, minúsculas, números e caracteres especiais',
          },
        })}
      />

      <TextField
        margin="normal"
        required
        fullWidth
        label="Confirmar senha"
        type={showConfirmPassword ? 'text' : 'password'}
        id="confirmPassword"
        autoComplete="new-password"
        error={!!errors.confirmPassword}
        helperText={errors.confirmPassword?.message}
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
                onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                edge="end"
              >
                {showConfirmPassword ? <VisibilityOff /> : <Visibility />}
              </IconButton>
            </InputAdornment>
          ),
        }}
        {...register('confirmPassword', {
          required: 'Confirmação de senha é obrigatória',
          validate: value => value === password || 'As senhas não coincidem',
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
          'Criar conta'
        )}
      </Button>

      <Box sx={{ mt: 2, textAlign: 'center' }}>
        <Typography variant="body2" color="text.secondary">
          Já tem uma conta?{' '}
          <Link to="/login" style={{ textDecoration: 'none' }}>
            <Button
              variant="text"
              size="small"
              sx={{ textTransform: 'none' }}
            >
              Fazer login
            </Button>
          </Link>
        </Typography>
      </Box>
    </Box>
  )
}