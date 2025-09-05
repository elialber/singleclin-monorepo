/**
 * Serviço para upload múltiplo de imagens
 */

import { UploadProgress } from './imageValidation'

export interface UploadConfig {
  endpoint: string
  maxConcurrent: number
  retryAttempts: number
  retryDelay: number
  timeout: number
  chunkSize?: number
}

export interface UploadResponse {
  success: boolean
  url?: string
  error?: string
  metadata?: {
    id: string
    filename: string
    size: number
    type: string
    width?: number
    height?: number
  }
}

/**
 * Configuração padrão para uploads
 */
export const DEFAULT_UPLOAD_CONFIG: UploadConfig = {
  endpoint: '/api/clinic/images/upload',
  maxConcurrent: 3,
  retryAttempts: 3,
  retryDelay: 1000,
  timeout: 30000
}

/**
 * Classe para gerenciar uploads múltiplos
 */
export class MultipleUploadService {
  private config: UploadConfig
  private activeUploads = new Map<string, XMLHttpRequest>()
  protected uploadQueue: UploadProgress[] = []
  private isProcessing = false

  constructor(config: Partial<UploadConfig> = {}) {
    this.config = { ...DEFAULT_UPLOAD_CONFIG, ...config }
  }

  /**
   * Adicionar arquivos à fila de upload
   */
  addFiles(
    files: File[],
    onProgress?: (progress: UploadProgress[]) => void,
    onComplete?: (results: UploadProgress[]) => void
  ): Promise<UploadProgress[]> {
    return new Promise((resolve) => {
      // Criar objetos de progresso para cada arquivo
      const newUploads: UploadProgress[] = files.map(file => ({
        id: this.generateUploadId(),
        file,
        progress: 0,
        status: 'pending'
      }))

      this.uploadQueue.push(...newUploads)

      // Iniciar processamento se não estiver ativo
      if (!this.isProcessing) {
        this.processQueue(onProgress, onComplete, resolve)
      }
    })
  }

  /**
   * Cancelar upload específico
   */
  cancelUpload(id: string): void {
    const xhr = this.activeUploads.get(id)
    if (xhr) {
      xhr.abort()
      this.activeUploads.delete(id)
    }

    // Remover da fila se ainda não iniciado
    const queueIndex = this.uploadQueue.findIndex(upload => upload.id === id)
    if (queueIndex >= 0) {
      this.uploadQueue[queueIndex].status = 'error'
      this.uploadQueue[queueIndex].error = 'Cancelado pelo usuário'
    }
  }

  /**
   * Cancelar todos os uploads
   */
  cancelAllUploads(): void {
    // Cancelar uploads ativos
    this.activeUploads.forEach(xhr => xhr.abort())
    this.activeUploads.clear()

    // Marcar todos na fila como cancelados
    this.uploadQueue.forEach(upload => {
      if (upload.status === 'pending' || upload.status === 'uploading') {
        upload.status = 'error'
        upload.error = 'Cancelado pelo usuário'
      }
    })

    this.isProcessing = false
  }

  /**
   * Processar fila de uploads
   */
  private async processQueue(
    onProgress?: (progress: UploadProgress[]) => void,
    onComplete?: (results: UploadProgress[]) => void,
    resolve?: (results: UploadProgress[]) => void
  ): Promise<void> {
    this.isProcessing = true
    const concurrentUploads: Promise<void>[] = []

    while (this.uploadQueue.some(u => u.status === 'pending') || concurrentUploads.length > 0) {
      // Iniciar novos uploads até o limite de concorrência
      while (
        concurrentUploads.length < this.config.maxConcurrent &&
        this.uploadQueue.some(u => u.status === 'pending')
      ) {
        const nextUpload = this.uploadQueue.find(u => u.status === 'pending')
        if (nextUpload) {
          const uploadPromise = this.uploadFile(nextUpload, onProgress)
          concurrentUploads.push(uploadPromise)
        }
      }

      // Aguardar pelo menos um upload completar
      if (concurrentUploads.length > 0) {
        await Promise.race(concurrentUploads)
        
        // Remover uploads completados
        for (let i = concurrentUploads.length - 1; i >= 0; i--) {
          const promise = concurrentUploads[i]
          if (await this.isPromiseSettled(promise)) {
            concurrentUploads.splice(i, 1)
          }
        }
      }
    }

    this.isProcessing = false
    
    // Notificar conclusão
    if (onComplete) {
      onComplete([...this.uploadQueue])
    }
    
    if (resolve) {
      resolve([...this.uploadQueue])
    }
  }

