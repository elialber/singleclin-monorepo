import { useState, useEffect, useCallback } from 'react'

export interface ValidationRule {
  required?: boolean
  minLength?: number
  maxLength?: number
  min?: number
  max?: number
  pattern?: RegExp
  custom?: (value: any) => string | null
}

export interface FieldValidation {
  isValid: boolean
  error: string | null
  touched: boolean
}

export interface FormValidation<T = Record<string, any>> {
  values: T
  errors: Record<keyof T, string | null>
  touched: Record<keyof T, boolean>
  isValid: boolean
  isSubmitting: boolean
}

export type ValidationSchema<T = Record<string, any>> = {
  [K in keyof T]?: ValidationRule
}

/**
 * Hook para validação de formulários em tempo real
 * Oferece validação instantânea, mensagens contextuais e gerenciamento de estado
 */
export function useFormValidation<T extends Record<string, any>>(
  initialValues: T,
  validationSchema: ValidationSchema<T>,
  options: {
    validateOnChange?: boolean
    validateOnBlur?: boolean
    debounceMs?: number
  } = {}
) {
  const {
    validateOnChange = true,
    validateOnBlur = true,
    debounceMs = 300
  } = options

  const [values, setValues] = useState<T>(initialValues)
  const [errors, setErrors] = useState<Record<keyof T, string | null>>({} as Record<keyof T, string | null>)
  const [touched, setTouched] = useState<Record<keyof T, boolean>>({} as Record<keyof T, boolean>)
  const [isSubmitting, setIsSubmitting] = useState(false)

  // Debounced validation
  const [validationTimeout, setValidationTimeout] = useState<NodeJS.Timeout>()

  const validateField = useCallback((field: keyof T, value: any): string | null => {
    const rules = validationSchema[field]
    if (!rules) return null

    // Required validation
    if (rules.required && (value === undefined || value === null || value === '')) {
      return 'Este campo é obrigatório'
    }

    // Skip other validations if field is empty and not required
    if (!rules.required && (value === undefined || value === null || value === '')) {
      return null
    }

    // String validations
    if (typeof value === 'string') {
      if (rules.minLength && value.length < rules.minLength) {
        return `Mínimo de ${rules.minLength} caracteres`
      }
      if (rules.maxLength && value.length > rules.maxLength) {
        return `Máximo de ${rules.maxLength} caracteres`
      }
      if (rules.pattern && !rules.pattern.test(value)) {
        return 'Formato inválido'
      }
    }

    // Number validations
    if (typeof value === 'number') {
      if (rules.min !== undefined && value < rules.min) {
        return `Valor mínimo: ${rules.min}`
      }
      if (rules.max !== undefined && value > rules.max) {
        return `Valor máximo: ${rules.max}`
      }
    }

    // Custom validation
    if (rules.custom) {
      return rules.custom(value)
    }

    return null
  }, [validationSchema])

  const validateAllFields = useCallback(() => {
    const newErrors = {} as Record<keyof T, string | null>
    let hasErrors = false

    Object.keys(values).forEach((field) => {
      const error = validateField(field as keyof T, values[field as keyof T])
      newErrors[field as keyof T] = error
      if (error) hasErrors = true
    })

    setErrors(newErrors)
    return !hasErrors
  }, [values, validateField])

  const debouncedValidateField = useCallback((field: keyof T, value: any) => {
    if (validationTimeout) {
      clearTimeout(validationTimeout)
    }

    setValidationTimeout(setTimeout(() => {
      const error = validateField(field, value)
      setErrors(prev => ({ ...prev, [field]: error }))
    }, debounceMs))
  }, [validateField, debounceMs, validationTimeout])

  const setValue = useCallback((field: keyof T, value: any) => {
    setValues(prev => ({ ...prev, [field]: value }))
    
    if (validateOnChange) {
      debouncedValidateField(field, value)
    }
  }, [validateOnChange, debouncedValidateField])

  const setFieldTouched = useCallback((field: keyof T, isTouched = true) => {
    setTouched(prev => ({ ...prev, [field]: isTouched }))
    
    if (validateOnBlur && isTouched) {
      const error = validateField(field, values[field])
      setErrors(prev => ({ ...prev, [field]: error }))
    }
  }, [validateOnBlur, validateField, values])

  const handleChange = useCallback((field: keyof T) => 
    (event: React.ChangeEvent<HTMLInputElement>) => {
      const value = event.target.type === 'checkbox' 
        ? event.target.checked 
        : event.target.type === 'number'
        ? parseFloat(event.target.value) || 0
        : event.target.value
      setValue(field, value)
    }, [setValue])

  const handleBlur = useCallback((field: keyof T) => 
    () => setFieldTouched(field), [setFieldTouched])

  const reset = useCallback((newValues?: Partial<T>) => {
    const resetValues = { ...initialValues, ...newValues }
    setValues(resetValues as T)
    setErrors({} as Record<keyof T, string | null>)
    setTouched({} as Record<keyof T, boolean>)
    setIsSubmitting(false)
  }, [initialValues])

  const submit = useCallback(async (onSubmit: (values: T) => Promise<void> | void) => {
    setIsSubmitting(true)
    
    // Mark all fields as touched
    const allTouched = Object.keys(values).reduce((acc, key) => {
      acc[key as keyof T] = true
      return acc
    }, {} as Record<keyof T, boolean>)
    setTouched(allTouched)

    // Validate all fields
    const isValid = validateAllFields()
    
    if (isValid) {
      try {
        await onSubmit(values)
      } catch (error) {
        // Error handling is done by the caller
      }
    }
    
    setIsSubmitting(false)
    return isValid
  }, [values, validateAllFields])

  // Calculate overall form validity
  const isValid = Object.values(errors).every(error => error === null) && 
                   Object.keys(validationSchema).every(field => 
                     validationSchema[field as keyof T]?.required ? 
                     values[field as keyof T] !== undefined && values[field as keyof T] !== null && values[field as keyof T] !== '' : 
                     true
                   )

  return {
    values,
    errors,
    touched,
    isValid,
    isSubmitting,
    setValue,
    setFieldTouched,
    handleChange,
    handleBlur,
    validateAllFields,
    reset,
    submit,
    // Field-specific helpers
    getFieldProps: (field: keyof T) => ({
      value: values[field] || '',
      onChange: handleChange(field),
      onBlur: handleBlur(field),
      error: touched[field] && !!errors[field],
      helperText: touched[field] ? errors[field] : undefined,
    }),
    // Field validation status
    getFieldStatus: (field: keyof T): FieldValidation => ({
      isValid: !errors[field],
      error: errors[field],
      touched: touched[field] || false,
    })
  }
}

