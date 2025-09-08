import React, { createContext, useContext, useReducer, useCallback, useEffect } from 'react'
import {
  StepperState,
  StepperContextValue,
  StepperProviderProps,
  ClinicFormData,
  StepperErrors,
  BasicInfoData,
  AddressData,
  LocationData,
  ServiceData,
  ImageData,
  PREDEFINED_SERVICES
} from '../../../../types/stepper'
import { ClinicType } from '../../../../types/clinic'

// Actions do reducer
type StepperAction =
  | { type: 'SET_CURRENT_STEP'; payload: number }
  | { type: 'NEXT_STEP' }
  | { type: 'PREV_STEP' }
  | { type: 'UPDATE_FORM_DATA'; payload: { section: keyof ClinicFormData; data: any } }
  | { type: 'SET_STEP_VALID'; payload: { stepIndex: number; isValid: boolean } }
  | { type: 'SET_STEP_DIRTY'; payload: { stepIndex: number; isDirty: boolean } }
  | { type: 'SET_STEP_ERROR'; payload: { stepIndex: number; field: string; errors: string[] } }
  | { type: 'CLEAR_STEP_ERRORS'; payload: number }
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'RESET_STEPPER' }

// Estado inicial
const initialFormData: ClinicFormData = {
  basicInfo: {
    name: '',
    type: ClinicType.Regular,
    cnpj: '',
    phone: '',
    email: '',
    isActive: true
  },
  address: {
    cep: '',
    street: '',
    number: '',
    complement: '',
    neighborhood: '',
    city: '',
    state: ''
  },
  location: {
    latitude: -14.235, // Centro do Brasil
    longitude: -51.9253,
    accuracy: 0,
    source: 'user'
  },
  services: {
    selectedServices: PREDEFINED_SERVICES.map(service => ({ ...service }))
  },
  images: [],
  metadata: {
    createdAt: new Date(),
    updatedAt: new Date(),
    completedSteps: [],
    timeSpentPerStep: [0, 0, 0, 0, 0],
    totalTime: 0
  }
}

const initialState: StepperState = {
  currentStep: 0,
  totalSteps: 5,
  isValid: [false, false, true, false, false], // Step 2 (services) começa como válido pois tem serviços pré-selecionados
  isDirty: [false, false, false, false, false],
  formData: initialFormData,
  errors: {},
  isLoading: false
}

// Reducer
function stepperReducer(state: StepperState, action: StepperAction): StepperState {
  switch (action.type) {
    case 'SET_CURRENT_STEP':
      return {
        ...state,
        currentStep: Math.max(0, Math.min(action.payload, state.totalSteps - 1))
      }

    case 'NEXT_STEP':
      return {
        ...state,
        currentStep: Math.min(state.currentStep + 1, state.totalSteps - 1)
      }

    case 'PREV_STEP':
      return {
        ...state,
        currentStep: Math.max(state.currentStep - 1, 0)
      }

    case 'UPDATE_FORM_DATA':
      return {
        ...state,
        formData: {
          ...state.formData,
          [action.payload.section]: action.payload.section === 'images' 
            ? action.payload.data // Para images, substituir completamente
            : {
                ...state.formData[action.payload.section],
                ...action.payload.data
              },
          metadata: {
            ...state.formData.metadata,
            updatedAt: new Date()
          }
        }
      }

    case 'SET_STEP_VALID':
      const newIsValid = [...state.isValid]
      newIsValid[action.payload.stepIndex] = action.payload.isValid
      return {
        ...state,
        isValid: newIsValid
      }

    case 'SET_STEP_DIRTY':
      const newIsDirty = [...state.isDirty]
      newIsDirty[action.payload.stepIndex] = action.payload.isDirty
      return {
        ...state,
        isDirty: newIsDirty
      }

    case 'SET_STEP_ERROR':
      const stepErrors = state.errors[action.payload.stepIndex] || {}
      return {
        ...state,
        errors: {
          ...state.errors,
          [action.payload.stepIndex]: {
            ...stepErrors,
            [action.payload.field]: action.payload.errors
          }
        }
      }

    case 'CLEAR_STEP_ERRORS':
      const newErrors = { ...state.errors }
      delete newErrors[action.payload]
      return {
        ...state,
        errors: newErrors
      }

    case 'SET_LOADING':
      return {
        ...state,
        isLoading: action.payload
      }


    case 'RESET_STEPPER':
      return {
        ...initialState,
        formData: {
          ...initialFormData,
          metadata: {
            ...initialFormData.metadata,
            createdAt: new Date(),
            updatedAt: new Date()
          }
        }
      }

    default:
      return state
  }
}

// Context
const StepperContext = createContext<StepperContextValue | undefined>(undefined)

