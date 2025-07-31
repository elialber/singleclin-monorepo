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
} from '@mui/material'
import { Visibility, VisibilityOff } from '@mui/icons-material'
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
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)
  
  const {
    control,
    handleSubmit,
    watch,
    formState: { errors },
    setValue,
  } = useForm<UserFormData>({
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

  // Show clinic field only for clinic roles
  const showClinicField = ['ClinicOrigin', 'ClinicPartner'].includes(selectedRole)

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
        <Typography variant="h6">
          {user ? 'Editar Usuário' : 'Novo Usuário'}
        </Typography>

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
              helperText={errors.email?.message}
              disabled={!!user} // Email cannot be changed
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
              label="Telefone"
              fullWidth
              placeholder="(00) 00000-0000"
              error={!!errors.phoneNumber}
              helperText={errors.phoneNumber?.message}
              onChange={(e) => {
                const formatted = formatPhone(e.target.value)
                field.onChange(formatted)
              }}
            />
          )}
        />

        <Controller
          name="role"
          control={control}
          rules={{ required: 'Perfil é obrigatório' }}
          render={({ field }) => (
            <FormControl fullWidth error={!!errors.role}>
              <InputLabel>Perfil</InputLabel>
              <Select {...field} label="Perfil">
                {roleOptions.map((option) => (
                  <MenuItem key={option.value} value={option.value}>
                    {option.label}
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
                <InputLabel>Clínica</InputLabel>
                <Select {...field} label="Clínica">
                  <MenuItem value="">
                    <em>Selecione uma clínica</em>
                  </MenuItem>
                  {clinics.map((clinic) => (
                    <MenuItem key={clinic.id} value={clinic.id}>
                      {clinic.name}
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

        {!user && (
          <>
            <Controller
              name="password"
              control={control}
              rules={{
                required: !user ? 'Senha é obrigatória' : false,
                minLength: {
                  value: 6,
                  message: 'Senha deve ter no mínimo 6 caracteres',
                },
              }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Senha"
                  type={showPassword ? 'text' : 'password'}
                  fullWidth
                  error={!!errors.password}
                  helperText={errors.password?.message}
                  InputProps={{
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
          </>
        )}

        {user && (
          <Controller
            name="isActive"
            control={control}
            render={({ field }) => (
              <FormControlLabel
                control={
                  <Switch
                    checked={field.value}
                    onChange={field.onChange}
                    color="primary"
                  />
                }
                label="Usuário ativo"
              />
            )}
          />
        )}
      </Stack>
    </Box>
  )
}