import React, { useEffect, useState } from 'react'
import {
  Box,
  Grid,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  FormControlLabel,
  Switch,
  Typography,
  CircularProgress,
  Tooltip,
  IconButton,
  Alert,
  Chip,
  FormHelperText
} from '@mui/material'
import { Help, CheckCircle, Warning, Info as InfoIcon } from '@mui/icons-material'
import { useClinicStepper } from '../hooks/useClinicStepper'
import { useInputValidation, useMaskedInput } from '../hooks/useInputValidation'
import { StepComponentProps } from '../../../../types/stepper'
import { ClinicType } from '../../../../types/clinic'
import {
  validateClinicName,
  validateEmail,
  validateCNPJ,
  validatePhone,
  formatCNPJ,
  formatPhone,
  checkClinicNameExists,
  checkCNPJExists
} from '../../../../utils/validation'

/**
 * Step 1: Informações Básicas
 * 
 * Formulário com validação em tempo real, máscaras e auto-complete
 */
function Step1BasicInfo({ onNext, onPrev, isValid, isDirty }: StepComponentProps) {
  const { formData, updateFormData, setStepError, clearStepErrors, validateStep } = useClinicStepper()
  const [formValid, setFormValid] = useState(false)

  // Campo Nome com validação de duplicatas

  const nameField = useInputValidation({
    validator: validateClinicName,
    asyncValidator: checkClinicNameExists,
    asyncErrorMessage: 'Este nome já está em uso',
    debounceMs: 500,
    initialValue: formData.basicInfo.name,
    onValidationChange: (isValid, errors) => {
      if (errors.length > 0) {
        setStepError(0, 'name', errors)
      } else {
        clearStepErrors(0)
      }
    }
  })

  // Campo Email
  const emailField = useInputValidation({
    validator: validateEmail,
    initialValue: formData.basicInfo.email || '',
    onValidationChange: (isValid, errors) => {
      if (errors.length > 0) {
        setStepError(0, 'email', errors)
      }
    }
  })

  // Campo CNPJ com máscara e validação
  const cnpjField = useMaskedInput({
    validator: validateCNPJ,
    asyncValidator: checkCNPJExists,
    asyncErrorMessage: 'Este CNPJ já está cadastrado',
    formatter: formatCNPJ,
    maxLength: 18, // XX.XXX.XXX/XXXX-XX
    debounceMs: 500,
    initialValue: formData.basicInfo.cnpj || '',
    onValidationChange: (isValid, errors) => {
      if (errors.length > 0) {
        setStepError(0, 'cnpj', errors)
      }
    }
  })

  // Campo Telefone com máscara e validação
  const phoneField = useMaskedInput({
    validator: validatePhone,
    formatter: formatPhone,
    maxLength: 15, // (XX) XXXXX-XXXX
    initialValue: formData.basicInfo.phone || '',
    onValidationChange: (isValid, errors) => {
      if (errors.length > 0) {
        setStepError(0, 'phone', errors)
      }
    }
  })

  // Estado do tipo de clínica
  const [clinicType, setClinicType] = useState<ClinicType>(formData.basicInfo.type)
  const [isActive, setIsActive] = useState(formData.basicInfo.isActive)

  // Atualizar dados do formulário quando os campos mudam
  useEffect(() => {
    updateFormData('basicInfo', {
      name: nameField.value,
      email: emailField.value || undefined,
      cnpj: cnpjField.value || undefined,
      phone: phoneField.value || undefined,
      type: clinicType,
      isActive
    })
  }, [
    nameField.value,
    emailField.value,
    cnpjField.value,
    phoneField.value,
    clinicType,
    isActive,
    updateFormData
  ])

  // Validar formulário
  useEffect(() => {
    const isFormValid = nameField.isValid && 
                       (emailField.value === '' || emailField.isValid) && // Email é opcional
                       (cnpjField.value === '' || cnpjField.isValid) && // CNPJ é opcional
                       (phoneField.value === '' || phoneField.isValid) && // Telefone é opcional
                       nameField.value.trim().length >= 3

    setFormValid(isFormValid)
  }, [
    nameField.isValid,
    emailField.isValid,
    emailField.value,
    cnpjField.isValid,
    cnpjField.value,
    phoneField.isValid,
    phoneField.value,
    nameField.value
  ])

  // Atualizar validação global do stepper quando o formulário local muda
  useEffect(() => {
    validateStep(0)
  }, [formValid, validateStep])

  // Note: Auto-complete removed - simple text input now

  // Tooltips para tipos de clínica
  const getClinicTypeTooltip = (type: ClinicType): string => {
    switch (type) {
      case ClinicType.Regular:
        return 'Clínica padrão que pode usar créditos de planos'
      case ClinicType.Origin:
        return 'Clínica origem que vende planos e gera créditos'
      case ClinicType.Partner:
        return 'Clínica parceira que aceita créditos de outras clínicas'
      case ClinicType.Administrative:
        return 'Clínica administrativa para gestão do sistema'
      default:
        return ''
    }
  }

  const getClinicTypeLabel = (type: ClinicType): string => {
    switch (type) {
      case ClinicType.Regular:
        return 'Regular'
      case ClinicType.Origin:
        return 'Origem'
      case ClinicType.Partner:
        return 'Parceira'
      case ClinicType.Administrative:
        return 'Administrativa'
      default:
        return 'Desconhecido'
    }
  }

  const getClinicTypeColor = (type: ClinicType): 'default' | 'primary' | 'secondary' | 'success' => {
    switch (type) {
      case ClinicType.Origin:
        return 'primary'
      case ClinicType.Partner:
        return 'secondary'
      case ClinicType.Administrative:
        return 'success'
      default:
        return 'default'
    }
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h5" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          🏢 Informações Básicas
          {formValid && <CheckCircle color="success" />}
          {!formValid && nameField.touched && <Warning color="warning" />}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Preencha os dados fundamentais da clínica. Campos obrigatórios estão marcados com *.
        </Typography>
      </Box>

      {/* Formulário */}
      <Grid container spacing={3}>
        {/* Nome da Clínica */}
        <Grid item xs={12}>
          <TextField
            fullWidth
            label="Nome da Clínica"
            required
            value={nameField.value}
            onChange={(e) => nameField.setValue(e.target.value)}
            onBlur={nameField.onBlur}
            error={nameField.showErrors}
            helperText={nameField.showErrors ? nameField.errors[0] : 'Nome da clínica'}
            placeholder="Digite o nome da clínica"
            InputProps={{
              endAdornment: nameField.isValidating && <CircularProgress color="inherit" size={20} />
            }}
          />
        </Grid>

        {/* Tipo de Clínica */}
        <Grid item xs={12} md={6}>
          <FormControl fullWidth>
            <InputLabel>Tipo de Clínica *</InputLabel>
            <Select
              value={clinicType}
              label="Tipo de Clínica *"
              onChange={(e) => setClinicType(e.target.value as ClinicType)}
            >
              {Object.values(ClinicType)
                .filter(value => typeof value === 'number' && value !== ClinicType.Origin)
                .map((type) => (
                  <MenuItem key={type} value={type}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, width: '100%' }}>
                      <Chip
                        label={getClinicTypeLabel(type as ClinicType)}
                        color={getClinicTypeColor(type as ClinicType)}
                        size="small"
                      />
                      <Tooltip title={getClinicTypeTooltip(type as ClinicType)}>
                        <IconButton size="small">
                          <Help fontSize="small" />
                        </IconButton>
                      </Tooltip>
                    </Box>
                  </MenuItem>
                ))
              }
            </Select>
            <FormHelperText>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mt: 0.5 }}>
                <InfoIcon fontSize="small" color="primary" />
                <Typography variant="caption" color="text.secondary">
                  Clínicas do tipo "Origem" requerem autorização especial e devem ser criadas por administradores do sistema
                </Typography>
              </Box>
            </FormHelperText>
          </FormControl>
        </Grid>

        {/* Status Ativo */}
        <Grid item xs={12} md={6}>
          <Box sx={{ display: 'flex', alignItems: 'center', height: '56px' }}>
            <FormControlLabel
              control={
                <Switch
                  checked={isActive}
                  onChange={(e) => setIsActive(e.target.checked)}
                  color="primary"
                />
              }
              label="Clínica Ativa"
            />
            <Tooltip title="Define se a clínica está ativa no sistema">
              <IconButton size="small">
                <Help fontSize="small" />
              </IconButton>
            </Tooltip>
          </Box>
        </Grid>

        {/* CNPJ */}
        <Grid item xs={12} md={6}>
          <TextField
            fullWidth
            label="CNPJ"
            value={cnpjField.value}
            onChange={(e) => cnpjField.setValue(e.target.value)}
            onBlur={cnpjField.onBlur}
            error={cnpjField.showErrors}
            helperText={cnpjField.showErrors ? cnpjField.errors[0] : 'Opcional - Formato: XX.XXX.XXX/XXXX-XX'}
            placeholder="00.000.000/0000-00"
            InputProps={{
              endAdornment: cnpjField.isValidating && <CircularProgress color="inherit" size={20} />
            }}
          />
        </Grid>

        {/* Telefone */}
        <Grid item xs={12} md={6}>
          <TextField
            fullWidth
            label="Telefone"
            value={phoneField.value}
            onChange={(e) => phoneField.setValue(e.target.value)}
            onBlur={phoneField.onBlur}
            error={phoneField.showErrors}
            helperText={phoneField.showErrors ? phoneField.errors[0] : 'Opcional - Formato: (XX) XXXXX-XXXX'}
            placeholder="(11) 99999-9999"
          />
        </Grid>

        {/* Email */}
        <Grid item xs={12}>
          <TextField
            fullWidth
            label="Email"
            type="email"
            value={emailField.value}
            onChange={(e) => emailField.setValue(e.target.value)}
            onBlur={emailField.onBlur}
            error={emailField.showErrors}
            helperText={emailField.showErrors ? emailField.errors[0] : 'Opcional - Email de contato da clínica'}
            placeholder="contato@clinica.com.br"
          />
        </Grid>
      </Grid>

      {/* Status do formulário */}
      <Box sx={{ mt: 4 }}>
        {formValid && (
          <Alert severity="success" sx={{ mb: 2 }}>
            ✅ Informações básicas válidas! Você pode prosseguir para o próximo step.
          </Alert>
        )}
        
        {!formValid && nameField.touched && (
          <Alert severity="warning" sx={{ mb: 2 }}>
            ⚠️ Preencha todos os campos obrigatórios para prosseguir.
          </Alert>
        )}

        {/* Indicadores de campos */}
        <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
          <Chip
            label="Nome"
            color={nameField.isValid && nameField.value.length >= 3 ? 'success' : 'default'}
            size="small"
            icon={nameField.isValid && nameField.value.length >= 3 ? <CheckCircle /> : undefined}
          />
          <Chip
            label="Tipo"
            color="success"
            size="small"
            icon={<CheckCircle />}
          />
          <Chip
            label="CNPJ"
            color={cnpjField.value ? (cnpjField.isValid ? 'success' : 'error') : 'default'}
            size="small"
            variant={cnpjField.value ? 'filled' : 'outlined'}
          />
          <Chip
            label="Telefone"
            color={phoneField.value ? (phoneField.isValid ? 'success' : 'error') : 'default'}
            size="small"
            variant={phoneField.value ? 'filled' : 'outlined'}
          />
          <Chip
            label="Email"
            color={emailField.value ? (emailField.isValid ? 'success' : 'error') : 'default'}
            size="small"
            variant={emailField.value ? 'filled' : 'outlined'}
          />
        </Box>
      </Box>
    </Box>
  )
}

export default Step1BasicInfo