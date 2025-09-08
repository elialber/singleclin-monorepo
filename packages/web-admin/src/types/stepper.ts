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
  services: ServiceData
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

// Step 3: Serviços da clínica
export interface ServiceData {
  selectedServices: SelectedService[]
}

export interface SelectedService {
  id: string
  name: string
  credits: number
  category: string
  isSelected: boolean
}

// Lista predefinida de serviços disponíveis
export const PREDEFINED_SERVICES: SelectedService[] = [
  // Terapias Injetáveis
  { id: 'terapia_im', name: 'Terapia Injetável Intramuscular', credits: 1, category: 'Terapias Injetáveis', isSelected: true },
  { id: 'terapia_ev', name: 'Terapia Injetável Endovenosa', credits: 3, category: 'Terapias Injetáveis', isSelected: true },
  
  // Tirzepatida
  { id: 'tirzepatida_25', name: 'Tirzepatida SC 2,5mg', credits: 1, category: 'Tirzepatida', isSelected: true },
  { id: 'tirzepatida_5', name: 'Tirzepatida SC 5mg', credits: 1, category: 'Tirzepatida', isSelected: true },
  { id: 'tirzepatida_75', name: 'Tirzepatida SC 7,5mg', credits: 1, category: 'Tirzepatida', isSelected: true },
  { id: 'tirzepatida_10', name: 'Tirzepatida SC 10 mg', credits: 1, category: 'Tirzepatida', isSelected: true },
  
  // Procedimentos Básicos
  { id: 'implante_sc', name: 'Implante subcutâneo', credits: 1, category: 'Procedimentos Básicos', isSelected: true },
  { id: 'remocao_ponto', name: 'Remoção de Ponto', credits: 1, category: 'Procedimentos Básicos', isSelected: true },
  { id: 'curativo', name: 'Curativo', credits: 2, category: 'Procedimentos Básicos', isSelected: true },
  
  // Estética
  { id: 'toxina_botulinica', name: 'Toxina Botulínica', credits: 2, category: 'Estética', isSelected: true },
  { id: 'bioestimulador_facial', name: 'Bioestimulador Facial (5mL)', credits: 3, category: 'Estética', isSelected: true },
  { id: 'bioestimulador_corporal', name: 'Bioestimulador Corporal (10mL)', credits: 3, category: 'Estética', isSelected: true },
  { id: 'preenchimento_facial', name: 'Preenchimento com Ac.Hialurônico Facial (5mL)', credits: 3, category: 'Estética', isSelected: true },
  { id: 'preenchimento_corporal', name: 'Preenchimento com Ac.Hialurônico Corporal (5mL)', credits: 3, category: 'Estética', isSelected: true },
  { id: 'mmp', name: 'MMP', credits: 3, category: 'Estética', isSelected: true },
  
  // Terapias Avançadas
  { id: 'onda_choque', name: 'Terapia de Onda de Choque (1 Sessão)', credits: 2, category: 'Terapias Avançadas', isSelected: true },
  { id: 'viscossuplementacao', name: 'Viscossuplementação (1 Sessão)', credits: 3, category: 'Terapias Avançadas', isSelected: true },
  { id: 'prp', name: 'PRP (1 Sessão)', credits: 3, category: 'Terapias Avançadas', isSelected: true },
  
  // Avaliações e Exames
  { id: 'bioimpedancia', name: 'Bioimpedância', credits: 1, category: 'Avaliações e Exames', isSelected: true },
  { id: 'calorimetria', name: 'Calorimetria Indireta', credits: 2, category: 'Avaliações e Exames', isSelected: true },
  { id: 'scaneamento_3d', name: 'Scaneamento 3D', credits: 1, category: 'Avaliações e Exames', isSelected: true },
  { id: 'biorressonancia', name: 'Biorressonância', credits: 1, category: 'Avaliações e Exames', isSelected: true },
  { id: 'mineralograma', name: 'Mineralograma', credits: 1, category: 'Avaliações e Exames', isSelected: true },
  
  // Tecnologias
  { id: 'campo_magnetico', name: 'Tecnologia (Campo Magnético)', credits: 3, category: 'Tecnologias', isSelected: true },
  { id: 'usg_focado', name: 'Tecnologia (USG Micro/Macro focado)', credits: 3, category: 'Tecnologias', isSelected: true },
  { id: 'laser_co2', name: 'Tecnologia  (Laser CO2)', credits: 3, category: 'Tecnologias', isSelected: true },
  { id: 'microagulhamento', name: 'Tecnologia (Microagulhamento)', credits: 3, category: 'Tecnologias', isSelected: true },
]

// Step 4: Upload de imagens
export interface ImageData {
  id: string
  file?: File
  url?: string
  preview?: string
  altText?: string
  displayOrder: number
  isFeatured: boolean
  uploadStatus: 'pending' | 'uploading' | 'success' | 'error'
  uploadProgress: number
  error?: string
  isExisting?: boolean // Para identificar imagens já existentes no backend
  dimensions?: {
    width: number
    height: number
  }
  sizeBytes?: number
  type?: string
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