import { useState, useCallback, useRef, useEffect } from 'react'
import { useDropzone, FileRejection } from 'react-dropzone'
import {
  ImageValidationConfig,
  ImageProcessingResult,
  UploadProgress,
  DEFAULT_IMAGE_CONFIG,
  validateImageType,
  validateImageSize,
  validateMultipleFiles,
  processImageFile,
  generateImageId,
  formatFileSize
} from '../../../../utils/imageValidation'
import { uploadService } from '../../../../utils/uploadService'

export interface ProcessedImage {
  id: string
  file?: File // Optional for existing images
  preview: string // URL for preview (either blob: URL or http: URL)
  dimensions: {
    width: number
    height: number
  }
  sizeBytes: number
  type: string
  thumbnail?: string
  isFeatured: boolean
  altText: string
  displayOrder: number
  uploadProgress?: UploadProgress
  url?: string // For existing images loaded from database
  isExisting?: boolean // Flag to identify existing vs new images
}

export interface ImageUploadConfig extends Partial<ImageValidationConfig> {
  autoUpload?: boolean
  generateThumbnails?: boolean
  enableReordering?: boolean
}

export interface UseImageUploadOptions {
  config?: ImageUploadConfig
  initialImages?: ProcessedImage[]
  onImagesChange?: (images: ProcessedImage[]) => void
  onUploadProgress?: (progress: UploadProgress[]) => void
  onError?: (errors: string[]) => void
}

export interface ImageUploadActions {
  // Gerenciamento de arquivos
  addFiles: (files: File[]) => Promise<void>
  removeImage: (id: string) => void
  removeAllImages: () => void
  
  // Reordenação
  reorderImages: (newOrder: ProcessedImage[]) => void
  moveImage: (fromIndex: number, toIndex: number) => void
  
  // Featured image
  setFeaturedImage: (id: string) => void
  
  // Alt text
  updateAltText: (id: string, altText: string) => void
  
  // Upload
  startUpload: () => Promise<void>
  cancelUpload: (id?: string) => void
  retryUpload: (id?: string) => void
  
  // Validation
  validateImages: () => boolean
  getValidationErrors: () => string[]
}

export interface ImageUploadState {
  images: ProcessedImage[]
  isProcessing: boolean
  isUploading: boolean
  uploadProgress: UploadProgress[]
  errors: string[]
  stats: {
    totalFiles: number
    totalSize: number
    uploadedCount: number
    failedCount: number
    overallProgress: number
  }
}

/**
 * Hook para gerenciar upload múltiplo de imagens
 */
