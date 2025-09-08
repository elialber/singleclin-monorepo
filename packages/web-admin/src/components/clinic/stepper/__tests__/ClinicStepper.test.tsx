import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { ClinicStepper } from '../core/ClinicStepper'
import { ClinicFormData } from '../../../../types/stepper'
import { ClinicType } from '../../../../types/clinic'

// Mock dos hooks
vi.mock('../hooks/useClinicStepper', () => ({
  useClinicStepper: () => ({
    state: {
      currentStep: 0,
      isValid: [false, false, false, false],
      isDirty: [false, false, false, false]
    },
    currentStepInfo: {
      label: 'Informações Básicas',
      description: 'Dados básicos da clínica'
    },
    stepInfos: [
      { label: 'Básicas', description: 'Dados básicos', isCompleted: false, hasErrors: false },
      { label: 'Endereço', description: 'Localização', isCompleted: false, hasErrors: false },
      { label: 'Imagens', description: 'Fotos', isCompleted: false, hasErrors: false },
      { label: 'Revisão', description: 'Confirmar', isCompleted: false, hasErrors: false }
    ],
    progress: { current: 1, total: 4, percentage: 25 },
    isLoading: false,
    totalErrors: 0
  })
}))

vi.mock('../hooks/useDraftSaver', () => ({
  useDraftSaver: () => ({
    currentDraftId: null,
    hasUnsavedChanges: false,
    isAutoSaving: false,
    lastSavedAt: null,
    availableDrafts: [],
    saveDraftManually: vi.fn(),
    loadDraft: vi.fn(),
    deleteDraft: vi.fn(),
    clearAllDrafts: vi.fn(),
    refreshDraftsList: vi.fn(),
    getRecentDraft: vi.fn(() => null),
    exportDraft: vi.fn(),
    importDraft: vi.fn()
  })
}))

// Mock dos steps
vi.mock('../steps/Step1BasicInfo', () => ({
  default: () => <div data-testid="step-1">Step 1 Content</div>
}))

vi.mock('../steps/Step2AddressLocation', () => ({
  default: () => <div data-testid="step-2">Step 2 Content</div>
}))

vi.mock('../steps/Step3ImageUpload', () => ({
  default: () => <div data-testid="step-3">Step 3 Content</div>
}))

vi.mock('../steps/Step4Review', () => ({
  default: () => <div data-testid="step-4">Step 4 Content</div>
}))