// Validation rule presets for common use cases
export const ValidationRules = {
  required: { required: true },
  
  email: {
    required: true,
    pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
    custom: (value: string) => {
      if (value && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
        return 'Insira um email válido'
      }
      return null
    }
  },
  
  phone: {
    pattern: /^\(\d{2}\)\s\d{4,5}-\d{4}$/,
    custom: (value: string) => {
      if (value && !/^\(\d{2}\)\s\d{4,5}-\d{4}$/.test(value)) {
        return 'Formato: (XX) XXXXX-XXXX'
      }
      return null
    }
  },
  
  cpf: {
    pattern: /^\d{3}\.\d{3}\.\d{3}-\d{2}$/,
    custom: (value: string) => {
      if (value && !/^\d{3}\.\d{3}\.\d{3}-\d{2}$/.test(value)) {
        return 'Formato: XXX.XXX.XXX-XX'
      }
      return null
    }
  },
  
  cnpj: {
    pattern: /^\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}$/,
    custom: (value: string) => {
      if (value && !/^\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}$/.test(value)) {
        return 'Formato: XX.XXX.XXX/XXXX-XX'
      }
      return null
    }
  },
  
  currency: {
    min: 0,
    custom: (value: number) => {
      if (value < 0) {
        return 'O valor deve ser positivo'
      }
      if (!Number.isFinite(value)) {
        return 'Insira um valor válido'
      }
      return null
    }
  },
  
  positiveNumber: {
    min: 1,
    custom: (value: number) => {
      if (value <= 0) {
        return 'O valor deve ser maior que zero'
      }
      return null
    }
  },
  
  transactionReason: {
    required: true,
    minLength: 3,
    maxLength: 500,
    custom: (value: string) => {
      if (!value?.trim()) return 'Motivo é obrigatório'
      if (value.trim().length < 3) return 'Mínimo de 3 caracteres'
      if (value.trim().length > 500) return 'Máximo de 500 caracteres'
      
      // Check for generic reasons
      const genericReasons = ['erro', 'error', 'cancel', 'cancelar', 'test', 'teste', 'wrong', 'errado']
      if (genericReasons.some(generic => 
        value.toLowerCase().includes(generic) && value.trim().length < 10
      )) {
        return 'Por favor, forneça um motivo mais específico'
      }
      
      return null
    }
  }
}