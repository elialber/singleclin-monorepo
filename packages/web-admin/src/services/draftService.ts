import { ClinicFormData } from '../types/stepper'

export interface DraftData {
  id: string
  formData: Partial<ClinicFormData>
  createdAt: Date
  updatedAt: Date
  stepCompleted: number
  title: string
  isAutoSaved: boolean
}

export interface DraftSaveOptions {
  isAutoSave?: boolean
  title?: string
}

class DraftService {
  private readonly STORAGE_KEY = 'clinic-stepper-drafts'
  private readonly MAX_DRAFTS = 10
  private readonly DRAFT_EXPIRY_DAYS = 30

  /**
   * Salva um rascunho localmente
   */
  async saveDraftLocal(
    formData: Partial<ClinicFormData>, 
    stepCompleted: number,
    options: DraftSaveOptions = {}
  ): Promise<string> {
    const drafts = this.getAllDrafts()
    
    const draftId = this.generateDraftId()
    const now = new Date()
    
    const newDraft: DraftData = {
      id: draftId,
      formData,
      createdAt: now,
      updatedAt: now,
      stepCompleted,
      title: options.title || this.generateDraftTitle(formData),
      isAutoSaved: options.isAutoSave || false
    }
    
    // Adicionar novo draft no início da lista
    drafts.unshift(newDraft)
    
    // Limitar número de drafts
    if (drafts.length > this.MAX_DRAFTS) {
      drafts.splice(this.MAX_DRAFTS)
    }
    
    // Salvar no localStorage
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(drafts))
    
    return draftId
  }

  /**
   * Atualiza um rascunho existente
   */
  async updateDraft(
    draftId: string,
    formData: Partial<ClinicFormData>,
    stepCompleted: number,
    options: DraftSaveOptions = {}
  ): Promise<void> {
    const drafts = this.getAllDrafts()
    const draftIndex = drafts.findIndex(d => d.id === draftId)
    
    if (draftIndex === -1) {
      throw new Error(`Draft com ID ${draftId} não encontrado`)
    }
    
    // Atualizar draft existente
    drafts[draftIndex] = {
      ...drafts[draftIndex],
      formData,
      stepCompleted,
      updatedAt: new Date(),
      title: options.title || drafts[draftIndex].title,
      isAutoSaved: options.isAutoSave || drafts[draftIndex].isAutoSaved
    }
    
    // Mover para o início da lista se foi atualizado
    const updatedDraft = drafts.splice(draftIndex, 1)[0]
    drafts.unshift(updatedDraft)
    
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(drafts))
  }

  /**
   * Carrega um rascunho específico
   */
  async loadDraft(draftId: string): Promise<DraftData | null> {
    const drafts = this.getAllDrafts()
    return drafts.find(d => d.id === draftId) || null
  }

  /**
   * Lista todos os rascunhos
   */
  getAllDrafts(): DraftData[] {
    try {
      const stored = localStorage.getItem(this.STORAGE_KEY)
      if (!stored) return []
      
      const drafts = JSON.parse(stored) as DraftData[]
      
      // Converter strings de data de volta para Date objects
      return drafts.map(draft => ({
        ...draft,
        createdAt: new Date(draft.createdAt),
        updatedAt: new Date(draft.updatedAt)
      })).filter(draft => !this.isDraftExpired(draft))
      
    } catch (error) {
      console.error('Erro ao carregar drafts:', error)
      return []
    }
  }

  /**
   * Remove um rascunho específico
   */
  async deleteDraft(draftId: string): Promise<void> {
    const drafts = this.getAllDrafts()
    const filteredDrafts = drafts.filter(d => d.id !== draftId)
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(filteredDrafts))
  }

  /**
   * Remove todos os rascunhos
   */
  async clearAllDrafts(): Promise<void> {
    localStorage.removeItem(this.STORAGE_KEY)
  }

  /**
   * Remove rascunhos expirados (mais de 30 dias)
   */
  async cleanupExpiredDrafts(): Promise<number> {
    const drafts = this.getAllDrafts()
    const validDrafts = drafts.filter(draft => !this.isDraftExpired(draft))
    const removedCount = drafts.length - validDrafts.length
    
    if (removedCount > 0) {
      localStorage.setItem(this.STORAGE_KEY, JSON.stringify(validDrafts))
    }
    
    return removedCount
  }

  /**
   * Verifica se existe um rascunho recente (últimas 24h)
   */
  getRecentDraft(): DraftData | null {
    const drafts = this.getAllDrafts()
    const yesterday = new Date()
    yesterday.setHours(yesterday.getHours() - 24)
    
    return drafts.find(draft => 
      draft.updatedAt > yesterday && draft.isAutoSaved
    ) || null
  }

  /**
   * Exporta rascunho para backup
   */
  exportDraft(draftId: string): string {
    const draft = this.getAllDrafts().find(d => d.id === draftId)
    if (!draft) {
      throw new Error(`Draft com ID ${draftId} não encontrado`)
    }
    
    return JSON.stringify(draft, null, 2)
  }

  /**
   * Importa rascunho de backup
   */
  async importDraft(draftJson: string): Promise<string> {
    try {
      const draft = JSON.parse(draftJson) as DraftData
      
      // Gerar novo ID para evitar conflitos
      const newDraftId = this.generateDraftId()
      draft.id = newDraftId
      draft.createdAt = new Date()
      draft.updatedAt = new Date()
      
      const drafts = this.getAllDrafts()
      drafts.unshift(draft)
      
      localStorage.setItem(this.STORAGE_KEY, JSON.stringify(drafts))
      
      return newDraftId
    } catch (error) {
      throw new Error('JSON de draft inválido')
    }
  }

  // Métodos privados

  private generateDraftId(): string {
    return `draft_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
  }

  private generateDraftTitle(formData: Partial<ClinicFormData>): string {
    if (formData.basicInfo?.name) {
      return `Rascunho: ${formData.basicInfo.name}`
    }
    
    const now = new Date()
    return `Rascunho ${now.toLocaleDateString()} ${now.toLocaleTimeString()}`
  }

  private isDraftExpired(draft: DraftData): boolean {
    const expiryDate = new Date()
    expiryDate.setDate(expiryDate.getDate() - this.DRAFT_EXPIRY_DAYS)
    return draft.createdAt < expiryDate
  }
}

export const draftService = new DraftService()
export default draftService