import React, { Suspense, useState, useEffect } from 'react'
import {
  Box,
  Container,
  Paper,
  LinearProgress,
  Alert,
  Backdrop,
  CircularProgress,
  Typography
} from '@mui/material'
import { StepperProvider } from './StepperProvider'
import { StepperIndicator } from './StepperIndicator'
import { StepperNavigation } from './StepperNavigation'
import { useClinicStepper } from '../hooks/useClinicStepper'
import { ClinicFormData } from '../../../../types/stepper'

// Lazy loading dos steps para melhor performance
const Step1BasicInfo = React.lazy(() => import('../steps/Step1BasicInfo'))
const Step2AddressLocation = React.lazy(() => import('../steps/Step2AddressLocation'))
const Step3Services = React.lazy(() => import('../steps/Step3Services'))
const Step4ImageUpload = React.lazy(() => import('../steps/Step4ImageUpload'))
const Step5Review = React.lazy(() => import('../steps/Step5Review'))

interface ClinicStepperProps {
  /** Dados iniciais do formulário (para edição) */
  initialData?: Partial<ClinicFormData>
  
  
  /** Callback chamado ao submeter o formulário */
  onSubmit: (data: ClinicFormData) => Promise<void>
  
  /** Callback chamado quando o step atual muda */
  onStepChange?: (stepIndex: number) => void
  
  /** Callback chamado em caso de erro */
  onError?: (error: Error) => void
  
  /** Callback chamado ao cancelar */
  onCancel?: () => void
  
  /** Título customizado */
  title?: string
  
  /** Modo compacto (sem container/padding) */
  compact?: boolean
  
}

/**
 * Componente principal do stepper de cadastro de clínica
 * 
 * Gerencia a navegação entre steps, validação e submissão do formulário
 */
export function ClinicStepper({
  initialData,
  onSubmit,
  onStepChange,
  onError,
  onCancel,
  title = 'Cadastro de Clínica',
  compact = false
}: ClinicStepperProps) {
  return (
    <StepperProvider
      initialData={initialData}
      onSubmit={onSubmit}
      onStepChange={onStepChange}
      onError={onError}
    >
      <StepperContent
        title={title}
        compact={compact}
        onCancel={onCancel}
      />
    </StepperProvider>
  )
}

/**
 * Conteúdo interno do stepper (separado para usar o contexto)
 */
function StepperContent({
  title,
  compact,
  onCancel
}: {
  title: string
  compact: boolean
  onCancel?: () => void
}) {
  const {
    state,
    currentStepInfo,
    stepInfos,
    progress,
    isLoading,
    totalErrors
  } = useClinicStepper()


  // Componente do step atual
  const renderCurrentStep = () => {
    const stepProps = {
      onNext: () => {}, // Será gerenciado pelo StepperNavigation
      onPrev: () => {}, // Será gerenciado pelo StepperNavigation
      isValid: state.isValid[state.currentStep],
      isDirty: state.isDirty[state.currentStep]
    }

    switch (state.currentStep) {
      case 0:
        return (
          <Suspense fallback={<StepLoader />}>
            <Step1BasicInfo {...stepProps} />
          </Suspense>
        )
      case 1:
        return (
          <Suspense fallback={<StepLoader />}>
            <Step2AddressLocation {...stepProps} />
          </Suspense>
        )
      case 2:
        return (
          <Suspense fallback={<StepLoader />}>
            <Step3Services {...stepProps} />
          </Suspense>
        )
      case 3:
        return (
          <Suspense fallback={<StepLoader />}>
            <Step4ImageUpload {...stepProps} />
          </Suspense>
        )
      case 4:
        return (
          <Suspense fallback={<StepLoader />}>
            <Step5Review {...stepProps} />
          </Suspense>
        )
      default:
        return <div>Step não encontrado</div>
    }
  }

  const content = (
    <Box sx={{ width: '100%', minHeight: '100vh', bgcolor: 'grey.50' }}>
      {/* Loading backdrop */}
      <Backdrop
        sx={{ color: '#fff', zIndex: (theme) => theme.zIndex.drawer + 1 }}
        open={isLoading}
      >
        <Box textAlign="center">
          <CircularProgress color="inherit" />
          <Typography variant="body1" sx={{ mt: 2 }}>
            Processando...
          </Typography>
        </Box>
      </Backdrop>

      {/* Header */}
      <Box
        sx={{
          bgcolor: 'primary.main',
          color: 'primary.contrastText',
          py: 3,
          mb: 2
        }}
      >
        <Container maxWidth="lg">
          <Typography variant="h4" component="h1" gutterBottom>
            {title}
          </Typography>
          <Typography variant="body1" sx={{ opacity: 0.9 }}>
            {currentStepInfo.description}
          </Typography>
          
          {/* Progress bar */}
          <Box sx={{ mt: 2 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
              <Typography variant="body2">
                Step {progress.current} de {progress.total}
              </Typography>
              <Typography variant="body2">
                {progress.percentage}% completo
              </Typography>
            </Box>
            <LinearProgress
              variant="determinate"
              value={progress.percentage}
              sx={{
                height: 8,
                borderRadius: 4,
                bgcolor: 'rgba(255,255,255,0.2)',
                '& .MuiLinearProgress-bar': {
                  borderRadius: 4
                }
              }}
            />
          </Box>
        </Container>
      </Box>

      {/* Alerts */}
      <Container maxWidth="lg" sx={{ mb: 2 }}>
        {/* Erros de validação */}
        {totalErrors > 0 && (
          <Alert severity="warning" sx={{ mb: 1 }}>
            {totalErrors === 1 
              ? 'Existe 1 campo que precisa ser corrigido.'
              : `Existem ${totalErrors} campos que precisam ser corrigidos.`
            }
          </Alert>
        )}
      </Container>

      {/* Main content */}
      <Container maxWidth="lg">
        <Box sx={{ display: 'flex', gap: 3 }}>
          {/* Stepper indicator (sidebar) */}
          <Box
            sx={{
              minWidth: 280,
              display: { xs: 'none', md: 'block' }
            }}
          >
            <Paper sx={{ p: 2, position: 'sticky', top: 20 }}>
              <StepperIndicator
                steps={stepInfos}
                currentStep={state.currentStep}
                orientation="vertical"
              />
            </Paper>
          </Box>

          {/* Step content */}
          <Box sx={{ flex: 1 }}>
            <Paper
              sx={{
                p: { xs: 2, sm: 3, md: 4 },
                mb: 3,
                minHeight: 400
              }}
            >
              {/* Mobile stepper indicator */}
              <Box sx={{ display: { xs: 'block', md: 'none' }, mb: 3 }}>
                <StepperIndicator
                  steps={stepInfos}
                  currentStep={state.currentStep}
                  orientation="horizontal"
                  compact
                />
              </Box>

              {/* Step content */}
              <Box sx={{ mb: 4 }}>
                {renderCurrentStep()}
              </Box>
            </Paper>

            {/* Navigation */}
            <Paper sx={{ p: 2 }}>
              <StepperNavigation onCancel={onCancel} />
            </Paper>
          </Box>
        </Box>
      </Container>

    </Box>
  )

  return compact ? (
    <Box sx={{ p: 2 }}>
      {content}
    </Box>
  ) : (
    content
  )
}

/**
 * Loading component para steps
 */
function StepLoader() {
  return (
    <Box
      sx={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        minHeight: 300
      }}
    >
      <CircularProgress />
    </Box>
  )
}

export default ClinicStepper