describe('ClinicStepper', () => {
  const defaultProps = {
    onSubmit: vi.fn(),
    title: 'Test Stepper'
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should render stepper with correct title', () => {
    render(<ClinicStepper {...defaultProps} />)

    expect(screen.getByText('Test Stepper')).toBeInTheDocument()
  })

  it('should render current step description', () => {
    render(<ClinicStepper {...defaultProps} />)

    expect(screen.getByText('Dados básicos da clínica')).toBeInTheDocument()
  })

  it('should render progress indicator', () => {
    render(<ClinicStepper {...defaultProps} />)

    expect(screen.getByText('Step 1 de 4')).toBeInTheDocument()
    expect(screen.getByText('25% completo')).toBeInTheDocument()
  })

  it('should render current step content', async () => {
    render(<ClinicStepper {...defaultProps} />)

    // Should render Step 1 by default
    await waitFor(() => {
      expect(screen.getByTestId('step-1')).toBeInTheDocument()
    })
  })

  it('should handle compact mode', () => {
    render(<ClinicStepper {...defaultProps} compact />)

    // In compact mode, should still render the stepper
    expect(screen.getByText('Test Stepper')).toBeInTheDocument()
  })

  it('should handle onCancel callback', () => {
    const onCancel = vi.fn()
    render(<ClinicStepper {...defaultProps} onCancel={onCancel} />)

    // Should render with cancel option available
    expect(screen.getByText('Test Stepper')).toBeInTheDocument()
  })

  it('should handle onError callback', () => {
    const onError = vi.fn()
    render(<ClinicStepper {...defaultProps} onError={onError} />)

    expect(screen.getByText('Test Stepper')).toBeInTheDocument()
  })

  it('should handle onStepChange callback', () => {
    const onStepChange = vi.fn()
    render(<ClinicStepper {...defaultProps} onStepChange={onStepChange} />)

    expect(screen.getByText('Test Stepper')).toBeInTheDocument()
  })

  it('should handle initial data', () => {
    const initialData: Partial<ClinicFormData> = {
      basicInfo: {
        name: 'Test Clinic',
        type: ClinicType.Regular,
        cnpj: '11.222.333/0001-81',
        phone: '(11) 99999-9999',
        email: 'test@clinic.com',
        isActive: true
      }
    }

    render(<ClinicStepper {...defaultProps} initialData={initialData} />)

    expect(screen.getByText('Test Stepper')).toBeInTheDocument()
  })

  it('should handle draft ID', () => {
    render(<ClinicStepper {...defaultProps} draftId="test-draft-123" />)

    expect(screen.getByText('Test Stepper')).toBeInTheDocument()
  })

  it('should disable auto-save when specified', () => {
    render(<ClinicStepper {...defaultProps} disableAutoSave />)

    // Should not show auto-save related messages
    expect(screen.queryByText(/automaticamente/)).not.toBeInTheDocument()
  })

  it('should render desktop layout with sidebar', () => {
    // Mock desktop viewport
    Object.defineProperty(window, 'innerWidth', {
      writable: true,
      configurable: true,
      value: 1024,
    })

    render(<ClinicStepper {...defaultProps} />)

    // Should render stepper indicator
    expect(screen.getByText('Test Stepper')).toBeInTheDocument()
  })

  it('should handle loading state', () => {
    // Mock loading state
    vi.mocked(vi.importActual('../hooks/useClinicStepper')).useClinicStepper = () => ({
      state: {
        currentStep: 0,
        isValid: [false, false, false, false],
        isDirty: [false, false, false, false]
      },
      currentStepInfo: {
        label: 'Informações Básicas',
        description: 'Dados básicos da clínica'
      },
      stepInfos: [],
      progress: { current: 1, total: 4, percentage: 25 },
      isLoading: true,
      totalErrors: 0
    })

    render(<ClinicStepper {...defaultProps} />)

    expect(screen.getByText('Processando...')).toBeInTheDocument()
  })
})

describe('ClinicStepper Integration Tests', () => {
  const defaultProps = {
    onSubmit: vi.fn(),
    title: 'Integration Test'
  }

  it('should handle complete flow simulation', async () => {
    const user = userEvent.setup()
    const onSubmit = vi.fn()

    render(<ClinicStepper {...defaultProps} onSubmit={onSubmit} />)

    // Should start at step 1
    await waitFor(() => {
      expect(screen.getByTestId('step-1')).toBeInTheDocument()
    })

    // Simulate step completion would require more complex mocking
    // of the step components and navigation logic
  })

  it('should handle error states', () => {
    // Mock error state
    vi.mocked(vi.importActual('../hooks/useClinicStepper')).useClinicStepper = () => ({
      state: {
        currentStep: 0,
        isValid: [false, false, false, false],
        isDirty: [true, false, false, false]
      },
      currentStepInfo: {
        label: 'Informações Básicas',
        description: 'Dados básicos da clínica'
      },
      stepInfos: [],
      progress: { current: 1, total: 4, percentage: 25 },
      isLoading: false,
      totalErrors: 2
    })

    render(<ClinicStepper {...defaultProps} />)

    expect(screen.getByText(/2 campos que precisam ser corrigidos/)).toBeInTheDocument()
  })

  it('should handle draft system integration', () => {
    // Mock draft system with available drafts
    vi.mocked(vi.importActual('../hooks/useDraftSaver')).useDraftSaver = () => ({
      currentDraftId: 'draft-123',
      hasUnsavedChanges: true,
      isAutoSaving: false,
      lastSavedAt: new Date(),
      availableDrafts: [
        {
          id: 'draft-123',
          title: 'Test Draft',
          createdAt: new Date(),
          updatedAt: new Date(),
          stepCompleted: 1,
          formData: {},
          isAutoSaved: true
        }
      ],
      saveDraftManually: vi.fn(),
      loadDraft: vi.fn(),
      deleteDraft: vi.fn(),
      clearAllDrafts: vi.fn(),
      refreshDraftsList: vi.fn(),
      getRecentDraft: vi.fn(),
      exportDraft: vi.fn(),
      importDraft: vi.fn()
    })

    render(<ClinicStepper {...defaultProps} />)

    expect(screen.getByText(/automaticamente a cada 30 segundos/)).toBeInTheDocument()
  })
})