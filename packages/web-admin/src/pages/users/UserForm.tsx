import { useEffect } from 'react'
import {
  Box,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  FormHelperText,
  Stack,
  Typography,
  Switch,
  FormControlLabel,
  InputAdornment,
  IconButton,
  Card,
  CardContent,
  Divider,
  Chip,
  Avatar,
  Alert,
  LinearProgress,
  useTheme,
  alpha,
} from '@mui/material'
import { 
  Visibility, 
  VisibilityOff,
  Person,
  Email,
  Phone,
  Badge,
  Business,
  Security,
  CheckCircle,
  Warning,
} from '@mui/icons-material'
import { User, UserRole } from '@/types/user'
import { useForm, Controller } from 'react-hook-form'
import { useState } from 'react'

interface UserFormData {
  email: string
  firstName: string
  lastName: string
  role: UserRole
  phoneNumber?: string
  clinicId?: string
  password?: string
  confirmPassword?: string
  isActive: boolean
}

interface UserFormProps {
  user?: User | null
  onSubmit: (data: UserFormData) => void
  clinics?: Array<{ id: string; name: string }>
}

const roleOptions: Array<{ value: UserRole; label: string }> = [
  { value: 'Administrator', label: 'Administrador' },
  { value: 'ClinicOrigin', label: 'Clínica Origem' },
  { value: 'ClinicPartner', label: 'Clínica Parceira' },
  { value: 'Patient', label: 'Paciente' },
]