export function useImageUpload({
  config = {},
  initialImages = [],
  onImagesChange,
  onUploadProgress,
  onError
}: UseImageUploadOptions = {}): [ImageUploadState, ImageUploadActions] {
  const fullConfig: ImageValidationConfig = { ...DEFAULT_IMAGE_CONFIG, ...config }
  const [images, setImages] = useState<ProcessedImage[]>(initialImages)
  const [isProcessing, setIsProcessing] = useState(false)
  const [isUploading, setIsUploading] = useState(false)
  const [uploadProgress, setUploadProgress] = useState<UploadProgress[]>([])
  const [errors, setErrors] = useState<string[]>([])
  
  const processingRef = useRef<Set<string>>(new Set())

  // Calcular estatísticas
  const stats = {
    totalFiles: images.length,
    totalSize: images.reduce((sum, img) => sum + img.sizeBytes, 0),
    uploadedCount: images.filter(img => img.uploadProgress?.status === 'success' || img.isExisting).length,
    failedCount: images.filter(img => img.uploadProgress?.status === 'error').length,
    overallProgress: uploadProgress.length > 0 
      ? Math.round(uploadProgress.reduce((sum, p) => sum + p.progress, 0) / uploadProgress.length)
      : 0
  }

  // Notificar mudanças
  useEffect(() => {
    onImagesChange?.(images)
  }, [images, onImagesChange])

  useEffect(() => {
    onUploadProgress?.(uploadProgress)
  }, [uploadProgress, onUploadProgress])

  useEffect(() => {
    if (errors.length > 0) {
      onError?.(errors)
    }
  }, [errors, onError])

  // Adicionar arquivos
  const addFiles = useCallback(async (files: File[]) => {
    if (files.length === 0) return

    setIsProcessing(true)
    setErrors([])

    try {
      // Validar múltiplos arquivos
      const existingFiles = images.filter(img => img.file).map(img => img.file!)
      const multipleValidation = validateMultipleFiles(
        [...existingFiles, ...files], 
        fullConfig
      )
      
      if (!multipleValidation.isValid) {
        setErrors(multipleValidation.errors)
        return
      }

      const processedImages: ProcessedImage[] = []
      const currentErrors: string[] = []

      // Processar cada arquivo
      for (const file of files) {
        try {
          // Verificar se não está sendo processado
          if (processingRef.current.has(file.name)) continue
          processingRef.current.add(file.name)

          // Validar tipo
          const typeValidation = await validateImageType(file)
          if (!typeValidation.isValid) {
            currentErrors.push(...typeValidation.errors.map(error => `${file.name}: ${error}`))
            continue
          }

          // Validar tamanho
          const sizeValidation = validateImageSize(file, fullConfig)
          if (!sizeValidation.isValid) {
            currentErrors.push(...sizeValidation.errors.map(error => `${file.name}: ${error}`))
            continue
          }

          // Processar imagem
          const processedImage = await processImageFile(file)
          
          // Criar objeto final
          const newImage: ProcessedImage = {
            ...processedImage,
            id: generateImageId(),
            isFeatured: images.length === 0 && processedImages.length === 0, // Primeira imagem é principal por padrão
            altText: '',
            displayOrder: images.length + processedImages.length
          }

          processedImages.push(newImage)
          
        } catch (error) {
          const errorMessage = error instanceof Error ? error.message : `Erro ao processar ${file.name}`
          currentErrors.push(errorMessage)
        } finally {
          processingRef.current.delete(file.name)
        }
      }

      // Adicionar imagens processadas
      if (processedImages.length > 0) {
        setImages(prev => [...prev, ...processedImages])
        
        // Auto-upload se configurado
        if (config.autoUpload) {
          // Note: Auto-upload is not implemented with real service yet
          // This would require integration with the actual clinic service API
          console.log('Auto-upload requested but not implemented with real service')
        }
      }

      // Exibir erros se houver
      if (currentErrors.length > 0) {
        setErrors(prev => [...prev, ...currentErrors])
      }

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Erro ao processar imagens'
      setErrors([errorMessage])
    } finally {
      setIsProcessing(false)
    }
  }, [images, fullConfig, config.autoUpload])

  // Configurar dropzone
  const { getRootProps, getInputProps, isDragActive, fileRejections } = useDropzone({
    accept: {
      'image/jpeg': ['.jpg', '.jpeg'],
      'image/png': ['.png'],
      'image/webp': ['.webp'],
      'image/avif': ['.avif']
    },
    maxFiles: fullConfig.maxFiles,
    maxSize: fullConfig.maxSizeBytes,
    multiple: true,
    noClick: false,
    onDrop: addFiles
  })

  // Processar rejeições do dropzone
  useEffect(() => {
    if (fileRejections.length > 0) {
      const rejectionErrors = fileRejections.map(rejection => {
        const fileName = rejection.file.name
        const errorMessages = rejection.errors.map(error => {
          switch (error.code) {
            case 'file-too-large':
              return `${fileName}: Arquivo muito grande (${formatFileSize(rejection.file.size)})`
            case 'file-invalid-type':
              return `${fileName}: Tipo de arquivo não suportado`
            case 'too-many-files':
              return 'Muitos arquivos selecionados'
            default:
              return `${fileName}: ${error.message}`
          }
        })
        return errorMessages.join(', ')
      })

      setErrors(prev => [...prev, ...rejectionErrors])
    }
  }, [fileRejections])

  // Remover imagem
  const removeImage = useCallback((id: string) => {
    setImages(prev => {
      const filtered = prev.filter(img => img.id !== id)
      
      // Se removeu a featured, definir a primeira como featured
      if (filtered.length > 0 && !filtered.some(img => img.isFeatured)) {
        filtered[0].isFeatured = true
      }
      
      // Revogar URL do preview
      const removedImage = prev.find(img => img.id === id)
      if (removedImage) {
        URL.revokeObjectURL(removedImage.preview)
      }
      
      return filtered
    })

    // Cancelar upload se em progresso
    uploadService.cancelUpload(id)
  }, [])

  // Remover todas as imagens
  const removeAllImages = useCallback(() => {
    // Revogar todas as URLs
    images.forEach(img => URL.revokeObjectURL(img.preview))
    
    setImages([])
    uploadService.clearQueue()
    setUploadProgress([])
    setErrors([])
  }, [images])

  // Reordenar imagens
  const reorderImages = useCallback((newOrder: ProcessedImage[]) => {
    const reorderedImages = newOrder.map((img, index) => ({
      ...img,
      displayOrder: index
    }))
    setImages(reorderedImages)
  }, [])

  // Mover imagem
  const moveImage = useCallback((fromIndex: number, toIndex: number) => {
    setImages(prev => {
      const newOrder = [...prev]
      const [moved] = newOrder.splice(fromIndex, 1)
      newOrder.splice(toIndex, 0, moved)
      
      return newOrder.map((img, index) => ({
        ...img,
        displayOrder: index
      }))
    })
  }, [])

  // Definir imagem principal
  const setFeaturedImage = useCallback((id: string) => {
    setImages(prev => prev.map(img => ({
      ...img,
      isFeatured: img.id === id
    })))
  }, [])

  // Atualizar alt text
  const updateAltText = useCallback((id: string, altText: string) => {
    setImages(prev => prev.map(img => 
      img.id === id ? { ...img, altText } : img
    ))
  }, [])

  // Iniciar upload
  const startUpload = useCallback(async () => {
    const imagesToUpload = images.filter(img => img.file && !img.isExisting)
    if (imagesToUpload.length === 0) return

    setIsUploading(true)
    setErrors([])

    try {
      const files = imagesToUpload.map(img => img.file!)
      await uploadService.addFiles(files, setUploadProgress)
      
      // Atualizar status das imagens
      setImages(prev => prev.map(img => {
        if (!img.file) return img
        const progress = uploadProgress.find(p => p.file === img.file)
        return progress ? { ...img, uploadProgress: progress } : img
      }))

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Erro no upload'
      setErrors([errorMessage])
    } finally {
      setIsUploading(false)
    }
  }, [images, uploadProgress])

  // Cancelar upload
  const cancelUpload = useCallback((id?: string) => {
    if (id) {
      uploadService.cancelUpload(id)
    } else {
      uploadService.cancelAllUploads()
    }
    
    if (!id) {
      setIsUploading(false)
      setUploadProgress([])
    }
  }, [])

  // Retry upload
  const retryUpload = useCallback(async (id?: string) => {
    if (id) {
      await uploadService.retryUpload(id, setUploadProgress)
    } else {
      await uploadService.retryFailedUploads(setUploadProgress)
    }
  }, [])

  // Validar imagens
  const validateImages = useCallback((): boolean => {
    if (images.length === 0) {
      setErrors(['Pelo menos uma imagem é obrigatória'])
      return false
    }

    const validationErrors: string[] = []

    // Verificar se tem featured image
    if (!images.some(img => img.isFeatured)) {
      validationErrors.push('Uma imagem deve ser marcada como principal')
    }

    // Verificar alt text obrigatório (opcional)
    const missingAltText = images.filter(img => !img.altText.trim())
    if (missingAltText.length > 0) {
      validationErrors.push(`${missingAltText.length} imagem(ns) sem descrição alternativa`)
    }

    setErrors(validationErrors)
    return validationErrors.length === 0
  }, [images])

  // Obter erros de validação
  const getValidationErrors = useCallback((): string[] => {
    return [...errors]
  }, [errors])

  const state: ImageUploadState = {
    images,
    isProcessing,
    isUploading,
    uploadProgress,
    errors,
    stats
  }

  const actions: ImageUploadActions = {
    addFiles,
    removeImage,
    removeAllImages,
    reorderImages,
    moveImage,
    setFeaturedImage,
    updateAltText,
    startUpload,
    cancelUpload,
    retryUpload,
    validateImages,
    getValidationErrors
  }

  return [state, actions]
}

/**
 * Hook simplificado para dropzone
 */
export function useImageDropzone(onFilesAdded: (files: File[]) => void) {
  return useDropzone({
    accept: {
      'image/jpeg': ['.jpg', '.jpeg'],
      'image/png': ['.png'],
      'image/webp': ['.webp'],
      'image/avif': ['.avif']
    },
    multiple: true,
    onDrop: onFilesAdded
  })
}