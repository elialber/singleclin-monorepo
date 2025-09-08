import { useCallback, useMemo } from 'react'
import { useStepperContext } from '../core/StepperProvider'
import { StepInfo, StepStatus } from '../../../../types/stepper'

/**
 * Hook principal para gerenciar o stepper de cadastro de clínica
 * 
 * Fornece funcionalidades completas de navegação, validação e gerenciamento de estado
 */
export function useClinicStepper() {
  const {
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
  } = useStepperContext()

  // Informações dos steps
  const stepInfos = useMemo((): StepInfo[] => [
    {
      index: 0,
      title: 'Informações Básicas',
      description: 'Dados fundamentais da clínica',
      icon: '🏢',
      status: getStepStatus(0, state.currentStep, state.isValid[0]),
      isValid: state.isValid[0],
      isDirty: state.isDirty[0]
    },
    {
      index: 1,
      title: 'Endereço e Localização',
      description: 'Localização precisa com mapa',
      icon: '🗺️',
      status: getStepStatus(1, state.currentStep, state.isValid[1]),
      isValid: state.isValid[1],
      isDirty: state.isDirty[1]
    },
    {
      index: 2,
      title: 'Serviços da Clínica',
      description: 'Selecionar serviços oferecidos',
      icon: '🩺',
      status: getStepStatus(2, state.currentStep, state.isValid[2]),
      isValid: state.isValid[2],
      isDirty: state.isDirty[2]
    },
    {
      index: 3,
      title: 'Upload de Imagens',
      description: 'Múltiplas imagens da clínica',
      icon: '📸',
      status: getStepStatus(3, state.currentStep, state.isValid[3]),
      isValid: state.isValid[3],
      isDirty: state.isDirty[3]
    },
    {
      index: 4,
      title: 'Revisão Final',
      description: 'Confirmar dados antes de enviar',
      icon: '✅',
      status: getStepStatus(4, state.currentStep, state.isValid[4]),
      isValid: state.isValid[4],
      isDirty: state.isDirty[4]
    }
  ], [state.currentStep, state.isValid, state.isDirty])

  // Informações do step atual
  const currentStepInfo = useMemo(() => 
    stepInfos[state.currentStep],
    [stepInfos, state.currentStep]
  )

  // Estado de navegação
  const canGoNext = useMemo(() => 
    state.currentStep < state.totalSteps - 1 && state.isValid[state.currentStep],
    [state.currentStep, state.totalSteps, state.isValid]
  )

  const canGoPrev = useMemo(() => 
    state.currentStep > 0,
    [state.currentStep]
  )

  const isLastStep = useMemo(() => 
    state.currentStep === state.totalSteps - 1,
    [state.currentStep, state.totalSteps]
  )

  const isFirstStep = useMemo(() => 
    state.currentStep === 0,
    [state.currentStep]
  )

  // Progresso geral
  const progress = useMemo(() => ({
    current: state.currentStep + 1,
    total: state.totalSteps,
    percentage: Math.round(((state.currentStep + 1) / state.totalSteps) * 100),
    completedSteps: state.isValid.filter(Boolean).length,
    validSteps: state.isValid.reduce((acc, isValid, index) => {
      if (isValid) acc.push(index)
      return acc
    }, [] as number[]),
    dirtySteps: state.isDirty.reduce((acc, isDirty, index) => {
      if (isDirty) acc.push(index)
      return acc
    }, [] as number[])
  }), [state.currentStep, state.totalSteps, state.isValid, state.isDirty])

  // Navegação com validação
  const nextStepWithValidation = useCallback(async () => {
    try {
      const isValid = await validateStep(state.currentStep)
      if (isValid) {
        nextStep()
      } else {
        console.warn(`Step ${state.currentStep} is not valid`)
      }
    } catch (error) {
      console.error('Error validating step:', error)
    }
  }, [state.currentStep, validateStep, nextStep])

  const goToStepWithValidation = useCallback(async (stepIndex: number) => {
    if (stepIndex < state.currentStep) {
      // Pode voltar sem validação
      goToStep(stepIndex)
      return
    }

    // Para ir para frente, validar steps intermediários
    let canGo = true
    for (let i = state.currentStep; i < stepIndex; i++) {
      const isValid = await validateStep(i)
      if (!isValid) {
        canGo = false
        break
      }
    }

    if (canGo) {
      goToStep(stepIndex)
    }
  }, [state.currentStep, validateStep, goToStep])

  // Validação de todo o formulário
  const validateAllSteps = useCallback(async (): Promise<boolean> => {
    const validationResults = await Promise.all([
      validateStep(0),
      validateStep(1),
      validateStep(2),
      validateStep(3)
    ])
    return validationResults.every(Boolean)
  }, [validateStep])


  // Obter erros de um step específico
  const getStepErrors = useCallback((stepIndex: number) => 
    state.errors[stepIndex] || {},
    [state.errors]
  )

  // Verificar se step tem erros
  const hasStepErrors = useCallback((stepIndex: number) => {
    const errors = getStepErrors(stepIndex)
    return Object.values(errors).some(errorArray => errorArray.length > 0)
  }, [getStepErrors])

  // Obter total de erros
  const totalErrors = useMemo(() => {
    return Object.values(state.errors).reduce((total, stepErrors) => {
      return total + Object.values(stepErrors).reduce((stepTotal, errorArray) => 
        stepTotal + errorArray.length, 0
      )
    }, 0)
  }, [state.errors])

  // Submissão com validação completa
  const submitWithValidation = useCallback(async () => {
    try {
      const allValid = await validateAllSteps()
      if (allValid) {
        await submitForm()
      } else {
        throw new Error('Formulário possui campos inválidos. Verifique todos os steps.')
      }
    } catch (error) {
      console.error('Error submitting form:', error)
      throw error
    }
  }, [validateAllSteps, submitForm])

  return {
    // Estado
    state,
    currentStepInfo,
    stepInfos,
    progress,
    
    // Navegação
    nextStep: nextStepWithValidation,
    prevStep,
    goToStep: goToStepWithValidation,
    canGoNext,
    canGoPrev,
    isFirstStep,
    isLastStep,
    
    // Dados
    formData: state.formData,
    updateFormData,
    
    // Validação
    validateStep,
    validateAllSteps,
    hasStepErrors,
    getStepErrors,
    totalErrors,
    setStepError,
    clearStepErrors,
    
    // Estados
    isLoading: state.isLoading,
    
    // Ações
    resetStepper,
    submitForm: submitWithValidation
  }
}

