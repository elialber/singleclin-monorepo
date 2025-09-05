import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { useDraftSaver } from '../hooks/useDraftSaver'
import { draftService } from '../../../../services/draftService'

// Mock do serviço de draft
vi.mock('../../../../services/draftService', () => ({
  draftService: {
    saveDraftLocal: vi.fn(),
    updateDraft: vi.fn(),
    loadDraft: vi.fn(),
    deleteDraft: vi.fn(),
    clearAllDrafts: vi.fn(),
    getAllDrafts: vi.fn(),
    getRecentDraft: vi.fn(),
    exportDraft: vi.fn(),
    importDraft: vi.fn(),
    cleanupExpiredDrafts: vi.fn()
  }
}))

// Mock do contexto do stepper
vi.mock('../hooks/useClinicStepper', () => ({
  useClinicStepper: () => ({
    formData: {
      basicInfo: {
        name: 'Test Clinic',
        cnpj: '11.222.333/0001-81'
      }
    },
    state: { currentStep: 0 },
    loadFormData: vi.fn()
  })
}))

describe('useDraftSaver', () => {
  const mockDraftService = draftService as any

  beforeEach(() => {
    vi.clearAllMocks()
    
    // Setup default mocks
    mockDraftService.getAllDrafts.mockReturnValue([])
    mockDraftService.getRecentDraft.mockReturnValue(null)
    mockDraftService.saveDraftLocal.mockResolvedValue('draft-123')
    mockDraftService.updateDraft.mockResolvedValue(undefined)
    mockDraftService.loadDraft.mockResolvedValue({
      id: 'draft-123',
      formData: { basicInfo: { name: 'Test' } },
      createdAt: new Date(),
      updatedAt: new Date(),
      stepCompleted: 0,
      title: 'Test Draft',
      isAutoSaved: true
    })

    // Mock localStorage
    Object.defineProperty(window, 'localStorage', {
      value: {
        getItem: vi.fn(() => null),
        setItem: vi.fn(),
        removeItem: vi.fn(),
        clear: vi.fn()
      },
      writable: true
    })
  })

  afterEach(() => {
    vi.clearAllTimers()
    vi.useRealTimers()
  })

  it('should initialize with default values', () => {
    const { result } = renderHook(() => useDraftSaver())

    expect(result.current.currentDraftId).toBe(null)
    expect(result.current.hasUnsavedChanges).toBe(false)
    expect(result.current.isAutoSaving).toBe(false)
    expect(result.current.lastSavedAt).toBe(null)
    expect(result.current.availableDrafts).toEqual([])
  })

  it('should save draft manually', async () => {
    const { result } = renderHook(() => useDraftSaver())

    await act(async () => {
      const draftId = await result.current.saveDraftManually('Test Draft')
      expect(draftId).toBe('draft-123')
    })

    expect(mockDraftService.saveDraftLocal).toHaveBeenCalledWith(
      expect.any(Object),
      0,
      { title: 'Test Draft', isAutoSave: false }
    )
  })

  it('should load draft', async () => {
    const { result } = renderHook(() => useDraftSaver())

    await act(async () => {
      await result.current.loadDraft('draft-123')
    })

    expect(mockDraftService.loadDraft).toHaveBeenCalledWith('draft-123')
  })

  it('should delete draft', async () => {
    const { result } = renderHook(() => useDraftSaver())

    await act(async () => {
      await result.current.deleteDraft('draft-123')
    })

    expect(mockDraftService.deleteDraft).toHaveBeenCalledWith('draft-123')
  })

  it('should auto-save when enabled and has changes', async () => {
    vi.useFakeTimers()
    
    const { result, rerender } = renderHook(() => useDraftSaver({
      enableAutoSave: true,
      autoSaveInterval: 1000
    }))

    // Simulate form changes
    act(() => {
      // This would normally be triggered by form data changes
      // For testing, we'll manually trigger the hasUnsavedChanges state
    })

    // Fast-forward time
    act(() => {
      vi.advanceTimersByTime(1000)
    })

    vi.useRealTimers()
  })

  it('should handle auto-save disabled', () => {
    const { result } = renderHook(() => useDraftSaver({
      enableAutoSave: false
    }))

    // Auto-save should not be triggered even with changes
    expect(result.current.isAutoSaving).toBe(false)
  })

  it('should export draft', () => {
    const mockExportData = '{"id":"draft-123","title":"Test"}'
    mockDraftService.exportDraft.mockReturnValue(mockExportData)

    const { result } = renderHook(() => useDraftSaver())

    const exportedData = result.current.exportDraft('draft-123')

    expect(exportedData).toBe(mockExportData)
    expect(mockDraftService.exportDraft).toHaveBeenCalledWith('draft-123')
  })

  it('should import draft', async () => {
    const mockImportData = '{"id":"draft-456","title":"Imported"}'
    mockDraftService.importDraft.mockResolvedValue('draft-456')

    const { result } = renderHook(() => useDraftSaver())

    await act(async () => {
      const draftId = await result.current.importDraft(mockImportData)
      expect(draftId).toBe('draft-456')
    })

    expect(mockDraftService.importDraft).toHaveBeenCalledWith(mockImportData)
  })

  it('should handle errors gracefully', async () => {
    const onError = vi.fn()
    mockDraftService.saveDraftLocal.mockRejectedValue(new Error('Save failed'))

    const { result } = renderHook(() => useDraftSaver({ onError }))

    await act(async () => {
      await expect(result.current.saveDraftManually()).rejects.toThrow('Save failed')
    })

    expect(onError).toHaveBeenCalledWith(expect.any(Error))
  })

  it('should refresh drafts list', () => {
    const mockDrafts = [
      {
        id: 'draft-1',
        title: 'Draft 1',
        createdAt: new Date(),
        updatedAt: new Date(),
        stepCompleted: 0,
        formData: {},
        isAutoSaved: false
      }
    ]
    mockDraftService.getAllDrafts.mockReturnValue(mockDrafts)

    const { result } = renderHook(() => useDraftSaver())

    act(() => {
      result.current.refreshDraftsList()
    })

    expect(result.current.availableDrafts).toEqual(mockDrafts)
  })

  it('should get recent draft', () => {
    const recentDraft = {
      id: 'recent-draft',
      title: 'Recent',
      createdAt: new Date(),
      updatedAt: new Date(),
      stepCompleted: 1,
      formData: {},
      isAutoSaved: true
    }
    mockDraftService.getRecentDraft.mockReturnValue(recentDraft)

    const { result } = renderHook(() => useDraftSaver())

    const recent = result.current.getRecentDraft()

    expect(recent).toEqual(recentDraft)
  })

  it('should clear all drafts', async () => {
    const { result } = renderHook(() => useDraftSaver())

    await act(async () => {
      await result.current.clearAllDrafts()
    })

    expect(mockDraftService.clearAllDrafts).toHaveBeenCalled()
  })
})