export default function UserForm({ user, onSubmit, clinics = [] }: UserFormProps) {
  const theme = useTheme()
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)
  
  const {
    control,
    handleSubmit,
    watch,
    formState: { errors, isValid, dirtyFields },
    setValue,
  } = useForm<UserFormData>({
    mode: 'onChange',
    defaultValues: {
      email: user?.email || '',
      firstName: user?.firstName || '',
      lastName: user?.lastName || '',
      role: user?.role || 'Patient',
      phoneNumber: user?.phoneNumber || '',
      clinicId: user?.clinicId || '',
      password: '',
      confirmPassword: '',
      isActive: user?.isActive ?? true,
    },
  })

  const selectedRole = watch('role')
  const password = watch('password')
  const firstName = watch('firstName')
  const lastName = watch('lastName')
  const email = watch('email')

  // Show clinic field only for clinic roles
  const showClinicField = ['ClinicOrigin', 'ClinicPartner'].includes(selectedRole)
  
  // Calculate form completion progress
  const getFormProgress = () => {
    const requiredFields = ['firstName', 'lastName', 'email', 'role']
    if (!user) requiredFields.push('password', 'confirmPassword')
    if (showClinicField) requiredFields.push('clinicId')
    
    const completedFields = requiredFields.filter(field => {
      const value = watch(field as keyof UserFormData)
      return value && value.toString().trim() !== ''
    })
    
    return (completedFields.length / requiredFields.length) * 100
  }

  const formProgress = getFormProgress()
  const fullName = `${firstName} ${lastName}`.trim()

  useEffect(() => {
    // Clear clinic field when switching to non-clinic role
    if (!showClinicField) {
      setValue('clinicId', '')
    }
  }, [showClinicField, setValue])

  const validateEmail = (value: string) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return emailRegex.test(value) || 'Email inválido'
  }

  const validatePhone = (value?: string) => {
    if (!value) return true
    const phoneRegex = /^\(\d{2}\) \d{4,5}-\d{4}$/
    return phoneRegex.test(value) || 'Telefone inválido. Use o formato (XX) XXXXX-XXXX'
  }

  const formatPhone = (value: string) => {
    const numbers = value.replace(/\D/g, '')
    if (numbers.length <= 2) return `(${numbers}`
    if (numbers.length <= 6) return `(${numbers.slice(0, 2)}) ${numbers.slice(2)}`
    if (numbers.length <= 10) return `(${numbers.slice(0, 2)}) ${numbers.slice(2, 6)}-${numbers.slice(6)}`
    return `(${numbers.slice(0, 2)}) ${numbers.slice(2, 7)}-${numbers.slice(7, 11)}`
  }

  return (
    <Box component="form" onSubmit={handleSubmit(onSubmit)} noValidate>
      <Stack spacing={3}>
        {/* Header with Progress */}
        <Card variant="outlined" sx={{ bgcolor: alpha(theme.palette.primary.main, 0.02) }}>
          <CardContent sx={{ pb: 2 }}>
            <Stack direction="row" spacing={2} alignItems="center" mb={2}>
              <Avatar
                sx={{
                  width: 48,
                  height: 48,
                  bgcolor: theme.palette.primary.main,
                }}
              >
                {fullName ? fullName.charAt(0).toUpperCase() : <Person />}
              </Avatar>
              <Box sx={{ flexGrow: 1 }}>
                <Typography variant="h6" fontWeight={600}>
                  {user ? 'Editar Usuário' : 'Novo Usuário'}
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  {fullName || 'Complete os dados do usuário'}
                </Typography>
              </Box>
              <Box sx={{ minWidth: 80 }}>
                <Typography variant="caption" color="textSecondary" display="block">
                  Progresso
                </Typography>
                <Typography variant="body2" fontWeight={600}>
                  {Math.round(formProgress)}%
                </Typography>
              </Box>
            </Stack>
            
            <LinearProgress
              variant="determinate"
              value={formProgress}
              sx={{
                height: 6,
                borderRadius: 3,
                bgcolor: alpha(theme.palette.primary.main, 0.1),
                '& .MuiLinearProgress-bar': {
                  borderRadius: 3,
                },
              }}
            />
            
            {formProgress === 100 && isValid && (
              <Alert
                severity="success"
                icon={<CheckCircle />}
                sx={{ mt: 2, py: 0.5 }}
              >
                Formulário completo e válido
              </Alert>
            )}
          </CardContent>
        </Card>

        {/* Personal Information Section */}
        <Card variant="outlined">
          <CardContent>
            <Stack direction="row" alignItems="center" spacing={1} mb={2}>
              <Person color="primary" />
              <Typography variant="h6" fontWeight={600}>
                Informações Pessoais
              </Typography>
            </Stack>

            <Stack spacing={2}>
              <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
                <Controller
                  name="firstName"
                  control={control}
                  rules={{ required: 'Nome é obrigatório' }}
                  render={({ field }) => (
                    <TextField
                      {...field}
                      label="Nome"
                      fullWidth
                      error={!!errors.firstName}
                      helperText={errors.firstName?.message}
                      InputProps={{
                        startAdornment: (
                          <InputAdornment position="start">
                            <Person color="disabled" fontSize="small" />
                          </InputAdornment>
                        ),
                      }}
                    />
                  )}
                />

                <Controller
                  name="lastName"
                  control={control}
                  rules={{ required: 'Sobrenome é obrigatório' }}
                  render={({ field }) => (
                    <TextField
                      {...field}
                      label="Sobrenome"
                      fullWidth
                      error={!!errors.lastName}
                      helperText={errors.lastName?.message}
                    />
                  )}
                />
              </Stack>

              <Controller
                name="email"
                control={control}
                rules={{
                  required: 'Email é obrigatório',
                  validate: validateEmail,
                }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Email"
                    type="email"
                    fullWidth
                    error={!!errors.email}
                    helperText={errors.email?.message || (user ? 'Email não pode ser alterado' : '')}
                    disabled={!!user}
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <Email color="disabled" fontSize="small" />
                        </InputAdornment>
                      ),
                    }}
                  />
                )}
              />

              <Controller
                name="phoneNumber"
                control={control}
                rules={{ validate: validatePhone }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Telefone (opcional)"
                    fullWidth
                    placeholder="(00) 00000-0000"
                    error={!!errors.phoneNumber}
                    helperText={errors.phoneNumber?.message}
                    onChange={(e) => {
                      const formatted = formatPhone(e.target.value)
                      field.onChange(formatted)
                    }}
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <Phone color="disabled" fontSize="small" />
                        </InputAdornment>
                      ),
                    }}
                  />
                )}
              />
            </Stack>
          </CardContent>
        </Card>

        {/* Role and Clinic Section */}
        <Card variant="outlined">
          <CardContent>
            <Stack direction="row" alignItems="center" spacing={1} mb={2}>
              <Badge color="primary" />
              <Typography variant="h6" fontWeight={600}>
                Perfil e Permissões
              </Typography>
            </Stack>
            
            <Stack spacing={2}>

              <Controller
                name="role"
                control={control}
                rules={{ required: 'Perfil é obrigatório' }}
                render={({ field }) => (
                  <FormControl fullWidth error={!!errors.role}>
                    <InputLabel>Perfil do Usuário</InputLabel>
                    <Select {...field} label="Perfil do Usuário">
                      {roleOptions.map((option) => (
                        <MenuItem key={option.value} value={option.value}>
                          <Stack direction="row" alignItems="center" spacing={1}>
                            <Chip
                              size="small"
                              label={option.label}
                              color={
                                option.value === 'Administrator' ? 'error' :
                                option.value === 'ClinicOrigin' ? 'warning' :
                                option.value === 'ClinicPartner' ? 'info' : 'success'
                              }
                              sx={{ minWidth: 100 }}
                            />
                          </Stack>
                        </MenuItem>
                      ))}
                    </Select>
                    {errors.role && (
                      <FormHelperText>{errors.role.message}</FormHelperText>
                    )}
                  </FormControl>
                )}
              />

              {showClinicField && (
                <Controller
                  name="clinicId"
                  control={control}
                  rules={{
                    required: showClinicField ? 'Clínica é obrigatória para este perfil' : false,
                  }}
                  render={({ field }) => (
                    <FormControl fullWidth error={!!errors.clinicId}>
                      <InputLabel>Clínica Associada</InputLabel>
                      <Select {...field} label="Clínica Associada">
                        <MenuItem value="">
                          <em>Selecione uma clínica</em>
                        </MenuItem>
                        {clinics.map((clinic) => (
                          <MenuItem key={clinic.id} value={clinic.id}>
                            <Stack direction="row" alignItems="center" spacing={1}>
                              <Business fontSize="small" color="disabled" />
                              <Typography>{clinic.name}</Typography>
                            </Stack>
                          </MenuItem>
                        ))}
                      </Select>
                      {errors.clinicId && (
                        <FormHelperText>{errors.clinicId.message}</FormHelperText>
                      )}
                    </FormControl>
                  )}
                />
              )}

              {showClinicField && (
                <Alert severity="info" icon={<Business />}>
                  <Typography variant="body2">
                    Este usuário terá acesso específico à clínica selecionada
                  </Typography>
                </Alert>
              )}
            </Stack>
          </CardContent>
        </Card>

        {/* Security Section */}
        {!user && (
          <Card variant="outlined">
            <CardContent>
              <Stack direction="row" alignItems="center" spacing={1} mb={2}>
                <Security color="primary" />
                <Typography variant="h6" fontWeight={600}>
                  Segurança
                </Typography>
              </Stack>
              
              <Stack spacing={2}>
                <Controller
                  name="password"
                  control={control}
                  rules={{
                    required: !user ? 'Senha é obrigatória' : false,
                    validate: (value) => {
                      if (!value && !user) return 'Senha é obrigatória'
                      if (!value && user) return true // Skip validation for existing user updates
                      
                      if (value.length < 8) return 'Senha deve ter pelo menos 8 caracteres'
                      if (!/[a-z]/.test(value)) return 'Senha deve conter pelo menos uma letra minúscula'
                      if (!/[A-Z]/.test(value)) return 'Senha deve conter pelo menos uma letra maiúscula'  
                      if (!/\d/.test(value)) return 'Senha deve conter pelo menos um número'
                      if (!/[\W_]/.test(value)) return 'Senha deve conter pelo menos um caractere especial'
                      
                      return true
                    }
                  }}
                  render={({ field }) => (
                    <TextField
                      {...field}
                      label="Senha"
                      type={showPassword ? 'text' : 'password'}
                      fullWidth
                      error={!!errors.password}
                      helperText={errors.password?.message || 'Mínimo 8 caracteres com maiúscula, minúscula, número e símbolo. Ex: MinhaSenh@123'}
                      InputProps={{
                        startAdornment: (
                          <InputAdornment position="start">
                            <Security color="disabled" fontSize="small" />
                          </InputAdornment>
                        ),
                        endAdornment: (
                          <InputAdornment position="end">
                            <IconButton
                              onClick={() => setShowPassword(!showPassword)}
                              edge="end"
                            >
                              {showPassword ? <VisibilityOff /> : <Visibility />}
                            </IconButton>
                          </InputAdornment>
                        ),
                      }}
                    />
                  )}
                />

                <Controller
                  name="confirmPassword"
                  control={control}
                  rules={{
                    required: !user ? 'Confirmação de senha é obrigatória' : false,
                    validate: (value) =>
                      !password || value === password || 'As senhas não coincidem',
                  }}
                  render={({ field }) => (
                    <TextField
                      {...field}
                      label="Confirmar Senha"
                      type={showConfirmPassword ? 'text' : 'password'}
                      fullWidth
                      error={!!errors.confirmPassword}
                      helperText={errors.confirmPassword?.message}
                      InputProps={{
                        endAdornment: (
                          <InputAdornment position="end">
                            <IconButton
                              onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                              edge="end"
                            >
                              {showConfirmPassword ? <VisibilityOff /> : <Visibility />}
                            </IconButton>
                          </InputAdornment>
                        ),
                      }}
                    />
                  )}
                />

                <Alert severity="info" sx={{ mt: 1 }}>
                  <Typography variant="body2">
                    A senha será enviada por email para o usuário junto com as instruções de primeiro acesso.
                  </Typography>
                </Alert>
              </Stack>
            </CardContent>
          </Card>
        )}

        {/* Status Section - Only for editing */}
        {user && (
          <Card variant="outlined">
            <CardContent>
              <Stack direction="row" alignItems="center" spacing={1} mb={2}>
                <CheckCircle color="primary" />
                <Typography variant="h6" fontWeight={600}>
                  Status do Usuário
                </Typography>
              </Stack>
              
              <Controller
                name="isActive"
                control={control}
                render={({ field }) => (
                  <Stack spacing={2}>
                    <FormControlLabel
                      control={
                        <Switch
                          checked={field.value}
                          onChange={field.onChange}
                          color="primary"
                        />
                      }
                      label={
                        <Stack>
                          <Typography variant="body1" fontWeight={500}>
                            Usuário ativo
                          </Typography>
                          <Typography variant="body2" color="textSecondary">
                            {field.value 
                              ? 'O usuário pode fazer login e usar o sistema' 
                              : 'O usuário não pode fazer login no sistema'
                            }
                          </Typography>
                        </Stack>
                      }
                    />
                    
                    {!field.value && (
                      <Alert severity="warning" icon={<Warning />}>
                        <Typography variant="body2">
                          Usuários inativos não podem acessar o sistema e não recebem notificações.
                        </Typography>
                      </Alert>
                    )}
                  </Stack>
                )}
              />
            </CardContent>
          </Card>
        )}
      </Stack>
    </Box>
  )
}