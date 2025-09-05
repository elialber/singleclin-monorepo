/**
 * Utilitários para validação e processamento de imagens
 */

export interface ImageValidationConfig {
  maxSizeBytes: number
  maxTotalSizeBytes: number
  maxFiles: number
  minWidth: number
  minHeight: number
  maxWidth: number
  maxHeight: number
  allowedTypes: string[]
}

export interface ImageValidationResult {
  isValid: boolean
  errors: string[]
}

export interface ImageProcessingResult {
  file: File
  preview: string
  dimensions: {
    width: number
    height: number
  }
  sizeBytes: number
  type: string
}

export interface UploadProgress {
  id: string
  file: File
  progress: number
  status: 'pending' | 'uploading' | 'success' | 'error'
  error?: string
  url?: string
}

/**
 * Configuração padrão para validação de imagens
 */
export const DEFAULT_IMAGE_CONFIG: ImageValidationConfig = {
  maxSizeBytes: 5 * 1024 * 1024, // 5MB por imagem
  maxTotalSizeBytes: 25 * 1024 * 1024, // 25MB total
  maxFiles: 10,
  minWidth: 200,
  minHeight: 200,
  maxWidth: 4096,
  maxHeight: 4096,
  allowedTypes: [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'image/avif'
  ]
}

/**
 * MIME types válidos com suas extensões
 */
export const VALID_IMAGE_TYPES = {
  'image/jpeg': ['.jpg', '.jpeg'],
  'image/png': ['.png'],
  'image/webp': ['.webp'],
  'image/avif': ['.avif']
} as const

/**
 * Validar tipo de arquivo por MIME type e header
 */
export async function validateImageType(file: File): Promise<ImageValidationResult> {
  const errors: string[] = []
  
  // Verificar MIME type
  if (!DEFAULT_IMAGE_CONFIG.allowedTypes.includes(file.type)) {
    errors.push(`Tipo de arquivo não permitido: ${file.type}`)
    return { isValid: false, errors }
  }
  
  // Verificar magic bytes (file header)
  try {
    const buffer = await file.slice(0, 16).arrayBuffer()
    const bytes = new Uint8Array(buffer)
    
    if (!isValidImageHeader(bytes, file.type)) {
      errors.push('Arquivo corrompido ou inválido')
      return { isValid: false, errors }
    }
  } catch (error) {
    errors.push('Não foi possível validar o arquivo')
    return { isValid: false, errors }
  }
  
  return { isValid: true, errors: [] }
}

/**
 * Verificar magic bytes do arquivo
 */
function isValidImageHeader(bytes: Uint8Array, mimeType: string): boolean {
  switch (mimeType) {
    case 'image/jpeg':
      // JPEG: FF D8 FF
      return bytes[0] === 0xFF && bytes[1] === 0xD8 && bytes[2] === 0xFF
      
    case 'image/png':
      // PNG: 89 50 4E 47 0D 0A 1A 0A
      return (
        bytes[0] === 0x89 && bytes[1] === 0x50 &&
        bytes[2] === 0x4E && bytes[3] === 0x47 &&
        bytes[4] === 0x0D && bytes[5] === 0x0A &&
        bytes[6] === 0x1A && bytes[7] === 0x0A
      )
      
    case 'image/webp':
      // WebP: 52 49 46 46 ... 57 45 42 50
      return (
        bytes[0] === 0x52 && bytes[1] === 0x49 &&
        bytes[2] === 0x46 && bytes[3] === 0x46 &&
        bytes[8] === 0x57 && bytes[9] === 0x45 &&
        bytes[10] === 0x42 && bytes[11] === 0x50
      )
      
    case 'image/avif':
      // AVIF é mais complexo, verificação básica
      return bytes[4] === 0x66 && bytes[5] === 0x74 && bytes[6] === 0x79 && bytes[7] === 0x70
      
    default:
      return false
  }
}

/**
 * Validar tamanho do arquivo
 */
