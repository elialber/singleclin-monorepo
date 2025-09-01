import { useState, useEffect, useCallback } from 'react'
import { useForm } from 'react-hook-form'
import { useNavigate, Link, useLocation } from 'react-router-dom'
import {
  Box,
  TextField,
  Button,
  Typography,
  Alert,
  InputAdornment,
  IconButton,
  CircularProgress,
  Paper,
  useTheme,
  useMediaQuery,
  Fade,
  Slide,
  Container,
  FormControlLabel,
  Checkbox,
  Chip,
} from '@mui/material'
import {
  Email as EmailIcon,
  Lock as LockIcon,
  Visibility,
  VisibilityOff,
  LocalHospital as LocalHospitalIcon,
  Security as SecurityIcon,
  Healing as HealingIcon,
  Psychology as PsychologyIcon,
  CheckCircleOutline as CheckCircleIcon,
  Keyboard as CapsLockIcon,
  Shield as ShieldIcon,
} from '@mui/icons-material'
import { Divider } from '@mui/material'
import { keyframes } from '@mui/system'
import { useAuth } from "@/hooks/useAuth"
import { useNotification } from "@/hooks/useNotification"
import { GoogleLoginButton } from '@/components/GoogleLoginButton'
import { SingleClinLogo } from '@/components/SingleClinLogo'

interface LoginFormData {
  email: string
  password: string
  rememberMe?: boolean
}

// Floating animation for hero icons
const float = keyframes`
  0%, 100% { transform: translateY(0) rotate(0deg); }
  25% { transform: translateY(-10px) rotate(2deg); }
  50% { transform: translateY(-5px) rotate(-1deg); }
  75% { transform: translateY(-15px) rotate(1deg); }
`

// Pulse animation for the main logo
const pulse = keyframes`
  0% { transform: scale(1); }
  50% { transform: scale(1.05); }
  100% { transform: scale(1); }
`

// Gradient shift animation
const gradientShift = keyframes`
  0%, 100% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
`