// Provider component
export function StepperProvider({
  children,
  initialData,
  onSubmit,
  onStepChange,
  onError
}: StepperProviderProps) {
  const [state, dispatch] = useReducer(stepperReducer, {
    ...initialState,
    formData: initialData ? { ...initialFormData, ...initialData } : initialFormData
  })

  // Notificar mudança de step
  useEffect(() => {
    onStepChange?.(state.currentStep)
  }, [state.currentStep, onStepChange])

  // Navegação
  const nextStep = useCallback(() => {
    if (state.currentStep < state.totalSteps - 1) {
      dispatch({ type: 'NEXT_STEP' })
    }
  }, [state.currentStep, state.totalSteps])

  const prevStep = useCallback(() => {
    if (state.currentStep > 0) {
      dispatch({ type: 'PREV_STEP' })
    }
  }, [state.currentStep])

  const goToStep = useCallback((stepIndex: number) => {
    if (stepIndex >= 0 && stepIndex < state.totalSteps) {
      dispatch({ type: 'SET_CURRENT_STEP', payload: stepIndex })
    }
  }, [state.totalSteps])

  // Atualização de dados
  const updateFormData = useCallback(<T extends keyof ClinicFormData>(
    section: T,
    data: Partial<ClinicFormData[T]>
  ) => {
    dispatch({
      type: 'UPDATE_FORM_DATA',
      payload: { section, data }
    })
    
    // Marcar step como dirty
    const stepIndex = getStepIndexForSection(section)
    if (stepIndex !== -1) {
      dispatch({
        type: 'SET_STEP_DIRTY',
        payload: { stepIndex, isDirty: true }
      })
    }
  }, [])

  // Validação
  const validateStep = useCallback(async (stepIndex: number): Promise<boolean> => {
    try {
      // Implementar validação específica por step
      let isValid = false
      
      switch (stepIndex) {
        case 0: // Basic Info
          isValid = validateBasicInfo(state.formData.basicInfo)
          break
        case 1: // Address
          isValid = validateAddressStep(state.formData.address)
          break
        case 2: // Services
          isValid = validateServices(state.formData.services)
          break
        case 3: // Images
          isValid = validateImages(state.formData.images)
          break
        case 4: // Review
          isValid = state.isValid.slice(0, 4).every(v => v)
          break
        default:
          isValid = false
      }

      dispatch({
        type: 'SET_STEP_VALID',
        payload: { stepIndex, isValid }
      })

      return isValid
    } catch (error) {
      onError?.(error as Error)
      return false
    }
  }, [state.formData, state.isValid, onError])

  // Gerenciamento de erros
  const setStepError = useCallback((stepIndex: number, field: string, errors: string[]) => {
    dispatch({
      type: 'SET_STEP_ERROR',
      payload: { stepIndex, field, errors }
    })
  }, [])

  const clearStepErrors = useCallback((stepIndex: number) => {
    dispatch({ type: 'CLEAR_STEP_ERRORS', payload: stepIndex })
  }, [])


  // Reset
  const resetStepper = useCallback(() => {
    dispatch({ type: 'RESET_STEPPER' })
  }, [])

  // Submit
  const submitForm = useCallback(async () => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true })
      
      // Validar todos os steps
      const allValid = await Promise.all([
        validateStep(0),
        validateStep(1),
        validateStep(2),
        validateStep(3),
        validateStep(4)
      ])

      if (allValid.every(v => v)) {
        await onSubmit(state.formData)
      } else {
        throw new Error('Formulário possui campos inválidos')
      }
    } catch (error) {
      onError?.(error as Error)
    } finally {
      dispatch({ type: 'SET_LOADING', payload: false })
    }
  }, [state.formData, onSubmit, onError, validateStep])

  // Context value
  const contextValue: StepperContextValue = {
    state,
    nextStep,
    prevStep,
    goToStep,
    updateFormData,
    validateStep,
    setStepError,
    clearStepErrors,
    resetStepper,
    submitForm
  }

  return (
    <StepperContext.Provider value={contextValue}>
      {children}
    </StepperContext.Provider>
  )
}

// Hook para usar o context
export function useStepperContext(): StepperContextValue {
  const context = useContext(StepperContext)
  if (context === undefined) {
    throw new Error('useStepperContext must be used within a StepperProvider')
  }
  return context
}

// Funções auxiliares
function getStepIndexForSection(section: keyof ClinicFormData): number {
  switch (section) {
    case 'basicInfo':
      return 0
    case 'address':
    case 'location':
      return 1
    case 'services':
      return 2
    case 'images':
      return 3
    case 'metadata':
      return -1
    default:
      return -1
  }
}

function validateBasicInfo(data: BasicInfoData): boolean {
  return data.name.trim().length >= 3 && data.type !== undefined
}

function validateAddressStep(data: AddressData): boolean {
  return !!(
    data.cep &&
    data.street &&
    data.number &&
    data.neighborhood &&
    data.city &&
    data.state &&
    data.cep.length === 9 && // XXXXX-XXX
    data.street.trim().length >= 5 &&
    data.number.trim().length > 0 &&
    data.neighborhood.trim().length >= 2 &&
    data.city.trim().length >= 2 &&
    data.state.trim().length > 0
  )
}

function validateServices(data: ServiceData): boolean {
  // Pelo menos um serviço deve estar selecionado
  return data.selectedServices && 
         data.selectedServices.length > 0 &&
         data.selectedServices.some(service => service.isSelected)
}

function validateImages(images: ImageData[]): boolean {
  // Step de imagens é opcional - sempre válido
  // Verificar se images é array
  if (!Array.isArray(images)) {
    return true // Se não é array, considerar como vazio (válido)
  }
  
  // Se não tem imagens = válido
  // Se tem imagens = deve ter uma principal e não ter erros
  return images.length === 0 || 
         (images.some(img => img.isFeatured) &&
          images.every(img => img.uploadStatus !== 'error'))
}