export function validateImageSize(
  file: File,
  config: ImageValidationConfig = DEFAULT_IMAGE_CONFIG
): ImageValidationResult {
  const errors: string[] = []
  
  if (file.size > config.maxSizeBytes) {
    const maxSizeMB = Math.round(config.maxSizeBytes / (1024 * 1024))
    const fileSizeMB = Math.round(file.size / (1024 * 1024))
    errors.push(`Arquivo muito grande: ${fileSizeMB}MB. Máximo: ${maxSizeMB}MB`)
  }
  
  return { isValid: errors.length === 0, errors }
}

/**
 * Validar dimensões da imagem usando Canvas API
 */
export function validateImageDimensions(
  image: HTMLImageElement,
  config: ImageValidationConfig = DEFAULT_IMAGE_CONFIG
): ImageValidationResult {
  const errors: string[] = []
  
  if (image.width < config.minWidth || image.height < config.minHeight) {
    errors.push(`Imagem muito pequena: ${image.width}x${image.height}px. Mínimo: ${config.minWidth}x${config.minHeight}px`)
  }
  
  if (image.width > config.maxWidth || image.height > config.maxHeight) {
    errors.push(`Imagem muito grande: ${image.width}x${image.height}px. Máximo: ${config.maxWidth}x${config.maxHeight}px`)
  }
  
  return { isValid: errors.length === 0, errors }
}

/**
 * Validar múltiplos arquivos
 */
export function validateMultipleFiles(
  files: File[],
  config: ImageValidationConfig = DEFAULT_IMAGE_CONFIG
): ImageValidationResult {
  const errors: string[] = []
  
  // Verificar quantidade máxima
  if (files.length > config.maxFiles) {
    errors.push(`Muitas imagens selecionadas: ${files.length}. Máximo: ${config.maxFiles}`)
  }
  
  // Verificar tamanho total
  const totalSize = files.reduce((sum, file) => sum + file.size, 0)
  if (totalSize > config.maxTotalSizeBytes) {
    const maxTotalMB = Math.round(config.maxTotalSizeBytes / (1024 * 1024))
    const totalMB = Math.round(totalSize / (1024 * 1024))
    errors.push(`Tamanho total muito grande: ${totalMB}MB. Máximo: ${maxTotalMB}MB`)
  }
  
  return { isValid: errors.length === 0, errors }
}

/**
 * Processar arquivo de imagem e extrair informações
 */
export function processImageFile(file: File): Promise<ImageProcessingResult> {
  return new Promise((resolve, reject) => {
    const img = new Image()
    const preview = URL.createObjectURL(file)
    
    img.onload = () => {
      const result: ImageProcessingResult = {
        file,
        preview,
        dimensions: {
          width: img.width,
          height: img.height
        },
        sizeBytes: file.size,
        type: file.type
      }
      
      // Não revogar URL aqui - será feito pelo componente quando necessário
      resolve(result)
    }
    
    img.onerror = () => {
      URL.revokeObjectURL(preview)
      reject(new Error('Não foi possível carregar a imagem'))
    }
    
    img.src = preview
  })
}

/**
 * Redimensionar imagem mantendo proporção
 */
export function resizeImage(
  image: HTMLImageElement,
  maxWidth: number,
  maxHeight: number,
  quality: number = 0.8
): Promise<Blob> {
  return new Promise((resolve, reject) => {
    const canvas = document.createElement('canvas')
    const ctx = canvas.getContext('2d')
    
    if (!ctx) {
      reject(new Error('Não foi possível criar canvas'))
      return
    }
    
    // Calcular novas dimensões mantendo proporção
    const ratio = Math.min(maxWidth / image.width, maxHeight / image.height)
    canvas.width = image.width * ratio
    canvas.height = image.height * ratio
    
    // Desenhar imagem redimensionada
    ctx.drawImage(image, 0, 0, canvas.width, canvas.height)
    
    // Converter para blob
    canvas.toBlob(
      (blob) => {
        if (blob) {
          resolve(blob)
        } else {
          reject(new Error('Erro ao redimensionar imagem'))
        }
      },
      'image/jpeg',
      quality
    )
  })
}