export default function Login() {
  const { login, isAuthenticated } = useAuth()
  const { showError, showSuccess } = useNotification()
  const navigate = useNavigate()
  const theme = useTheme()
  const isMobile = useMediaQuery(theme.breakpoints.down('md'))
  const [showPassword, setShowPassword] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  const [showContent, setShowContent] = useState(false)
  const [capsLockOn, setCapsLockOn] = useState(false)
  const [emailError, setEmailError] = useState('')
  const [isRedirected, setIsRedirected] = useState(false)
  const location = useLocation()

  const {
    register,
    handleSubmit,
    formState: { errors },
    watch,
    clearErrors,
  } = useForm<LoginFormData>({
    defaultValues: {
      rememberMe: false
    }
  })

  const watchEmail = watch('email')

  // Animate content on mount
  useEffect(() => {
    const timer = setTimeout(() => setShowContent(true), 100)
    return () => clearTimeout(timer)
  }, [])

  // Check if user was redirected
  useEffect(() => {
    const params = new URLSearchParams(location.search)
    if (params.get('redirected') === 'true') {
      setIsRedirected(true)
    }
  }, [location])

  // Email validation with debounce
  useEffect(() => {
    if (!watchEmail) {
      setEmailError('')
      return
    }

    const timer = setTimeout(() => {
      const emailRegex = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i
      if (watchEmail && !emailRegex.test(watchEmail)) {
        setEmailError('Formato de email inválido')
      } else {
        setEmailError('')
        clearErrors('email')
      }
    }, 500)

    return () => clearTimeout(timer)
  }, [watchEmail, clearErrors])

  // Caps Lock detection
  const handleKeyPress = useCallback((event: KeyboardEvent) => {
    setCapsLockOn(event.getModifierState('CapsLock'))
  }, [])

  useEffect(() => {
    document.addEventListener('keydown', handleKeyPress)
    document.addEventListener('keyup', handleKeyPress)
    return () => {
      document.removeEventListener('keydown', handleKeyPress)
      document.removeEventListener('keyup', handleKeyPress)
    }
  }, [handleKeyPress])

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
    } catch (err: any) {
      console.error('Login error:', err)
      
      let message = 'Erro ao fazer login. Tente novamente.'
      
      // Handle Firebase specific errors
      if (err.message?.includes('Email ou senha incorretos')) {
        message = 'Email ou senha incorretos. Verifique suas credenciais.'
      } else if (err.message?.includes('Usuário não encontrado')) {
        message = 'Usuário não encontrado. Verifique o email digitado.'
      } else if (err.message?.includes('Senha incorreta')) {
        message = 'Senha incorreta. Tente novamente.'
      } else if (err.message?.includes('Muitas tentativas')) {
        message = 'Muitas tentativas de login. Tente novamente mais tarde.'
      } else if (err.message?.includes('Endpoint de autenticação não encontrado')) {
        message = 'Erro de conexão com o servidor. Verifique se o backend está rodando.'
      } else if (err.response?.status === 401) {
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

  if (isMobile) {
    // Mobile layout - single column with simplified design
    return (
      <Box
        sx={{
          minHeight: '100vh',
          display: 'flex',
          flexDirection: 'column',
          background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.primary.dark} 100%)`,
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        {/* Animated background elements */}
        <Box
          sx={{
            position: 'absolute',
            top: '10%',
            right: '10%',
            opacity: 0.1,
            animation: `${float} 6s ease-in-out infinite`,
          }}
        >
          <HealingIcon sx={{ fontSize: 120, color: 'white' }} />
        </Box>
        <Box
          sx={{
            position: 'absolute',
            top: '60%',
            left: '5%',
            opacity: 0.08,
            animation: `${float} 8s ease-in-out infinite reverse`,
          }}
        >
          <SecurityIcon sx={{ fontSize: 80, color: 'white' }} />
        </Box>

        <Container 
          component="main" 
          maxWidth="sm" 
          sx={{ 
            flex: 1, 
            display: 'flex', 
            alignItems: 'center',
            py: 4,
          }}
        >
          <Fade in={showContent} timeout={800}>
            <Paper
              elevation={24}
              sx={{
                width: '100%',
                p: 4,
                borderRadius: 3,
                background: '#fafafa',
                backdropFilter: 'blur(10px)',
                border: '1px solid rgba(0, 0, 0, 0.08)',
              }}
            >
              {/* Logo Section */}
              <Box sx={{ textAlign: 'center', mb: 4 }}>
                <Box
                  sx={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    animation: `${pulse} 2s ease-in-out infinite`,
                  }}
                >
                  <SingleClinLogo 
                    width={48} 
                    height={48} 
                    variant="dark"
                  />
                  <Box sx={{ textAlign: 'left', ml: 2 }}>
                    <Typography
                      variant="h4"
                      sx={{
                        fontWeight: 700,
                        background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.primary.dark} 100%)`,
                        backgroundClip: 'text',
                        WebkitBackgroundClip: 'text',
                        WebkitTextFillColor: 'transparent',
                        lineHeight: 1.2,
                      }}
                    >
                      SingleClin
                    </Typography>
                    <Typography
                      variant="caption"
                      sx={{
                        color: 'text.secondary',
                        letterSpacing: 1.5,
                        fontWeight: 500,
                      }}
                    >
                      PORTAL ADMINISTRATIVO
                    </Typography>
                  </Box>
                </Box>
              </Box>

              {/* Login Form */}
              <Box component="form" onSubmit={handleSubmit(handleLogin)}>
                <Typography 
                  variant="h5" 
                  align="center" 
                  sx={{ 
                    mb: 1,
                    fontWeight: 600,
                    color: 'text.primary',
                  }}
                >
                  Acessar sua conta
                </Typography>
                
                <Typography 
                  variant="body2" 
                  align="center" 
                  color="text.secondary"
                  sx={{ mb: 3 }}
                >
                  Use suas credenciais para continuar
                </Typography>

                {isRedirected && (
                  <Alert 
                    severity="info" 
                    sx={{ 
                      mb: 2,
                      borderRadius: 2,
                      backgroundColor: 'rgba(33, 150, 243, 0.08)',
                      border: '1px solid rgba(33, 150, 243, 0.2)',
                    }}
                  >
                    Você foi redirecionado. Faça login para continuar.
                  </Alert>
                )}

                {error && (
                  <Slide direction="down" in={!!error} mountOnEnter unmountOnExit>
                    <Alert 
                      severity="error" 
                      sx={{ 
                        mb: 2,
                        borderRadius: 2,
                        '& .MuiAlert-icon': {
                          alignItems: 'center',
                        }
                      }}
                      onClose={() => setError('')}
                    >
                      {error}
                    </Alert>
                  </Slide>
                )}

                <TextField
                  margin="normal"
                  required
                  fullWidth
                  id="email"
                  label="Email"
                  autoComplete="email"
                  autoFocus
                  error={!!errors.email || !!emailError}
                  helperText={emailError || errors.email?.message}
                  InputProps={{
                    startAdornment: (
                      <InputAdornment position="start">
                        <EmailIcon color="action" />
                      </InputAdornment>
                    ),
                    endAdornment: watchEmail && !emailError && !errors.email ? (
                      <InputAdornment position="end">
                        <CheckCircleIcon 
                          sx={{ 
                            color: 'success.main',
                            fontSize: 20,
                          }} 
                        />
                      </InputAdornment>
                    ) : null,
                  }}
                  sx={{
                    '& .MuiOutlinedInput-root': {
                      borderRadius: 2,
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        '& .MuiOutlinedInput-notchedOutline': {
                          borderColor: theme.palette.primary.light,
                        },
                      },
                      '&.Mui-focused': {
                        '& .MuiOutlinedInput-notchedOutline': {
                          borderWidth: 2,
                        },
                      },
                    },
                  }}
                  {...register('email', {
                    required: 'Email é obrigatório',
                    pattern: {
                      value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
                      message: 'Email inválido',
                    },
                  })}
                />

                <Box sx={{ position: 'relative' }}>
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
                            aria-label={`${showPassword ? 'Ocultar' : 'Mostrar'} senha`}
                            onClick={() => setShowPassword(!showPassword)}
                            onKeyDown={(e) => {
                              if (e.key === 'Enter' || e.key === ' ') {
                                e.preventDefault()
                                setShowPassword(!showPassword)
                              }
                            }}
                            edge="end"
                            tabIndex={0}
                            sx={{
                              transition: 'color 0.2s ease',
                              '&:hover': {
                                color: theme.palette.primary.main,
                              },
                            }}
                          >
                            {showPassword ? <VisibilityOff /> : <Visibility />}
                          </IconButton>
                        </InputAdornment>
                      ),
                    }}
                    sx={{
                      '& .MuiOutlinedInput-root': {
                        borderRadius: 2,
                        transition: 'all 0.3s ease',
                        '&:hover': {
                          '& .MuiOutlinedInput-notchedOutline': {
                            borderColor: theme.palette.primary.light,
                          },
                        },
                        '&.Mui-focused': {
                          '& .MuiOutlinedInput-notchedOutline': {
                            borderWidth: 2,
                          },
                        },
                      },
                    }}
                    {...register('password', {
                      required: 'Senha é obrigatória',
                    })}
                  />
                  
                  {capsLockOn && (
                    <Fade in={capsLockOn}>
                      <Box
                        sx={{
                          position: 'absolute',
                          right: 8,
                          top: 8,
                          display: 'flex',
                          alignItems: 'center',
                          gap: 0.5,
                          color: 'warning.main',
                          fontSize: '0.75rem',
                          zIndex: 1,
                        }}
                      >
                        <CapsLockIcon sx={{ fontSize: 16 }} />
                        <Typography variant="caption" color="warning.main">
                          Caps Lock ativo
                        </Typography>
                      </Box>
                    </Fade>
                  )}
                </Box>

                <FormControlLabel
                  control={
                    <Checkbox
                      {...register('rememberMe')}
                      sx={{
                        '&.Mui-checked': {
                          color: theme.palette.primary.main,
                        },
                      }}
                    />
                  }
                  label={
                    <Typography variant="body2" color="text.secondary">
                      Lembrar de mim
                    </Typography>
                  }
                  sx={{ mt: 1, mb: 1 }}
                />

                <Button
                  type="submit"
                  fullWidth
                  variant="contained"
                  disabled={isLoading}
                  sx={{ 
                    mt: 2, 
                    mb: 2, 
                    py: 1.5,
                    borderRadius: 2,
                    fontWeight: 600,
                    fontSize: '1.1rem',
                    textTransform: 'none',
                    boxShadow: `0 4px 12px rgba(0, 81, 86, 0.3)`,
                    position: 'relative',
                    overflow: 'hidden',
                    transition: 'all 0.3s ease',
                    '&:hover:not(:disabled)': {
                      transform: 'translateY(-2px)',
                      boxShadow: `0 6px 20px rgba(0, 81, 86, 0.4)`,
                    },
                    '&:active': {
                      transform: 'translateY(0)',
                    },
                    '&:disabled': {
                      backgroundColor: theme.palette.primary.main,
                      color: 'white',
                      opacity: 0.8,
                    },
                  }}
                >
                  {isLoading ? (
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <CircularProgress size={20} color="inherit" />
                      <Typography variant="inherit">Entrando...</Typography>
                    </Box>
                  ) : (
                    'Entrar'
                  )}
                </Button>
                
                {/* Secure connection indicator */}
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', mb: 2 }}>
                  <ShieldIcon sx={{ fontSize: 14, color: 'success.main', mr: 0.5 }} />
                  <Typography variant="caption" color="success.main" sx={{ fontWeight: 500 }}>
                    Conexão segura
                  </Typography>
                </Box>

                <Divider sx={{ 
                  my: 2.5, 
                  '&::before, &::after': { borderColor: 'divider' },
                  '& .MuiDivider-wrapper': {
                    px: 2,
                  }
                }}>
                  <Chip 
                    label="ou" 
                    size="small"
                    sx={{ 
                      backgroundColor: 'background.paper',
                      color: 'text.secondary',
                      fontSize: '0.75rem',
                      border: `1px solid ${theme.palette.divider}`,
                    }}
                  />
                </Divider>

                <GoogleLoginButton />

                <Box sx={{ mt: 3, textAlign: 'center', space: 2 }}>
                  <Button
                    variant="text"
                    size="medium"
                    sx={{ 
                      textTransform: 'none',
                      fontWeight: 600,
                      color: theme.palette.primary.main,
                      mb: 2,
                      '&:hover': {
                        backgroundColor: `rgba(${theme.palette.primary.main.replace('#', '').match(/.{2}/g)?.map(hex => parseInt(hex, 16)).join(', ')}, 0.04)`,
                      },
                    }}
                    disabled
                  >
                    Esqueci minha senha
                  </Button>
                  
                  <Typography variant="body2" color="text.secondary">
                    Novo por aqui?{' '}
                    <Link to="/register" style={{ textDecoration: 'none' }}>
                      <Button
                        variant="text"
                        size="small"
                        sx={{ 
                          textTransform: 'none',
                          fontWeight: 600,
                          color: theme.palette.primary.main,
                          '&:hover': {
                            backgroundColor: 'transparent',
                            textDecoration: 'underline',
                          },
                        }}
                      >
                        Crie sua conta
                      </Button>
                    </Link>
                  </Typography>
                </Box>
              </Box>
            </Paper>
          </Fade>
        </Container>

        {/* Footer */}
        <Box sx={{ p: 2, textAlign: 'center' }}>
          <Typography
            variant="body2"
            sx={{ 
              color: 'rgba(255, 255, 255, 0.8)',
              fontWeight: 300,
            }}
          >
            © {new Date().getFullYear()} SingleClin. Todos os direitos reservados.
          </Typography>
        </Box>
      </Box>
    )
  }

  // Desktop layout - split screen design
  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        overflow: 'hidden',
      }}
    >
      {/* Left Hero Section */}
      <Box
        sx={{
          flex: 1,
          background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.primary.dark} 100%)`,
          backgroundSize: '400% 400%',
          animation: `${gradientShift} 8s ease infinite`,
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          position: 'relative',
          overflow: 'hidden',
          color: 'white',
        }}
      >
        {/* Animated background elements */}
        <Box
          sx={{
            position: 'absolute',
            top: '15%',
            right: '15%',
            opacity: 0.1,
            animation: `${float} 6s ease-in-out infinite`,
          }}
        >
          <HealingIcon sx={{ fontSize: 200, color: 'white' }} />
        </Box>
        <Box
          sx={{
            position: 'absolute',
            bottom: '20%',
            left: '10%',
            opacity: 0.08,
            animation: `${float} 8s ease-in-out infinite reverse`,
          }}
        >
          <SecurityIcon sx={{ fontSize: 120, color: 'white' }} />
        </Box>
        <Box
          sx={{
            position: 'absolute',
            top: '40%',
            left: '5%',
            opacity: 0.06,
            animation: `${float} 10s ease-in-out infinite`,
          }}
        >
          <PsychologyIcon sx={{ fontSize: 100, color: 'white' }} />
        </Box>

        <Fade in={showContent} timeout={1000}>
          <Box sx={{ textAlign: 'center', zIndex: 1, px: 4 }}>
            <Box
              sx={{
                display: 'inline-flex',
                alignItems: 'center',
                mb: 4,
                animation: `${pulse} 3s ease-in-out infinite`,
              }}
            >
              <SingleClinLogo 
                width={80} 
                height={80} 
                variant="light"
              />
              <Box sx={{ textAlign: 'left', ml: 3 }}>
                <Typography
                  variant="h2"
                  sx={{
                    fontWeight: 700,
                    lineHeight: 1.2,
                    textShadow: '0 2px 4px rgba(0,0,0,0.3)',
                  }}
                >
                  SingleClin
                </Typography>
                <Typography
                  variant="h6"
                  sx={{
                    opacity: 0.9,
                    letterSpacing: 2,
                    fontWeight: 300,
                  }}
                >
                  PORTAL ADMINISTRATIVO
                </Typography>
              </Box>
            </Box>

            <Typography
              variant="h4"
              sx={{
                mb: 3,
                fontWeight: 600,
                textShadow: '0 2px 4px rgba(0,0,0,0.2)',
              }}
            >
              Bem-vindo de volta!
            </Typography>

            <Typography
              variant="h6"
              sx={{ 
                mb: 4,
                opacity: 0.9,
                fontWeight: 300,
                maxWidth: 380,
                lineHeight: 1.5,
              }}
            >
              Tecnologia avançada para gestão completa do seu ecossistema de saúde
            </Typography>

            {/* Feature highlights */}
            <Box sx={{ mt: 6, maxWidth: 500 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                <SecurityIcon sx={{ mr: 2, fontSize: 24 }} />
                <Typography variant="body1" sx={{ opacity: 0.9 }}>
                  Segurança e conformidade com LGPD
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                <HealingIcon sx={{ mr: 2, fontSize: 24 }} />
                <Typography variant="body1" sx={{ opacity: 0.9 }}>
                  Gestão integrada de clínicas e pacientes
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                <PsychologyIcon sx={{ mr: 2, fontSize: 24 }} />
                <Typography variant="body1" sx={{ opacity: 0.9 }}>
                  Análises inteligentes em tempo real
                </Typography>
              </Box>
            </Box>
          </Box>
        </Fade>
      </Box>

      {/* Right Login Section */}
      <Box
        sx={{
          flex: 1,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: '#fafafa',
          p: 4,
        }}
      >
        <Slide direction="left" in={showContent} timeout={800}>
          <Paper
            elevation={0}
            sx={{
              width: '100%',
              maxWidth: 480,
              p: 6,
              borderRadius: 3,
              border: '1px solid rgba(0, 0, 0, 0.08)',
              background: '#ffffff',
              boxShadow: '0 2px 8px rgba(0, 0, 0, 0.08)',
            }}
          >
            <Box component="form" onSubmit={handleSubmit(handleLogin)}>
              <Typography 
                variant="h4" 
                align="center" 
                sx={{ 
                  mb: 1,
                  fontWeight: 700,
                  color: 'text.primary',
                }}
              >
                Acessar sua conta
              </Typography>
              
              <Typography 
                variant="body1" 
                align="center" 
                color="text.secondary"
                sx={{ mb: 3 }}
              >
                Use suas credenciais para continuar
              </Typography>

              {isRedirected && (
                <Alert 
                  severity="info" 
                  sx={{ 
                    mb: 3,
                    borderRadius: 2,
                    backgroundColor: 'rgba(33, 150, 243, 0.08)',
                    border: '1px solid rgba(33, 150, 243, 0.2)',
                  }}
                >
                  Você foi redirecionado. Faça login para continuar.
                </Alert>
              )}

              {error && (
                <Slide direction="down" in={!!error} mountOnEnter unmountOnExit>
                  <Alert 
                    severity="error" 
                    sx={{ 
                      mb: 3,
                      borderRadius: 2,
                      border: `1px solid ${theme.palette.error.light}`,
                      '& .MuiAlert-icon': {
                        alignItems: 'center',
                      }
                    }}
                    onClose={() => setError('')}
                  >
                    {error}
                  </Alert>
                </Slide>
              )}

              <TextField
                margin="normal"
                required
                fullWidth
                id="email"
                label="Email"
                autoComplete="email"
                autoFocus
                error={!!errors.email || !!emailError}
                helperText={emailError || errors.email?.message}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <EmailIcon color="action" aria-label="Ícone de email" />
                    </InputAdornment>
                  ),
                  endAdornment: watchEmail && !emailError && !errors.email ? (
                    <InputAdornment position="end">
                      <CheckCircleIcon 
                        sx={{ 
                          color: 'success.main',
                          fontSize: 20,
                        }} 
                        aria-label="Email válido"
                      />
                    </InputAdornment>
                  ) : null,
                }}
                inputProps={{
                  'aria-label': 'Campo de email',
                  'aria-describedby': emailError ? 'email-error' : undefined,
                }}
                sx={{
                  '& .MuiOutlinedInput-root': {
                    borderRadius: 2,
                    backgroundColor: 'rgba(255, 255, 255, 0.9)',
                    transition: 'all 0.3s ease',
                    '&:hover': {
                      backgroundColor: 'rgba(255, 255, 255, 1)',
                      '& .MuiOutlinedInput-notchedOutline': {
                        borderColor: theme.palette.primary.light,
                      },
                    },
                    '&.Mui-focused': {
                      backgroundColor: 'rgba(255, 255, 255, 1)',
                      '& .MuiOutlinedInput-notchedOutline': {
                        borderWidth: 2,
                      },
                    },
                  },
                  '& .MuiInputLabel-root': {
                    fontWeight: 500,
                  },
                }}
                {...register('email', {
                  required: 'Email é obrigatório',
                  pattern: {
                    value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
                    message: 'Email inválido',
                  },
                })}
              />

              <Box sx={{ position: 'relative' }}>
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
                        <LockIcon color="action" aria-label="Ícone de cadeado" />
                      </InputAdornment>
                    ),
                    endAdornment: (
                      <InputAdornment position="end">
                        <IconButton
                          aria-label={`${showPassword ? 'Ocultar' : 'Mostrar'} senha`}
                          onClick={() => setShowPassword(!showPassword)}
                          onKeyDown={(e) => {
                            if (e.key === 'Enter' || e.key === ' ') {
                              e.preventDefault()
                              setShowPassword(!showPassword)
                            }
                          }}
                          edge="end"
                          tabIndex={0}
                          sx={{
                            transition: 'color 0.2s ease',
                            '&:hover': {
                              color: theme.palette.primary.main,
                            },
                          }}
                        >
                          {showPassword ? <VisibilityOff /> : <Visibility />}
                        </IconButton>
                      </InputAdornment>
                    ),
                  }}
                  inputProps={{
                    'aria-label': 'Campo de senha',
                    'aria-describedby': capsLockOn ? 'caps-lock-warning' : undefined,
                  }}
                  sx={{
                    '& .MuiOutlinedInput-root': {
                      borderRadius: 2,
                      backgroundColor: 'rgba(255, 255, 255, 0.9)',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        backgroundColor: 'rgba(255, 255, 255, 1)',
                        '& .MuiOutlinedInput-notchedOutline': {
                          borderColor: theme.palette.primary.light,
                        },
                      },
                      '&.Mui-focused': {
                        backgroundColor: 'rgba(255, 255, 255, 1)',
                        '& .MuiOutlinedInput-notchedOutline': {
                          borderWidth: 2,
                        },
                      },
                    },
                    '& .MuiInputLabel-root': {
                      fontWeight: 500,
                    },
                  }}
                  {...register('password', {
                    required: 'Senha é obrigatória',
                  })}
                />
                
                {capsLockOn && (
                  <Fade in={capsLockOn}>
                    <Box
                      id="caps-lock-warning"
                      sx={{
                        position: 'absolute',
                        right: 60,
                        top: 20,
                        display: 'flex',
                        alignItems: 'center',
                        gap: 0.5,
                        color: 'warning.main',
                        fontSize: '0.75rem',
                        zIndex: 1,
                        backgroundColor: 'background.paper',
                        px: 1,
                        borderRadius: 1,
                        border: `1px solid ${theme.palette.warning.light}`,
                      }}
                    >
                      <CapsLockIcon sx={{ fontSize: 14 }} />
                      <Typography variant="caption" color="warning.main">
                        Caps Lock ativo
                      </Typography>
                    </Box>
                  </Fade>
                )}
              </Box>

              <FormControlLabel
                control={
                  <Checkbox
                    {...register('rememberMe')}
                    sx={{
                      '&.Mui-checked': {
                        color: theme.palette.primary.main,
                      },
                    }}
                  />
                }
                label={
                  <Typography variant="body2" color="text.secondary">
                    Lembrar de mim
                  </Typography>
                }
                sx={{ mt: 2, mb: 1 }}
              />

              <Button
                type="submit"
                fullWidth
                variant="contained"
                disabled={isLoading}
                sx={{ 
                  mt: 2, 
                  mb: 2, 
                  py: 1.8,
                  borderRadius: 2,
                  fontWeight: 600,
                  fontSize: '1.1rem',
                  textTransform: 'none',
                  boxShadow: `0 4px 12px rgba(0, 81, 86, 0.3)`,
                  position: 'relative',
                  overflow: 'hidden',
                  transition: 'all 0.3s ease',
                  '&:hover:not(:disabled)': {
                    transform: 'translateY(-2px)',
                    boxShadow: `0 6px 20px rgba(0, 81, 86, 0.4)`,
                  },
                  '&:active': {
                    transform: 'translateY(0)',
                  },
                  '&:disabled': {
                    backgroundColor: theme.palette.primary.main,
                    color: 'white',
                    opacity: 0.8,
                  },
                }}
              >
                {isLoading ? (
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <CircularProgress size={20} color="inherit" />
                    <Typography variant="inherit">Entrando...</Typography>
                  </Box>
                ) : (
                  'Entrar'
                )}
              </Button>
              
              {/* Secure connection indicator */}
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', mb: 2 }}>
                <ShieldIcon sx={{ fontSize: 14, color: 'success.main', mr: 0.5 }} />
                <Typography variant="caption" color="success.main" sx={{ fontWeight: 500 }}>
                  Conexão segura
                </Typography>
              </Box>

              <Divider sx={{ 
                my: 2.5, 
                '&::before, &::after': { borderColor: 'divider' },
                '& .MuiDivider-wrapper': {
                  px: 2,
                }
              }}>
                <Chip 
                  label="ou" 
                  size="small"
                  sx={{ 
                    backgroundColor: 'background.paper',
                    color: 'text.secondary',
                    fontSize: '0.75rem',
                    border: `1px solid ${theme.palette.divider}`,
                  }}
                />
              </Divider>

              <GoogleLoginButton />

              <Box sx={{ mt: 3, textAlign: 'center', space: 2 }}>
                <Button
                  variant="text"
                  size="medium"
                  sx={{ 
                    textTransform: 'none',
                    fontWeight: 600,
                    color: theme.palette.primary.main,
                    mb: 2,
                    px: 0,
                    '&:hover': {
                      backgroundColor: `rgba(${theme.palette.primary.main.replace('#', '').match(/.{2}/g)?.map(hex => parseInt(hex, 16)).join(', ')}, 0.04)`,
                    },
                  }}
                  disabled
                >
                  Esqueci minha senha
                </Button>
                
                <Typography variant="body2" color="text.secondary">
                  Novo por aqui?{' '}
                  <Link to="/register" style={{ textDecoration: 'none' }}>
                    <Button
                      variant="text"
                      size="small"
                      sx={{ 
                        textTransform: 'none',
                        fontWeight: 600,
                        color: theme.palette.primary.main,
                        '&:hover': {
                          backgroundColor: 'transparent',
                          textDecoration: 'underline',
                        },
                      }}
                    >
                      Crie sua conta
                    </Button>
                  </Link>
                </Typography>
              </Box>
            </Box>
          </Paper>
        </Slide>
      </Box>
    </Box>
  )
}