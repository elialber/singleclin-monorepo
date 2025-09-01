import { useEffect } from 'react'
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Grid,
  FormControlLabel,
  Switch,
  Typography,
  Box,
  Alert,
  InputAdornment,
  MenuItem,
  FormControl,
  InputLabel,
  Select,
  LinearProgress,
} from '@mui/material'
import {
  Person as PersonIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  Business as BusinessIcon,
  Lock as LockIcon,
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
} from '@mui/icons-material'
import { useForm, Controller } from 'react-hook-form'
import { AxiosError } from 'axios'
import { useState } from 'react'
import { Patient, CreatePatientRequest, UpdatePatientRequest } from '@/types/patient'
import { useCreatePatient, useUpdatePatient } from '@/hooks/usePatients'
import { useActiveClinics } from '@/hooks/useClinics'

interface ValidationError {
  type: string
  title: string
  status: number
  errors: Record<string, string[]>
  traceId: string
}

interface PatientFormData {
  email: string
  firstName: string
  lastName: string
  phoneNumber: string
  clinicId: string
  password: string
  isActive: boolean
}

interface PatientFormDialogProps {
  open: boolean
  onClose: () => void
  patient?: Patient | null
}

export default function PatientFormDialog({ open, onClose, patient }: PatientFormDialogProps) {
  const isEditing = Boolean(patient)
  const createPatient = useCreatePatient()
  const updatePatient = useUpdatePatient()
  const [passwordValue, setPasswordValue] = useState('')
  const { data: clinics = [] } = useActiveClinics()

  // Password validation criteria
  const getPasswordCriteria = (password: string) => {
    return {
      minLength: password.length >= 8,
      hasUppercase: /[A-Z]/.test(password),
      hasLowercase: /[a-z]/.test(password),
      hasNumber: /\d/.test(password),
      hasSpecial: /[\W_]/.test(password),
    }
  }

  const getPasswordStrength = (password: string) => {
    const criteria = getPasswordCriteria(password)
    const validCount = Object.values(criteria).filter(Boolean).length
    return {
      score: validCount,
      percentage: (validCount / 5) * 100,
      label: validCount === 0 ? '' : 
             validCount <= 2 ? 'Fraca' :
             validCount <= 3 ? 'Média' :
             validCount <= 4 ? 'Boa' : 'Forte'
    }
  }

  // Custom validation function for React Hook Form
  const validatePassword = (value: string) => {
    if (!value) return 'Senha é obrigatória'
    
    const criteria = getPasswordCriteria(value)
    
    // Minimum 8 characters required (not 6!)
    if (!criteria.minLength) return 'Senha deve ter pelo menos 8 caracteres'
    if (!criteria.hasLowercase) return 'Senha deve conter pelo menos uma letra minúscula'
    if (!criteria.hasUppercase) return 'Senha deve conter pelo menos uma letra maiúscula'  
    if (!criteria.hasNumber) return 'Senha deve conter pelo menos um número'
    if (!criteria.hasSpecial) return 'Senha deve conter pelo menos um caractere especial'
    
    return true
  }

  const {
    control,
    handleSubmit,
    reset,
    setError,
    clearErrors,
    formState: { errors, isValid },
  } = useForm<PatientFormData>({
    defaultValues: {
      email: '',
      firstName: '',
      lastName: '',
      phoneNumber: '',
      clinicId: '',
      password: '',
      isActive: true,
    },
    mode: 'onChange',
  })

  // Function to handle backend validation errors
  const handleBackendValidationErrors = (error: AxiosError<ValidationError>) => {
    if (error.response?.status === 400 && error.response.data?.errors) {
      const backendErrors = error.response.data.errors
      
      // Map backend field names to form field names (case insensitive)
      const fieldMapping: Record<string, keyof PatientFormData> = {
        'email': 'email',
        'firstname': 'firstName',
        'lastname': 'lastName',
        'phonenumber': 'phoneNumber',
        'clinicid': 'clinicId',
        'password': 'password',
      }

      // Clear previous errors
      clearErrors()

      // Set errors from backend
      Object.entries(backendErrors).forEach(([backendField, messages]) => {
        const frontendField = fieldMapping[backendField.toLowerCase()]
        if (frontendField && messages.length > 0) {
          setError(frontendField, {
            type: 'server',
            message: messages[0] // Use the first error message
          })
        }
      })
    }
  }

  // Reset form when dialog opens/closes or patient changes
  useEffect(() => {
    if (open) {
      if (patient) {
        reset({
          email: patient.email,
          firstName: patient.firstName,
          lastName: patient.lastName,
          phoneNumber: patient.phoneNumber || '',
          clinicId: patient.clinicId || '',
          password: '', // Don't pre-fill password for editing
          isActive: patient.isActive,
        })
      } else {
        reset({
          email: '',
          firstName: '',
          lastName: '',
          phoneNumber: '',
          clinicId: '',
          password: '',
          isActive: true,
        })
      }
      // Reset password value state
      setPasswordValue('')
    }
  }, [open, patient, reset])

  const handleClose = () => {
    if (!createPatient.isPending && !updatePatient.isPending) {
      onClose()
    }
  }

  const onSubmit = async (data: PatientFormData) => {
    // Clear any previous errors
    clearErrors()

    if (isEditing && patient) {
      const updateData: UpdatePatientRequest = {
        email: data.email,
        firstName: data.firstName,
        lastName: data.lastName,
        phoneNumber: data.phoneNumber || undefined,
        clinicId: data.clinicId || undefined,
        isActive: data.isActive,
      }
      updatePatient.mutate({ id: patient.id, data: updateData }, {
        onSuccess: () => {
          onClose()
        },
        onError: (error: any) => {
          if (error.response?.status === 400 && error.response.data?.errors) {
            handleBackendValidationErrors(error)
          }
        }
      })
    } else {
      const createData: CreatePatientRequest = {
        email: data.email,
        firstName: data.firstName,
        lastName: data.lastName,
        phoneNumber: data.phoneNumber || undefined,
        clinicId: data.clinicId || undefined,
        password: data.password,
        isActive: data.isActive,
      }
      createPatient.mutate(createData, {
        onSuccess: () => {
          onClose()
        },
        onError: (error: any) => {
          if (error.response?.status === 400 && error.response.data?.errors) {
            handleBackendValidationErrors(error)
          }
        }
      })
    }
  }

  const isLoading = createPatient.isPending || updatePatient.isPending
  const submitError = createPatient.error || updatePatient.error

  return (
    <Dialog
      open={open}
      onClose={handleClose}
      maxWidth="md"
      fullWidth
      PaperProps={{
        sx: { borderRadius: 2 }
      }}
    >
      <DialogTitle>
        <Typography variant="h5" component="div" fontWeight={600}>
          {isEditing ? 'Editar Paciente' : 'Novo Paciente'}
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
          {isEditing 
            ? 'Modifique as informações do paciente existente'
            : 'Preencha as informações para criar um novo paciente'
          }
        </Typography>
      </DialogTitle>

      <form onSubmit={handleSubmit(onSubmit)}>
        <DialogContent dividers>
          {submitError && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {submitError instanceof Error ? submitError.message : 'Erro ao salvar paciente'}
            </Alert>
          )}

          <Grid container spacing={3}>
            <Grid item xs={12} sm={6}>
              <Controller
                name="firstName"
                control={control}
                rules={{ 
                  required: 'Nome é obrigatório',
                  minLength: { value: 2, message: 'Nome deve ter pelo menos 2 caracteres' },
                  maxLength: { value: 50, message: 'Nome deve ter no máximo 50 caracteres' },
                }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Nome"
                    fullWidth
                    error={!!errors.firstName}
                    helperText={errors.firstName?.message}
                    placeholder="Ex: João, Maria..."
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <PersonIcon />
                        </InputAdornment>
                      ),
                    }}
                  />
                )}
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <Controller
                name="lastName"
                control={control}
                rules={{ 
                  required: 'Sobrenome é obrigatório',
                  minLength: { value: 2, message: 'Sobrenome deve ter pelo menos 2 caracteres' },
                  maxLength: { value: 50, message: 'Sobrenome deve ter no máximo 50 caracteres' },
                }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Sobrenome"
                    fullWidth
                    error={!!errors.lastName}
                    helperText={errors.lastName?.message}
                    placeholder="Ex: Silva, Santos..."
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <PersonIcon />
                        </InputAdornment>
                      ),
                    }}
                  />
                )}
              />
            </Grid>

            <Grid item xs={12}>
              <Controller
                name="email"
                control={control}
                rules={{
                  required: 'Email é obrigatório',
                  pattern: {
                    value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
                    message: 'Formato de email inválido'
                  },
                  maxLength: { value: 100, message: 'Email deve ter no máximo 100 caracteres' }
                }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Email"
                    fullWidth
                    type="email"
                    error={!!errors.email}
                    helperText={errors.email?.message}
                    placeholder="paciente@email.com"
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <EmailIcon />
                        </InputAdornment>
                      ),
                    }}
                  />
                )}
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <Controller
                name="phoneNumber"
                control={control}
                rules={{
                  pattern: {
                    value: /^(\+?[\d\s\-\(\)\.]+(\s?(x|ext\.?)\s?\d+)?)$/,
                    message: 'Formato de telefone inválido. Use apenas números, espaços, parênteses, hifens e pontos'
                  },
                  maxLength: { value: 20, message: 'Telefone deve ter no máximo 20 caracteres' }
                }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Telefone (Opcional)"
                    fullWidth
                    error={!!errors.phoneNumber}
                    helperText={errors.phoneNumber?.message || 'Ex: (11) 99999-9999, +55 11 99999-9999'}
                    placeholder="(11) 99999-9999"
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <PhoneIcon />
                        </InputAdornment>
                      ),
                    }}
                  />
                )}
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <Controller
                name="clinicId"
                control={control}
                render={({ field }) => (
                  <FormControl fullWidth error={!!errors.clinicId}>
                    <InputLabel>Clínica (Opcional)</InputLabel>
                    <Select
                      {...field}
                      label="Clínica (Opcional)"
                      displayEmpty
                    >
                      <MenuItem value="">
                        <em>Nenhuma clínica</em>
                      </MenuItem>
                      {clinics.map((clinic) => (
                        <MenuItem key={clinic.id} value={clinic.id}>
                          {clinic.name}
                        </MenuItem>
                      ))}
                    </Select>
                    {errors.clinicId && (
                      <Typography variant="caption" color="error" sx={{ ml: 2, mt: 0.5 }}>
                        {errors.clinicId.message}
                      </Typography>
                    )}
                  </FormControl>
                )}
              />
            </Grid>

            {!isEditing && (
              <Grid item xs={12}>
                <Controller
                  name="password"
                  control={control}
                  rules={{
                    validate: validatePassword
                  }}
                  render={({ field }) => (
                    <Box>
                      <TextField
                        {...field}
                        label="Senha"
                        type="password"
                        fullWidth
                        required
                        error={!!errors.password}
                        helperText={errors.password?.message || 'Exemplo: MinhaSenh@123'}
                        placeholder="Digite uma senha segura"
                        onChange={(e) => {
                          field.onChange(e)
                          setPasswordValue(e.target.value)
                        }}
                        InputProps={{
                          startAdornment: (
                            <InputAdornment position="start">
                              <LockIcon />
                            </InputAdornment>
                          ),
                        }}
                      />
                      
                      {/* Password strength and criteria indicators */}
                      <Box sx={{ mt: 1, p: 2, backgroundColor: 'grey.50', borderRadius: 1 }}>
                        {passwordValue && (
                          <Box sx={{ mb: 2 }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 0.5 }}>
                              <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 600 }}>
                                Força da senha:
                              </Typography>
                              <Typography 
                                variant="caption" 
                                sx={{ 
                                  fontWeight: 600,
                                  color: getPasswordStrength(passwordValue).score <= 2 ? 'error.main' :
                                         getPasswordStrength(passwordValue).score <= 3 ? 'warning.main' :
                                         getPasswordStrength(passwordValue).score <= 4 ? 'info.main' : 'success.main'
                                }}
                              >
                                {getPasswordStrength(passwordValue).label}
                              </Typography>
                            </Box>
                            <LinearProgress 
                              variant="determinate" 
                              value={getPasswordStrength(passwordValue).percentage}
                              sx={{
                                height: 6,
                                borderRadius: 3,
                                backgroundColor: 'grey.200',
                                '& .MuiLinearProgress-bar': {
                                  borderRadius: 3,
                                  backgroundColor: getPasswordStrength(passwordValue).score <= 2 ? 'error.main' :
                                                  getPasswordStrength(passwordValue).score <= 3 ? 'warning.main' :
                                                  getPasswordStrength(passwordValue).score <= 4 ? 'info.main' : 'success.main'
                                }
                              }}
                            />
                          </Box>
                        )}
                        
                        <Typography variant="caption" color="text.secondary" sx={{ mb: 1, display: 'block', fontWeight: 600 }}>
                          {passwordValue ? 'Requisitos da senha:' : 'Requisitos necessários:'}
                        </Typography>
                        {Object.entries({
                          minLength: 'Mínimo 8 caracteres',
                          hasUppercase: 'Uma letra maiúscula (A-Z)',
                          hasLowercase: 'Uma letra minúscula (a-z)',
                          hasNumber: 'Um número (0-9)',
                          hasSpecial: 'Um caractere especial (!@#$%^&*)',
                        }).map(([key, label]) => {
                          const criteria = getPasswordCriteria(passwordValue)
                          const isValid = criteria[key as keyof typeof criteria]
                          
                          return (
                            <Box key={key} sx={{ display: 'flex', alignItems: 'center', gap: 1, py: 0.25 }}>
                              {isValid ? (
                                <CheckCircleIcon sx={{ fontSize: 16, color: 'success.main' }} />
                              ) : (
                                <CancelIcon sx={{ fontSize: 16, color: 'error.main' }} />
                              )}
                              <Typography 
                                variant="caption" 
                                color={isValid ? 'success.main' : 'text.secondary'}
                                sx={{ fontWeight: isValid ? 500 : 400 }}
                              >
                                {label}
                              </Typography>
                            </Box>
                          )
                        })}
                      </Box>
                    </Box>
                  )}
                />
              </Grid>
            )}

            <Grid item xs={12}>
              <Controller
                name="isActive"
                control={control}
                render={({ field }) => (
                  <FormControlLabel
                    control={
                      <Switch
                        {...field}
                        checked={field.value}
                        color="primary"
                      />
                    }
                    label={
                      <Box>
                        <Typography variant="body1" fontWeight={500}>
                          Paciente ativo
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          {field.value 
                            ? 'Pode usar planos e acessar o sistema'
                            : 'Não pode usar planos nem acessar o sistema'
                          }
                        </Typography>
                      </Box>
                    }
                  />
                )}
              />
            </Grid>
          </Grid>
        </DialogContent>

        <DialogActions sx={{ p: 3, gap: 1 }}>
          <Button
            onClick={handleClose}
            disabled={isLoading}
            color="inherit"
            variant="outlined"
          >
            Cancelar
          </Button>
          <Button
            type="submit"
            variant="contained"
            disabled={!isValid || isLoading}
            sx={{ minWidth: 120 }}
          >
            {isLoading ? 'Salvando...' : isEditing ? 'Atualizar' : 'Criar Paciente'}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  )
}