import { useState, useEffect, useCallback } from 'react'
import { useForm } from 'react-hook-form'
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  FormHelperText,
  InputAdornment,
  Box,
  Typography,
  IconButton,
} from '@mui/material'
import { Close, AttachMoney } from '@mui/icons-material'
import { Plan, CreatePlanRequest } from '@/types/plan'
import { clinicService } from '@/services/clinic.service'
import { useNotification } from "@/contexts/NotificationContext"

interface PlanDialogProps {
  open: boolean
  onClose: () => void
  onSubmit: (data: CreatePlanRequest) => Promise<void>
  plan?: Plan | null
  loading?: boolean
}

interface FormData extends CreatePlanRequest {
  clinicId: string
}

export default function PlanDialog({
  open,
  onClose,
  onSubmit,
  plan,
  loading = false,
}: PlanDialogProps) {
  const [clinicOptions, setClinicOptions] = useState<Array<{ id: string; name: string }>>([])
  const [loadingClinics, setLoadingClinics] = useState(false)
  const { showError } = useNotification()

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
    setValue,
    watch,
  } = useForm<FormData>({
    defaultValues: {
      name: '',
      description: '',
      credits: 0,
      price: 0,
      clinicId: '',
    },
  })

  const isEdit = !!plan

  const loadClinics = useCallback(async () => {
    try {
      setLoadingClinics(true)
      const options = await clinicService.getClinicOptions()
      setClinicOptions([{ id: '', name: 'Nenhuma clínica específica' }, ...options])
    } catch (error) {
      console.error('Error loading clinics:', error)
      showError('Erro ao carregar clínicas')
    } finally {
      setLoadingClinics(false)
    }
  }, [showError])

  useEffect(() => {
    if (open) {
      loadClinics()
      if (plan) {
        setValue('name', plan.name)
        setValue('description', plan.description)
        setValue('credits', plan.credits)
        setValue('price', plan.price)
        setValue('clinicId', plan.clinicId || '')
      } else {
        reset()
      }
    }
  }, [open, plan, setValue, reset, loadClinics])

  const handleFormSubmit = async (data: FormData) => {
    try {
      const submitData = {
        ...data,
        clinicId: data.clinicId || undefined, // Convert empty string to undefined
      }
      await onSubmit(submitData)
      onClose()
    } catch (error) {
      // Error handling is done in parent component
    }
  }

  const handleClose = () => {
    if (!loading) {
      onClose()
    }
  }

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
      <DialogTitle sx={{ m: 0, p: 2, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <Typography variant="h6" component="div">
          {isEdit ? 'Editar Plano' : 'Novo Plano'}
        </Typography>
        <IconButton
          aria-label="close"
          onClick={handleClose}
          sx={{ color: 'grey.500' }}
          disabled={loading}
        >
          <Close />
        </IconButton>
      </DialogTitle>

      <Box component="form" onSubmit={handleSubmit(handleFormSubmit)}>
        <DialogContent dividers>
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <TextField
                {...register('name', {
                  required: 'Nome é obrigatório',
                  minLength: {
                    value: 3,
                    message: 'Nome deve ter pelo menos 3 caracteres',
                  },
                })}
                label="Nome do Plano"
                fullWidth
                error={!!errors.name}
                helperText={errors.name?.message}
                disabled={loading}
              />
            </Grid>

            <Grid item xs={12}>
              <TextField
                {...register('description', {
                  required: 'Descrição é obrigatória',
                  minLength: {
                    value: 10,
                    message: 'Descrição deve ter pelo menos 10 caracteres',
                  },
                })}
                label="Descrição"
                fullWidth
                multiline
                rows={3}
                error={!!errors.description}
                helperText={errors.description?.message}
                disabled={loading}
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <TextField
                {...register('credits', {
                  required: 'Créditos são obrigatórios',
                  min: {
                    value: 1,
                    message: 'Créditos devem ser maior que 0',
                  },
                  max: {
                    value: 1000,
                    message: 'Créditos não podem exceder 1000',
                  },
                })}
                label="Créditos"
                type="number"
                fullWidth
                error={!!errors.credits}
                helperText={errors.credits?.message}
                disabled={loading}
                inputProps={{ min: 1, max: 1000 }}
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <TextField
                {...register('price', {
                  required: 'Preço é obrigatório',
                  min: {
                    value: 0.01,
                    message: 'Preço deve ser maior que 0',
                  },
                  max: {
                    value: 999999.99,
                    message: 'Preço muito alto',
                  },
                })}
                label="Preço"
                type="number"
                fullWidth
                error={!!errors.price}
                helperText={errors.price?.message}
                disabled={loading}
                inputProps={{ 
                  min: 0.01, 
                  max: 999999.99, 
                  step: 0.01 
                }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <AttachMoney />
                    </InputAdornment>
                  ),
                }}
              />
            </Grid>

            <Grid item xs={12}>
              <FormControl fullWidth error={!!errors.clinicId}>
                <InputLabel id="clinic-select-label">
                  Clínica {loadingClinics && '(Carregando...)'}
                </InputLabel>
                <Select
                  {...register('clinicId')}
                  labelId="clinic-select-label"
                  label={`Clínica ${loadingClinics ? '(Carregando...)' : ''}`}
                  value={watch('clinicId') || ''}
                  onChange={(e) => setValue('clinicId', e.target.value)}
                  disabled={loading || loadingClinics}
                >
                  {clinicOptions.map((clinic) => (
                    <MenuItem key={clinic.id} value={clinic.id}>
                      {clinic.name}
                    </MenuItem>
                  ))}
                </Select>
                {errors.clinicId && (
                  <FormHelperText>{errors.clinicId.message}</FormHelperText>
                )}
              </FormControl>
            </Grid>
          </Grid>
        </DialogContent>

        <DialogActions sx={{ px: 3, py: 2, gap: 1 }}>
          <Button 
            onClick={handleClose} 
            variant="outlined"
            disabled={loading}
          >
            Cancelar
          </Button>
          <Button 
            type="submit"
            variant="contained"
            disabled={loading}
          >
            {loading ? 'Salvando...' : (isEdit ? 'Atualizar' : 'Criar')}
          </Button>
        </DialogActions>
      </Box>
    </Dialog>
  )
}