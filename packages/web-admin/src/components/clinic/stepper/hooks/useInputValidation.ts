import { useState, useEffect, useCallback, useRef } from 'react'
import { debounce } from '../../../../utils/validation'

interface ValidationResult {
  isValid: boolean
  errors: string[]
}

interface UseInputValidationOptions {
  /** Função de validação síncrona */
  validator?: (value: string) => ValidationResult
  
  /** Função de validação assíncrona (ex: verificar duplicatas) */
  asyncValidator?: (value: string) => Promise<boolean>
  
  /** Mensagem de erro para validação assíncrona */
  asyncErrorMessage?: string
  
  /** Delay para validação assíncrona (debounce) */
  debounceMs?: number
  
  /** Validar apenas quando o campo perde o foco */
  validateOnBlur?: boolean
  
  /** Valor inicial */
  initialValue?: string
  
  /** Callback chamado quando a validação muda */
  onValidationChange?: (isValid: boolean, errors: string[]) => void
}

/**
 * Hook para input com validação em tempo real
 */
export function useInputValidation({
  validator,
  asyncValidator,
  asyncErrorMessage = 'Valor já existe',
  debounceMs = 500,
  validateOnBlur = false,
  initialValue = '',
  onValidationChange
}: UseInputValidationOptions) {
  const [value, setValue] = useState(initialValue)
  const [errors, setErrors] = useState<string[]>([])
  const [isValidating, setIsValidating] = useState(false)
  const [touched, setTouched] = useState(false)
  
  const asyncValidatorRef = useRef(asyncValidator)
  asyncValidatorRef.current = asyncValidator
  
  // Validação assíncrona com debounce
  const debouncedAsyncValidation = useCallback(
    debounce(async (val: string) => {
      if (asyncValidatorRef.current && val.trim()) {
        setIsValidating(true)
        try {
          const exists = await asyncValidatorRef.current(val)
          if (exists) {
            setErrors(prev => [...prev.filter(e => e !== asyncErrorMessage), asyncErrorMessage])
          } else {
            setErrors(prev => prev.filter(e => e !== asyncErrorMessage))
          }
        } catch (error) {
          console.error('Async validation error:', error)
        } finally {
          setIsValidating(false)
        }
      }
    }, debounceMs),
    [asyncErrorMessage, debounceMs]
  )
  
  // Validação principal
  const validate = useCallback((val: string) => {
    let newErrors: string[] = []
    
    // Validação síncrona
    if (validator) {
      const result = validator(val)
      newErrors = result.errors
    }
    
    setErrors(newErrors)
    
    // Validação assíncrona (apenas se a validação síncrona passou)
    if (newErrors.length === 0 && asyncValidator && val.trim()) {
      debouncedAsyncValidation(val)
    }
    
    return newErrors.length === 0
  }, [validator, asyncValidator, debouncedAsyncValidation])
  
  // Handler para mudança de valor
  const handleChange = useCallback((newValue: string) => {
    setValue(newValue)
    setTouched(true)
    
    if (!validateOnBlur) {
      validate(newValue)
    }
  }, [validate, validateOnBlur])
  
  // Handler para blur
  const handleBlur = useCallback(() => {
    setTouched(true)
    if (validateOnBlur) {
      validate(value)
    }
  }, [validate, validateOnBlur, value])
  
  // Notificar mudanças de validação
  useEffect(() => {
    if (touched && onValidationChange) {
      const isValid = errors.length === 0 && !isValidating
      onValidationChange(isValid, errors)
    }
  }, [errors, isValidating, touched, onValidationChange])
  
  const isValid = errors.length === 0 && !isValidating
  const showErrors = touched && errors.length > 0
  
  return {
    value,
    setValue: handleChange,
    errors,
    isValid,
    isValidating,
    touched,
    showErrors,
    onBlur: handleBlur,
    reset: () => {
      setValue(initialValue)
      setErrors([])
      setTouched(false)
      setIsValidating(false)
    }
  }
}

interface UseMaskedInputOptions extends UseInputValidationOptions {
  /** Função para aplicar máscara */
  formatter?: (value: string) => string
  
  /** Valor máximo de caracteres */
  maxLength?: number
}

/**
 * Hook para input com máscara e validação
 */
export function useMaskedInput({
  formatter,
  maxLength,
  ...validationOptions
}: UseMaskedInputOptions) {
  const validation = useInputValidation(validationOptions)
  
  const handleChange = useCallback((newValue: string) => {
    let formattedValue = newValue
    
    // Aplicar limitação de caracteres
    if (maxLength && formattedValue.length > maxLength) {
      formattedValue = formattedValue.slice(0, maxLength)
    }
    
    // Aplicar máscara
    if (formatter) {
      formattedValue = formatter(formattedValue)
    }
    
    validation.setValue(formattedValue)
  }, [formatter, maxLength, validation])
  
  return {
    ...validation,
    setValue: handleChange
  }
}

interface UseAutoCompleteOptions {
  /** Função para buscar sugestões */
  getSuggestions: (query: string) => Promise<string[]>
  
  /** Delay para busca (debounce) */
  debounceMs?: number
  
  /** Número mínimo de caracteres para buscar */
  minChars?: number
  
  /** Número máximo de sugestões */
  maxSuggestions?: number
}

/**
 * Hook para auto-complete
 */
export function useAutoComplete({
  getSuggestions,
  debounceMs = 300,
  minChars = 2,
  maxSuggestions = 5
}: UseAutoCompleteOptions) {
  const [suggestions, setSuggestions] = useState<string[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [showSuggestions, setShowSuggestions] = useState(false)
  
  const getSuggestionsRef = useRef(getSuggestions)
  getSuggestionsRef.current = getSuggestions
  
  const debouncedSearch = useCallback(
    debounce(async (query: string) => {
      if (query.length >= minChars) {
        setIsLoading(true)
        try {
          const results = await getSuggestionsRef.current(query)
          setSuggestions(results.slice(0, maxSuggestions))
          setShowSuggestions(true)
        } catch (error) {
          console.error('Auto-complete search error:', error)
          setSuggestions([])
        } finally {
          setIsLoading(false)
        }
      } else {
        setSuggestions([])
        setShowSuggestions(false)
      }
    }, debounceMs),
    [debounceMs, minChars, maxSuggestions]
  )
  
  const search = useCallback((query: string) => {
    if (query.length === 0) {
      setSuggestions([])
      setShowSuggestions(false)
      return
    }
    
    debouncedSearch(query)
  }, [debouncedSearch])
  
  const selectSuggestion = useCallback((suggestion: string) => {
    setSuggestions([])
    setShowSuggestions(false)
    return suggestion
  }, [])
  
  const hideSuggestions = useCallback(() => {
    setShowSuggestions(false)
  }, [])
  
  return {
    suggestions,
    isLoading,
    showSuggestions,
    search,
    selectSuggestion,
    hideSuggestions
  }
}