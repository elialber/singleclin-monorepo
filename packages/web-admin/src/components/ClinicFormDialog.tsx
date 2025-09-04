import { useEffect, useState } from 'react'
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
  Divider,
} from '@mui/material'
import {
  LocationOn as LocationIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  Business as BusinessIcon,
} from '@mui/icons-material'
import { useForm, Controller } from 'react-hook-form'
import { AxiosError } from 'axios'
import { Clinic, CreateClinicRequest, UpdateClinicRequest, ClinicType, getClinicTypeLabel } from '@/types/clinic'
import { useCreateClinic, useUpdateClinic } from '@/hooks/useClinics'
import { useImageUpload } from '@/hooks/useImageUpload'
import ImageUpload from './ImageUpload'

interface ValidationError {
  type: string
  title: string
  status: number
  errors: Record<string, string[]>
  traceId: string
}

interface ClinicFormData {
  name: string
  type: ClinicType
  address: string
  phoneNumber: string
  email: string
  cnpj: string
  isActive: boolean
}

interface ClinicFormDialogProps {
  open: boolean
  onClose: () => void
  clinic?: Clinic | null
}

export default function ClinicFormDialog({ open, onClose, clinic }: ClinicFormDialogProps) {
  const isEditing = Boolean(clinic)
  const createClinic = useCreateClinic()
  const updateClinic = useUpdateClinic()
  const [pendingImageFile, setPendingImageFile] = useState<File | null>(null)

  const { uploadImage, deleteImage, loading: imageLoading, error: imageError, clearError: clearImageError } = useImageUpload({
    onSuccess: () => {
      clearImageError()
    },
    onError: (error) => {
      console.error('Image upload error:', error)
    }
  })

  const {
    control,
    handleSubmit,
    reset,
    setError,
    clearErrors,
    formState: { errors, isValid },
  } = useForm<ClinicFormData>({
    defaultValues: {
      name: '',
      type: ClinicType.Regular,
      address: '',
      phoneNumber: '',
      email: '',
      cnpj: '',
      isActive: true,
    },
    mode: 'onChange',
  })


  // Function to handle backend validation errors
  const handleBackendValidationErrors = (error: AxiosError<ValidationError>) => {
    if (error.response?.status === 400 && error.response.data?.errors) {
      const backendErrors = error.response.data.errors
      
      // Map backend field names to form field names (case insensitive)
      const fieldMapping: Record<string, keyof ClinicFormData> = {
        'name': 'name',
        'type': 'type',
        'address': 'address',
        'phonenumber': 'phoneNumber',
        'email': 'email',
        'cnpj': 'cnpj',
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

  // Reset form when dialog opens/closes or clinic changes
  useEffect(() => {
    if (open) {
      if (clinic) {
        reset({
          name: clinic.name,
          type: clinic.type,
          address: clinic.address,
          phoneNumber: clinic.phoneNumber || '',
          email: clinic.email || '',
          cnpj: clinic.cnpj || '',
          isActive: clinic.isActive,
        })
      } else {
        reset({
          name: '',
          type: ClinicType.Regular,
          address: '',
          phoneNumber: '',
          email: '',
          cnpj: '',
          isActive: true,
        })
      }
      // Reset image state
      setPendingImageFile(null)
      clearImageError()
    }
  }, [open, clinic, reset, clearImageError])

  const handleClose = () => {
    if (!createClinic.isPending && !updateClinic.isPending && !imageLoading) {
      onClose()
    }
  }

  const handleImageUpload = (file: File) => {
    setPendingImageFile(file)
    clearImageError()
  }

  const handleImageDelete = async () => {
    if (isEditing && clinic?.id && clinic.hasImage) {
      try {
        await deleteImage(clinic.id)
      } catch (error) {
        console.error('Error deleting image:', error)
      }
    }
    setPendingImageFile(null)
  }

  const onSubmit = async (data: ClinicFormData) => {
    // Clear any previous errors
    clearErrors()

    if (isEditing && clinic) {
      const updateData: UpdateClinicRequest = {
        name: data.name,
        type: data.type,
        address: data.address,
        phoneNumber: data.phoneNumber || undefined,
        email: data.email || undefined,
        cnpj: data.cnpj || undefined,
        isActive: data.isActive,
      }
      updateClinic.mutate({ id: clinic.id, data: updateData }, {
        onSuccess: async () => {
          // Upload image if there's a pending file
          if (pendingImageFile) {
            try {
              await uploadImage(clinic.id, { image: pendingImageFile })
            } catch (error) {
              console.error('Error uploading image after clinic update:', error)
            }
          }
          onClose()
        },
        onError: (error: any) => {
          if (error.response?.status === 400 && error.response.data?.errors) {
            handleBackendValidationErrors(error)
          }
        }
      })
    } else {
      const createData: CreateClinicRequest = {
        name: data.name,
        type: data.type,
        address: data.address,
        phoneNumber: data.phoneNumber || undefined,
        email: data.email || undefined,
        cnpj: data.cnpj || undefined,
        isActive: data.isActive,
      }
      createClinic.mutate(createData, {
        onSuccess: async (createdClinic) => {
          // Upload image if there's a pending file
          if (pendingImageFile && createdClinic.id) {
            try {
              await uploadImage(createdClinic.id, { image: pendingImageFile })
            } catch (error) {
              console.error('Error uploading image after clinic creation:', error)
            }
          }
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

  const isLoading = createClinic.isPending || updateClinic.isPending || imageLoading
  const submitError = createClinic.error || updateClinic.error || imageError

  // CNPJ validation regex
  const cnpjRegex = /^\d{2}\.\d{3}\.\d{3}\/\d{4}\-\d{2}$|^\d{14}$/

  // Phone validation regex  
  const phoneRegex = /^\+?[\d\s\-\(\)]+$/

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
          {isEditing ? 'Editar Clínica' : 'Nova Clínica'}
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
          {isEditing 
            ? 'Modifique as informações da clínica existente'
            : 'Preencha as informações para criar uma nova clínica'
          }
        </Typography>
      </DialogTitle>

      <form onSubmit={handleSubmit(onSubmit)}>
        <DialogContent dividers>
          {submitError && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {submitError instanceof Error ? submitError.message : 'Erro ao salvar clínica'}
            </Alert>
          )}

          <Grid container spacing={3}>
            <Grid item xs={12}>
              <Controller
                name="name"
                control={control}
                rules={{ 
                  required: 'Nome da clínica é obrigatório',
                  minLength: { value: 2, message: 'Nome deve ter pelo menos 2 caracteres' },
                  maxLength: { value: 100, message: 'Nome deve ter no máximo 100 caracteres' },
                }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Nome da Clínica"
                    fullWidth
                    error={!!errors.name}
                    helperText={errors.name?.message}
                    placeholder="Ex: Clínica Saúde Total, Centro Médico Vida..."
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <BusinessIcon />
                        </InputAdornment>
                      ),
                    }}
                  />
                )}
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <Controller
                name="type"
                control={control}
                rules={{ required: 'Tipo da clínica é obrigatório' }}
                render={({ field }) => (
                  <FormControl fullWidth error={!!errors.type}>
                    <InputLabel>Tipo da Clínica</InputLabel>
                    <Select
                      {...field}
                      label="Tipo da Clínica"
                    >
                      <MenuItem value={ClinicType.Regular}>
                        {getClinicTypeLabel(ClinicType.Regular)}
                      </MenuItem>
                      <MenuItem value={ClinicType.Origin}>
                        {getClinicTypeLabel(ClinicType.Origin)}
                      </MenuItem>
                      <MenuItem value={ClinicType.Partner}>
                        {getClinicTypeLabel(ClinicType.Partner)}
                      </MenuItem>
                      <MenuItem value={ClinicType.Administrative}>
                        {getClinicTypeLabel(ClinicType.Administrative)}
                      </MenuItem>
                    </Select>
                    {errors.type && (
                      <Typography variant="caption" color="error" sx={{ ml: 2, mt: 0.5 }}>
                        {errors.type.message}
                      </Typography>
                    )}
                  </FormControl>
                )}
              />
            </Grid>

            <Grid item xs={12} sm={6}>
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
                          Clínica ativa
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          {field.value 
                            ? 'Disponível no sistema'
                            : 'Indisponível no sistema'
                          }
                        </Typography>
                      </Box>
                    }
                  />
                )}
              />
            </Grid>

            <Grid item xs={12}>
              <Controller
                name="address"
                control={control}
                rules={{ 
                  required: 'Endereço é obrigatório',
                  minLength: { value: 10, message: 'Endereço deve ter pelo menos 10 caracteres' },
                  maxLength: { value: 500, message: 'Endereço deve ter no máximo 500 caracteres' }
                }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Endereço"
                    fullWidth
                    multiline
                    rows={2}
                    error={!!errors.address}
                    helperText={errors.address?.message}
                    placeholder="Rua, número, bairro, cidade, estado, CEP..."
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <LocationIcon />
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
                    value: phoneRegex,
                    message: 'Formato de telefone inválido'
                  },
                  maxLength: { value: 20, message: 'Telefone deve ter no máximo 20 caracteres' }
                }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Telefone (Opcional)"
                    fullWidth
                    error={!!errors.phoneNumber}
                    helperText={errors.phoneNumber?.message || 'Ex: (11) 3456-7890, (11) 99999-9999'}
                    placeholder="(11) 3456-7890"
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
                name="email"
                control={control}
                rules={{
                  pattern: {
                    value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
                    message: 'Formato de email inválido'
                  },
                  maxLength: { value: 100, message: 'Email deve ter no máximo 100 caracteres' }
                }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Email (Opcional)"
                    fullWidth
                    type="email"
                    error={!!errors.email}
                    helperText={errors.email?.message}
                    placeholder="contato@clinica.com.br"
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
                name="cnpj"
                control={control}
                rules={{
                  pattern: {
                    value: cnpjRegex,
                    message: 'CNPJ deve estar no formato XX.XXX.XXX/XXXX-XX ou apenas números'
                  },
                  maxLength: { value: 18, message: 'CNPJ deve ter no máximo 18 caracteres' }
                }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="CNPJ (Opcional)"
                    fullWidth
                    error={!!errors.cnpj}
                    helperText={errors.cnpj?.message || 'Formato: XX.XXX.XXX/XXXX-XX'}
                    placeholder="12.345.678/0001-90"
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <BusinessIcon />
                        </InputAdornment>
                      ),
                    }}
                  />
                )}
              />
            </Grid>

            {/* Image Upload Section */}
            <Grid item xs={12}>
              <Divider sx={{ my: 2 }} />
              <Typography variant="h6" gutterBottom>
                Imagem da Clínica
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Faça upload do logotipo ou imagem representativa da clínica (opcional)
              </Typography>
              
              <ImageUpload
                currentImageUrl={clinic?.imageUrl}
                onImageUpload={handleImageUpload}
                onImageDelete={handleImageDelete}
                loading={imageLoading}
                error={imageError || undefined}
                disabled={isLoading}
                label="Imagem da Clínica"
                helperText="Formatos aceitos: JPEG, PNG, WebP • Tamanho máximo: 5MB"
                variant="standard"
                size="medium"
                showPreview={true}
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
            {isLoading ? 'Salvando...' : isEditing ? 'Atualizar' : 'Criar Clínica'}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  )
}