/**
 * Gerar thumbnail da imagem
 */
export function generateThumbnail(
  image: HTMLImageElement,
  size: number = 200,
  quality: number = 0.7
): Promise<string> {
  return new Promise((resolve, reject) => {
    const canvas = document.createElement('canvas')
    const ctx = canvas.getContext('2d')
    
    if (!ctx) {
      reject(new Error('Não foi possível criar canvas'))
      return
    }
    
    canvas.width = size
    canvas.height = size
    
    // Calcular crop para manter proporção quadrada
    const sourceSize = Math.min(image.width, image.height)
    const sourceX = (image.width - sourceSize) / 2
    const sourceY = (image.height - sourceSize) / 2
    
    // Desenhar imagem cropada e redimensionada
    ctx.drawImage(
      image,
      sourceX, sourceY, sourceSize, sourceSize,
      0, 0, size, size
    )
    
    // Converter para data URL
    resolve(canvas.toDataURL('image/jpeg', quality))
  })
}

/**
 * Formatar tamanho de arquivo para exibição
 */
export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 Bytes'
  
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i]
}

/**
 * Gerar ID único para arquivo
 */
export function generateImageId(): string {
  return Date.now().toString(36) + Math.random().toString(36).substr(2)
}

/**
 * Verificar se o navegador suporta tipos de imagem modernos
 */
export function checkImageSupport() {
  const canvas = document.createElement('canvas')
  
  return {
    webp: canvas.toDataURL('image/webp').indexOf('image/webp') === 5,
    avif: canvas.toDataURL('image/avif').indexOf('image/avif') === 5
  }
}

/**
 * Extrair dados EXIF básicos (orientação)
 */
export function getImageOrientation(file: File): Promise<number> {
  return new Promise((resolve) => {
    const reader = new FileReader()
    
    reader.onload = (e) => {
      const arrayBuffer = e.target?.result as ArrayBuffer
      const dataView = new DataView(arrayBuffer)
      
      // Verificar se é JPEG
      if (dataView.getUint16(0) !== 0xFFD8) {
        resolve(1) // Orientação normal para não-JPEG
        return
      }
      
      let offset = 2
      let marker
      
      while (offset < dataView.byteLength) {
        marker = dataView.getUint16(offset)
        
        if (marker === 0xFFE1) {
          // Encontrou segmento EXIF
          const orientation = extractOrientationFromEXIF(dataView, offset)
          resolve(orientation)
          return
        }
        
        offset += 2 + dataView.getUint16(offset + 2)
      }
      
      resolve(1) // Orientação normal se EXIF não encontrado
    }
    
    reader.onerror = () => resolve(1)
    reader.readAsArrayBuffer(file.slice(0, 64 * 1024)) // Ler apenas primeiros 64KB
  })
}

function extractOrientationFromEXIF(dataView: DataView, offset: number): number {
  try {
    const length = dataView.getUint16(offset + 2)
    const exifOffset = offset + 4
    
    if (dataView.getUint32(exifOffset) !== 0x45786966) return 1 // "Exif"
    
    const tiffOffset = exifOffset + 6
    const littleEndian = dataView.getUint16(tiffOffset) === 0x4949
    
    const ifd0Offset = tiffOffset + dataView.getUint32(tiffOffset + 4, littleEndian)
    const tagCount = dataView.getUint16(ifd0Offset, littleEndian)
    
    for (let i = 0; i < tagCount; i++) {
      const tagOffset = ifd0Offset + 2 + i * 12
      const tag = dataView.getUint16(tagOffset, littleEndian)
      
      if (tag === 0x0112) { // Orientation tag
        return dataView.getUint16(tagOffset + 8, littleEndian)
      }
    }
    
    return 1
  } catch {
    return 1
  }
}