export enum ClinicType {
  Regular = 0,
  Origin = 1,
  Partner = 2,
  Administrative = 3,
}

export interface Clinic {
  id: string
  name: string
  type: ClinicType
  address: string
  phoneNumber?: string
  email?: string
  cnpj?: string
  isActive: boolean
  latitude?: number
  longitude?: number
  imageUrl?: string
  createdAt: string
  updatedAt: string
  transactionCount: number
  typeDisplayName: string
  hasImage: boolean
}

export interface CreateClinicRequest {
  name: string
  type: ClinicType
  address: string
  phoneNumber?: string
  email?: string
  cnpj?: string
  isActive?: boolean
}

export interface UpdateClinicRequest extends Partial<CreateClinicRequest> {
  isActive?: boolean
}

export interface ClinicListResponse {
  data: Clinic[]
  total: number
  totalCount: number
  pageNumber: number
  pageSize: number
  totalPages: number
}

// Helper functions for display
export const getClinicTypeLabel = (type: ClinicType): string => {
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

export const getClinicTypeColor = (type: ClinicType): 'default' | 'primary' | 'secondary' | 'success' | 'warning' => {
  switch (type) {
    case ClinicType.Origin:
      return 'primary'
    case ClinicType.Partner:
      return 'secondary'
    case ClinicType.Administrative:
      return 'success'
    case ClinicType.Regular:
    default:
      return 'default'
  }
}

// Image upload related interfaces
export interface ClinicImageUpload {
  image: File
  altText?: string
  description?: string
}

export interface ImageUploadResponse {
  success: boolean
  imageUrl?: string
  fileSize?: number
  originalFileName?: string
  contentType?: string
  errorMessage?: string
  uploadedAt: string
}

export interface ImageUploadResult {
  success: boolean
  clinic?: Clinic
  error?: string
}

// Image validation helpers
export const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp']
export const MAX_IMAGE_SIZE = 5 * 1024 * 1024 // 5MB
export const ALLOWED_EXTENSIONS = ['jpg', 'jpeg', 'png', 'webp']

export const validateImageFile = (file: File): { isValid: boolean; error?: string } => {
  if (!file) {
    return { isValid: false, error: 'Nenhum arquivo selecionado' }
  }

  if (!ALLOWED_IMAGE_TYPES.includes(file.type)) {
    return { isValid: false, error: 'Tipo de arquivo não permitido. Use JPEG, PNG ou WebP.' }
  }

  if (file.size > MAX_IMAGE_SIZE) {
    return { isValid: false, error: 'Arquivo muito grande. Máximo 5MB.' }
  }

  return { isValid: true }
}

export const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}