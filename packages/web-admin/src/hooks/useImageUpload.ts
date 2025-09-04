import { useState, useCallback } from 'react'
import { clinicService } from '@/services/clinic.service'
import { validateImageFile, type ClinicImageUpload } from '@/types/clinic'

interface UseImageUploadOptions {
  onSuccess?: (imageUrl: string) => void
  onError?: (error: string) => void
  autoUpload?: boolean
}

interface UseImageUploadReturn {
  uploadImage: (clinicId: string, uploadData: ClinicImageUpload) => Promise<void>
  deleteImage: (clinicId: string) => Promise<void>
  loading: boolean
  error: string | null
  clearError: () => void
  validateFile: (file: File) => { isValid: boolean; error?: string }
}

export const useImageUpload = (options: UseImageUploadOptions = {}): UseImageUploadReturn => {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const clearError = useCallback(() => {
    setError(null)
  }, [])

  const validateFile = useCallback((file: File) => {
    return validateImageFile(file)
  }, [])

  const uploadImage = useCallback(async (clinicId: string, uploadData: ClinicImageUpload) => {
    try {
      setLoading(true)
      setError(null)

      const validation = validateImageFile(uploadData.image)
      if (!validation.isValid) {
        throw new Error(validation.error)
      }

      const result = await clinicService.uploadImage(clinicId, uploadData)
      
      if (!result.success) {
        throw new Error(result.error || 'Erro ao fazer upload da imagem')
      }

      if (result.clinic?.imageUrl) {
        options.onSuccess?.(result.clinic.imageUrl)
      }
    } catch (err: any) {
      const errorMessage = err?.message || 'Erro inesperado ao fazer upload da imagem'
      setError(errorMessage)
      options.onError?.(errorMessage)
    } finally {
      setLoading(false)
    }
  }, [options])

  const deleteImage = useCallback(async (clinicId: string) => {
    try {
      setLoading(true)
      setError(null)

      const result = await clinicService.deleteImage(clinicId)
      
      if (!result.success) {
        throw new Error(result.error || 'Erro ao remover imagem')
      }

      options.onSuccess?.('')
    } catch (err: any) {
      const errorMessage = err?.message || 'Erro inesperado ao remover imagem'
      setError(errorMessage)
      options.onError?.(errorMessage)
    } finally {
      setLoading(false)
    }
  }, [options])

  return {
    uploadImage,
    deleteImage,
    loading,
    error,
    clearError,
    validateFile
  }
}

export default useImageUpload