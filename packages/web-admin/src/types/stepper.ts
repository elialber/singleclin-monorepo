import { ClinicType } from './clinic'

// Estado geral do stepper
export interface StepperState {
  currentStep: number
  totalSteps: number
  isValid: boolean[]       // Valida��o por step
  isDirty: boolean[]       // Modifica��o por step
  formData: ClinicFormData
  errors: StepperErrors
  isLoading: boolean
}

// Dados do formul�rio da cl�nica
export interface ClinicFormData {
  basicInfo: BasicInfoData
  address: AddressData
  location: LocationData
  images: ImageData[]
  metadata: StepperMetadata
}

// Step 1: Informa��es b�sicas
export interface BasicInfoData {
  name: string
  type: ClinicType
  cnpj?: string
  phone?: string
  email?: string
  isActive: boolean
}

// Step 2: Endere�o e localiza��o
export interface AddressData {
  cep: string
  street: string
  number: string
  complement?: string
  neighborhood: string
  city: string
  state: string
}

export interface LocationData {
  latitude: number
  longitude: number
  accuracy?: number
  source: 'user' | 'geocode' | 'gps'
}

// Step 3: Upload de imagens
export interface ImageData {
  id: string
  file?: File
  url?: string
  altText?: string
  displayOrder: number
  isFeatured: boolean
  uploadStatus: 'pending' | 'uploading' | 'success' | 'error'
  uploadProgress: number
  error?: string
}

// Metadados do stepper
export interface StepperMetadata {
  createdAt: Date
  updatedAt: Date
  completedSteps: number[]
  timeSpentPerStep: number[]
  totalTime: number
}

// Erros do stepper
export interface StepperErrors {
  [stepIndex: number]: {
    [fieldName: string]: string[]
  }
}

// Estados dos steps
export type StepStatus = 'pending' | 'current' | 'completed' | 'error'

export interface StepInfo {
  index: number
  title: string
  description: string
  icon: string
  status: StepStatus
  isValid: boolean
  isDirty: boolean
}

// Context do stepper
export interface StepperContextValue {
  state: StepperState
  nextStep: () => void
  prevStep: () => void
  goToStep: (stepIndex: number) => void
  updateFormData: <T extends keyof ClinicFormData>(
    section: T,
    data: Partial<ClinicFormData[T]>
  ) => void
  validateStep: (stepIndex: number) => Promise<boolean>
  setStepError: (stepIndex: number, field: string, errors: string[]) => void
  clearStepErrors: (stepIndex: number) => void
  resetStepper: () => void
  submitForm: () => Promise<void>
}

// Props dos componentes
export interface StepperProviderProps {
  children: React.ReactNode
  initialData?: Partial<ClinicFormData>
  onSubmit: (data: ClinicFormData) => Promise<void>
  onStepChange?: (stepIndex: number) => void
  onError?: (error: Error) => void
}

export interface StepComponentProps {
  onNext: () => void
  onPrev: () => void
  isValid: boolean
  isDirty: boolean
}

// Valida��o
export interface ValidationRule {
  field: string
  type: 'required' | 'email' | 'phone' | 'cnpj' | 'cep' | 'minLength' | 'maxLength' | 'regex' | 'custom'
  value?: any
  message: string
  validator?: (value: any, formData: ClinicFormData) => boolean | Promise<boolean>
}

export interface StepValidationConfig {
  [stepIndex: number]: ValidationRule[]
}


// Upload de imagens
export interface ImageUploadConfig {
  maxFiles: number
  maxFileSize: number
  maxTotalSize: number
  allowedTypes: string[]
  minResolution: { width: number; height: number }
  maxResolution: { width: number; height: number }
}

// Mapa e geocoding
export interface MapConfig {
  center: { lat: number; lng: number }
  zoom: number
  bounds?: {
    north: number
    south: number
    east: number
    west: number
  }
}

export interface GeocodingResult {
  address: string
  latitude: number
  longitude: number
  accuracy: number
  components: {
    street?: string
    number?: string
    neighborhood?: string
    city?: string
    state?: string
    country?: string
    postalCode?: string
  }
}

// Estados brasileiros
export const BRAZILIAN_STATES = [
  { code: 'AC', name: 'Acre' },
  { code: 'AL', name: 'Alagoas' },
  { code: 'AP', name: 'Amapá' },
  { code: 'AM', name: 'Amazonas' },
  { code: 'BA', name: 'Bahia' },
  { code: 'CE', name: 'Ceará' },
  { code: 'DF', name: 'Distrito Federal' },
  { code: 'ES', name: 'Espírito Santo' },
  { code: 'GO', name: 'Goiás' },
  { code: 'MA', name: 'Maranhão' },
  { code: 'MT', name: 'Mato Grosso' },
  { code: 'MS', name: 'Mato Grosso do Sul' },
  { code: 'MG', name: 'Minas Gerais' },
  { code: 'PA', name: 'Pará' },
  { code: 'PB', name: 'Paraíba' },
  { code: 'PR', name: 'Paraná' },
  { code: 'PE', name: 'Pernambuco' },
  { code: 'PI', name: 'Piauí' },
  { code: 'RJ', name: 'Rio de Janeiro' },
  { code: 'RN', name: 'Rio Grande do Norte' },
  { code: 'RS', name: 'Rio Grande do Sul' },
  { code: 'RO', name: 'Rondônia' },
  { code: 'RR', name: 'Roraima' },
  { code: 'SC', name: 'Santa Catarina' },
  { code: 'SP', name: 'São Paulo' },
  { code: 'SE', name: 'Sergipe' },
  { code: 'TO', name: 'Tocantins' }
] as const

export type BrazilianStateCode = typeof BRAZILIAN_STATES[number]['code']