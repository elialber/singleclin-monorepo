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
} from '@mui/material'
import { useForm, Controller } from 'react-hook-form'
import { AxiosError } from 'axios'
import { Plan, CreatePlanRequest, UpdatePlanRequest } from '@/types/plan'
import { useCreatePlan, useUpdatePlan } from '@/hooks/usePlans'

interface ValidationError {
  type: string
  title: string
  status: number
  errors: Record<string, string[]>
  traceId: string
}

interface PlanFormData {
  name: string
  description: string
  credits: number
  price: number
  validityDays: number
  isActive: boolean
}

interface PlanFormDialogProps {
  open: boolean
  onClose: () => void
  plan?: Plan | null
}

export default function PlanFormDialog({ open, onClose, plan }: PlanFormDialogProps) {
  const isEditing = Boolean(plan)
  const createPlan = useCreatePlan()
  const updatePlan = useUpdatePlan()

  const {
    control,
    handleSubmit,
    reset,
    setError,
    clearErrors,
    formState: { errors, isValid },
    watch,
  } = useForm<PlanFormData>({
    defaultValues: {
      name: '',
      description: '',
      credits: 1,
      price: 0,
      validityDays: 365,
      isActive: true,
    },
    mode: 'onChange',
  })

  // Watch credits and price for real-time calculation display
  const credits = watch('credits')
  const price = watch('price')
  const pricePerCredit = credits > 0 ? price / credits : 0

  // Function to handle backend validation errors
  const handleBackendValidationErrors = (error: AxiosError<ValidationError>) => {
    if (error.response?.status === 400 && error.response.data?.errors) {
      const backendErrors = error.response.data.errors
      
      // Map backend field names to form field names (case insensitive)
      const fieldMapping: Record<string, keyof PlanFormData> = {
        'name': 'name',
        'description': 'description', 
        'credits': 'credits',
        'price': 'price',
        'validitydays': 'validityDays',
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

  // Reset form when dialog opens/closes or plan changes
  useEffect(() => {
    if (open) {
      if (plan) {
        reset({
          name: plan.name,
          description: plan.description,
          credits: plan.credits,
          price: plan.price,
          validityDays: plan.validityDays,
          isActive: plan.isActive,
        })
      } else {
        reset({
          name: '',
          description: '',
          credits: 1,
          price: 0,
          validityDays: 365,
          isActive: true,
        })
      }
    }
  }, [open, plan, reset])

  const handleClose = () => {
    if (!createPlan.isPending && !updatePlan.isPending) {
      onClose()
    }
  }

  const onSubmit = async (data: PlanFormData) => {
    // Clear any previous errors
    clearErrors()

    if (isEditing && plan) {
      const updateData: UpdatePlanRequest = {
        name: data.name,
        description: data.description,
        credits: data.credits,
        price: data.price,
        originalPrice: undefined,
        validityDays: data.validityDays,
        isActive: data.isActive,
        isFeatured: false,
      }
      updatePlan.mutate({ id: plan.id, data: updateData }, {
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
      const createData: CreatePlanRequest = {
        name: data.name,
        description: data.description,
        credits: data.credits,
        price: data.price,
        originalPrice: undefined,
        validityDays: data.validityDays,
        isActive: data.isActive,
        isFeatured: false,
      }
      createPlan.mutate(createData, {
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

  const isLoading = createPlan.isPending || updatePlan.isPending
  const submitError = createPlan.error || updatePlan.error

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
          {isEditing ? 'Editar Plano' : 'Novo Plano'}
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
          {isEditing 
            ? 'Modifique as informações do plano existente'
            : 'Preencha as informações para criar um novo plano'
          }
        </Typography>
      </DialogTitle>

      <form onSubmit={handleSubmit(onSubmit)}>
        <DialogContent dividers>
          {submitError && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {submitError instanceof Error ? submitError.message : 'Erro ao salvar plano'}
            </Alert>
          )}

          <Grid container spacing={3}>
            <Grid item xs={12}>
              <Controller
                name="name"
                control={control}
                rules={{ 
                  required: 'Nome do plano é obrigatório',
                  minLength: { value: 3, message: 'Nome deve ter pelo menos 3 caracteres' },
                  maxLength: { value: 100, message: 'Nome deve ter no máximo 100 caracteres' },
                  pattern: {
                    value: /^[\w\s\-_.À-ÿ]+$/,
                    message: 'Nome do plano pode conter apenas letras (incluindo acentos), números, espaços, hífens, sublinhados e pontos'
                  }
                }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Nome do Plano"
                    fullWidth
                    error={!!errors.name}
                    helperText={errors.name?.message}
                    placeholder="Ex: Plano Básico, Plano Premium..."
                  />
                )}
              />
            </Grid>

            <Grid item xs={12}>
              <Controller
                name="description"
                control={control}
                rules={{ 
                  minLength: { value: 10, message: 'Descrição deve ter pelo menos 10 caracteres' },
                  maxLength: { value: 1000, message: 'Descrição deve ter no máximo 1000 caracteres' }
                }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Descrição (Opcional)"
                    fullWidth
                    multiline
                    rows={3}
                    error={!!errors.description}
                    helperText={errors.description?.message}
                    placeholder="Descreva os benefícios e características do plano..."
                  />
                )}
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <Controller
                name="credits"
                control={control}
                rules={{ 
                  required: 'Quantidade de créditos é obrigatória',
                  min: { value: 1, message: 'Deve ter pelo menos 1 crédito' },
                  max: { value: 10000, message: 'Não pode exceder 10.000 créditos' }
                }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Créditos"
                    type="number"
                    fullWidth
                    error={!!errors.credits}
                    helperText={errors.credits?.message}
                    onChange={(e) => field.onChange(Number(e.target.value))}
                    InputProps={{
                      inputProps: { min: 1, max: 10000 }
                    }}
                  />
                )}
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <Controller
                name="price"
                control={control}
                rules={{ 
                  required: 'Preço é obrigatório',
                  min: { value: 0, message: 'Preço deve ser maior ou igual a zero' },
                  max: { value: 999999.99, message: 'Preço não pode exceder R$ 999.999,99' }
                }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Preço"
                    type="number"
                    fullWidth
                    error={!!errors.price}
                    helperText={errors.price?.message}
                    onChange={(e) => field.onChange(Number(e.target.value))}
                    InputProps={{
                      startAdornment: <InputAdornment position="start">R$</InputAdornment>,
                      inputProps: { min: 0, max: 999999.99, step: 0.01 }
                    }}
                  />
                )}
              />
            </Grid>


            <Grid item xs={12} sm={6}>
              <Controller
                name="validityDays"
                control={control}
                rules={{ 
                  required: 'Validade em dias é obrigatória',
                  min: { value: 1, message: 'Deve ter pelo menos 1 dia' },
                  max: { value: 3650, message: 'Não pode exceder 10 anos (3650 dias)' }
                }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Validade (dias)"
                    type="number"
                    fullWidth
                    error={!!errors.validityDays}
                    helperText={errors.validityDays?.message || 'Padrão: 365 dias (1 ano)'}
                    onChange={(e) => field.onChange(Number(e.target.value))}
                    InputProps={{
                      inputProps: { min: 1, max: 3650 }
                    }}
                  />
                )}
              />
            </Grid>



            {!isEditing && (
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
                            Plano ativo
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            {field.value 
                              ? 'Disponível para compra pelos clientes'
                              : 'Indisponível para novos clientes'
                            }
                          </Typography>
                        </Box>
                      }
                    />
                  )}
                />
              </Grid>
            )}

            {/* Real-time calculation display */}
            {credits > 0 && price > 0 && (
              <Grid item xs={12}>
                <Box
                  sx={{
                    p: 2,
                    backgroundColor: 'primary.50',
                    borderRadius: 1,
                    border: '1px solid',
                    borderColor: 'primary.200',
                  }}
                >
                  <Typography variant="body2" color="primary.main" fontWeight={500}>
                    💡 Valor por crédito: R$ {pricePerCredit.toFixed(2)}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                    Os clientes pagarão R$ {pricePerCredit.toFixed(2)} por cada crédito utilizado
                  </Typography>
                </Box>
              </Grid>
            )}

            {isEditing && (
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
                            Plano ativo
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            {field.value 
                              ? 'Plano disponível para compra pelos clientes'
                              : 'Plano indisponível para novos clientes'
                            }
                          </Typography>
                        </Box>
                      }
                    />
                  )}
                />
              </Grid>
            )}
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
            {isLoading ? 'Salvando...' : isEditing ? 'Atualizar' : 'Criar Plano'}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  )
}