  /**
   * Upload de um arquivo individual
   */
  protected uploadFile(
    uploadProgress: UploadProgress,
    onProgress?: (progress: UploadProgress[]) => void
  ): Promise<void> {
    return new Promise((resolve) => {
      uploadProgress.status = 'uploading'
      
      const formData = new FormData()
      formData.append('file', uploadProgress.file)
      formData.append('id', uploadProgress.id)

      const xhr = new XMLHttpRequest()
      this.activeUploads.set(uploadProgress.id, xhr)

      // Progress handler
      xhr.upload.onprogress = (event) => {
        if (event.lengthComputable) {
          uploadProgress.progress = Math.round((event.loaded / event.total) * 100)
          if (onProgress) {
            onProgress([...this.uploadQueue])
          }
        }
      }

      // Success handler
      xhr.onload = () => {
        this.activeUploads.delete(uploadProgress.id)
        
        if (xhr.status >= 200 && xhr.status < 300) {
          try {
            const response: UploadResponse = JSON.parse(xhr.responseText)
            if (response.success) {
              uploadProgress.status = 'success'
              uploadProgress.url = response.url
              uploadProgress.progress = 100
            } else {
              uploadProgress.status = 'error'
              uploadProgress.error = response.error || 'Erro desconhecido'
            }
          } catch {
            uploadProgress.status = 'error'
            uploadProgress.error = 'Resposta inválida do servidor'
          }
        } else {
          uploadProgress.status = 'error'
          uploadProgress.error = `Erro HTTP: ${xhr.status}`
        }

        if (onProgress) {
          onProgress([...this.uploadQueue])
        }
        resolve()
      }

      // Error handler
      xhr.onerror = () => {
        this.activeUploads.delete(uploadProgress.id)
        uploadProgress.status = 'error'
        uploadProgress.error = 'Erro de rede'
        
        if (onProgress) {
          onProgress([...this.uploadQueue])
        }
        resolve()
      }

      // Abort handler
      xhr.onabort = () => {
        this.activeUploads.delete(uploadProgress.id)
        uploadProgress.status = 'error'
        uploadProgress.error = 'Upload cancelado'
        
        if (onProgress) {
          onProgress([...this.uploadQueue])
        }
        resolve()
      }

      // Timeout
      xhr.timeout = this.config.timeout

      xhr.ontimeout = () => {
        this.activeUploads.delete(uploadProgress.id)
        uploadProgress.status = 'error'
        uploadProgress.error = 'Timeout do upload'
        
        if (onProgress) {
          onProgress([...this.uploadQueue])
        }
        resolve()
      }

      // Iniciar upload
      xhr.open('POST', this.config.endpoint)
      xhr.send(formData)
    })
  }

  /**
   * Retry de upload com falha
   */
  async retryUpload(
    id: string,
    onProgress?: (progress: UploadProgress[]) => void
  ): Promise<void> {
    const upload = this.uploadQueue.find(u => u.id === id)
    if (!upload || upload.status !== 'error') {
      return
    }

    upload.status = 'pending'
    upload.progress = 0
    delete upload.error
    delete upload.url

    // Adicionar de volta à fila se não estiver processando
    if (!this.isProcessing) {
      await this.processQueue(onProgress)
    }
  }

