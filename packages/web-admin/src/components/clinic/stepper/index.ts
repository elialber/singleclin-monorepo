// Core components
export { ClinicStepper } from './core/ClinicStepper'
export { StepperProvider, useStepperContext } from './core/StepperProvider'
export { StepperIndicator } from './core/StepperIndicator'
export { StepperNavigation } from './core/StepperNavigation'

// Hooks
export {
  useClinicStepper,
  useStepperNavigation,
  useStepperForm,
  useStepperValidation
} from './hooks/useClinicStepper'

// Types (re-export from types)
export type {
  StepperState,
  ClinicFormData,
  BasicInfoData,
  AddressData,
  LocationData,
  ImageData,
  StepperMetadata,
  StepperErrors,
  StepStatus,
  StepInfo,
  StepperContextValue,
  StepperProviderProps,
  StepComponentProps,
  ValidationRule,
  StepValidationConfig,
  ImageUploadConfig,
  MapConfig,
  GeocodingResult,
  BrazilianStateCode
} from '../../../types/stepper'

export { BRAZILIAN_STATES } from '../../../types/stepper'