/**
 * Hook simplificado para componentes que só precisam de navegação básica
 */
export function useStepperNavigation() {
  const { nextStep, prevStep, goToStep, canGoNext, canGoPrev, isFirstStep, isLastStep } = useClinicStepper()
  
  return {
    nextStep,
    prevStep,
    goToStep,
    canGoNext,
    canGoPrev,
    isFirstStep,
    isLastStep
  }
}

/**
 * Hook para gerenciar apenas os dados do formulário
 */
export function useStepperForm() {
  const { formData, updateFormData, validateStep } = useClinicStepper()
  
  return {
    formData,
    updateFormData,
    validateStep
  }
}

/**
 * Hook para gerenciar apenas validação e erros
 */
export function useStepperValidation() {
  const {
    validateStep,
    validateAllSteps,
    hasStepErrors,
    getStepErrors,
    totalErrors,
    setStepError,
    clearStepErrors
  } = useClinicStepper()
  
  return {
    validateStep,
    validateAllSteps,
    hasStepErrors,
    getStepErrors,
    totalErrors,
    setStepError,
    clearStepErrors
  }
}

// Função auxiliar para determinar status do step
function getStepStatus(stepIndex: number, currentStep: number, isValid: boolean): StepStatus {
  if (stepIndex < currentStep) {
    return isValid ? 'completed' : 'error'
  }
  
  if (stepIndex === currentStep) {
    return 'current'
  }
  
  return 'pending'
}