  /**
   * Retry de todos os uploads com falha
   */
  async retryFailedUploads(
    onProgress?: (progress: UploadProgress[]) => void
  ): Promise<void> {
    const failedUploads = this.uploadQueue.filter(u => u.status === 'error')
    
    failedUploads.forEach(upload => {
      upload.status = 'pending'
      upload.progress = 0
      delete upload.error
      delete upload.url
    })

    if (failedUploads.length > 0 && !this.isProcessing) {
      await this.processQueue(onProgress)
    }
  }

  /**
   * Limpar fila de uploads
   */
  clearQueue(): void {
    this.cancelAllUploads()
    this.uploadQueue.length = 0
  }

  /**
   * Obter status atual de todos os uploads
   */
  getUploadStatus(): UploadProgress[] {
    return [...this.uploadQueue]
  }

  /**
   * Verificar se upload está completo
   */
  isUploadComplete(): boolean {
    return this.uploadQueue.length > 0 && 
           this.uploadQueue.every(u => u.status === 'success' || u.status === 'error')
  }

  /**
   * Obter estatísticas dos uploads
   */
  getUploadStats(): {
    total: number
    pending: number
    uploading: number
    success: number
    error: number
    progress: number
  } {
    const stats = {
      total: this.uploadQueue.length,
      pending: 0,
      uploading: 0,
      success: 0,
      error: 0,
      progress: 0
    }

    if (stats.total === 0) return stats

    this.uploadQueue.forEach(upload => {
      stats[upload.status]++
      stats.progress += upload.progress
    })

    stats.progress = Math.round(stats.progress / stats.total)
    return stats
  }

  /**
   * Gerar ID único para upload
   */
  private generateUploadId(): string {
    return `upload_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
  }

  /**
   * Verificar se Promise foi resolvida
   */
  private async isPromiseSettled(promise: Promise<any>): Promise<boolean> {
    try {
      const result = await Promise.race([
        promise,
        new Promise(resolve => setTimeout(() => resolve('__timeout__'), 0))
      ])
      return result !== '__timeout__'
    } catch {
      return true
    }
  }
}

/**
 * Instância singleton do serviço de upload
 */
export const uploadService = new MultipleUploadService()

/**
 * Hook simulado para demonstração (sem API real)
 */
export class MockUploadService extends MultipleUploadService {
  constructor(config: Partial<UploadConfig> = {}) {
    super(config)
  }

  public async uploadFile(
    uploadProgress: UploadProgress,
    onProgress?: (progress: UploadProgress[]) => void
  ): Promise<void> {
    return new Promise((resolve) => {
      uploadProgress.status = 'uploading'

      // Simular progresso de upload
      const simulateProgress = (progress: number) => {
        uploadProgress.progress = progress
        if (onProgress) {
          onProgress([...this.uploadQueue])
        }
      }

      // Simular upload com progresso
      const progressInterval = setInterval(() => {
        const currentProgress = uploadProgress.progress
        const nextProgress = Math.min(currentProgress + Math.random() * 20, 95)
        simulateProgress(nextProgress)

        if (nextProgress >= 95) {
          clearInterval(progressInterval)
          
          // Simular resposta do servidor
          setTimeout(() => {
            // 90% de chance de sucesso
            if (Math.random() > 0.1) {
              uploadProgress.status = 'success'
              uploadProgress.progress = 100
              uploadProgress.url = `https://example.com/images/${uploadProgress.id}_${uploadProgress.file.name}`
            } else {
              uploadProgress.status = 'error'
              uploadProgress.error = 'Simulação de erro de upload'
            }
            
            if (onProgress) {
              onProgress([...this.uploadQueue])
            }
            resolve()
          }, 500)
        }
      }, 200)
    })
  }
}

/**
 * Instância mock para testes e desenvolvimento
 */
export const mockUploadService = new MockUploadService()