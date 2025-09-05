import React, { useState } from 'react'
import {
  Box,
  Button,
  ButtonGroup,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Typography
} from '@mui/material'
import {
  ArrowBack,
  ArrowForward,
  Cancel,
  Check,
  Warning
} from '@mui/icons-material'
import { useClinicStepper } from '../hooks/useClinicStepper'

interface StepperNavigationProps {
  /** Callback chamado ao cancelar */
  onCancel?: () => void
  
  /** Texto customizado dos botões */
  buttonLabels?: {
    prev?: string
    next?: string
    submit?: string
    cancel?: string
  }
  
  /** Variante dos botões */
  variant?: 'text' | 'outlined' | 'contained'
  
  /** Tamanho dos botões */
  size?: 'small' | 'medium' | 'large'
}

/**
 * Componente de navegação do stepper
 * 
 * Fornece botões para navegar entre steps, salvar rascunho e submeter
 */
export function StepperNavigation({
  onCancel,
  buttonLabels = {},
  variant = 'contained',
  size = 'medium'
}: StepperNavigationProps) {
  const {
    nextStep,
    prevStep,
    canGoNext,
    canGoPrev,
    isFirstStep,
    isLastStep,
    isLoading,
    totalErrors,
    submitForm,
    currentStepInfo,
    validateStep,
    state
  } = useClinicStepper()

  const [showCancelDialog, setShowCancelDialog] = useState(false)

  // Labels dos botões
  const labels = {
    prev: buttonLabels.prev || 'Voltar',
    next: buttonLabels.next || 'Próximo',
    submit: buttonLabels.submit || 'Finalizar Cadastro',
    cancel: buttonLabels.cancel || 'Cancelar',
    ...buttonLabels
  }

  // Handler para próximo step
  const handleNext = async () => {
    try {
      if (isLastStep) {
        // Última etapa - submeter formulário
        await submitForm()
      } else {
        // Validar step atual antes de prosseguir
        const isValid = await validateStep(state.currentStep)
        if (isValid) {
          nextStep()
        }
      }
    } catch (error) {
      console.error('Error on next step:', error)
    }
  }

  // Handler para voltar
  const handlePrev = () => {
    prevStep()
  }


  // Handler para cancelar
  const handleCancel = () => {
    setShowCancelDialog(true)
  }

  // Confirmar cancelamento
  const confirmCancel = () => {
    setShowCancelDialog(false)
    onCancel?.()
  }

  return (
    <>
      <Box
        sx={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: 2
        }}
      >
        {/* Lado esquerdo - Informações do step atual */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Typography variant="body2" color="text.secondary">
            {currentStepInfo.icon} {currentStepInfo.title}
          </Typography>
          
          {totalErrors > 0 && (
            <Tooltip title={`${totalErrors} campo(s) com erro`}>
              <Warning color="warning" fontSize="small" />
            </Tooltip>
          )}
          
          {currentStepInfo.isValid && currentStepInfo.isDirty && (
            <Tooltip title="Step válido">
              <Check color="success" fontSize="small" />
            </Tooltip>
          )}
        </Box>

        {/* Lado direito - Botões de ação */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>

          {/* Navegação principal */}
          <ButtonGroup variant={variant} size={size}>
            {/* Voltar */}
            <Button
              onClick={handlePrev}
              disabled={!canGoPrev || isLoading}
              startIcon={<ArrowBack />}
              sx={{ 
                minWidth: 100,
                backgroundColor: 'grey.600',
                color: 'white',
                '&:hover': {
                  backgroundColor: 'grey.700',
                },
                '&:disabled': {
                  backgroundColor: 'grey.300',
                  color: 'grey.500',
                }
              }}
            >
              {labels.prev}
            </Button>

            {/* Próximo - Ocultar Finalizar no último step */}
            {!isLastStep && (
              <Button
                onClick={handleNext}
                disabled={isLoading || !canGoNext}
                endIcon={<ArrowForward />}
                color="primary"
                sx={{ 
                  minWidth: 100,
                  backgroundColor: 'primary.main',
                  color: 'white',
                  fontWeight: 600,
                  '&:hover': {
                    backgroundColor: 'primary.dark',
                  },
                  '&:disabled': {
                    backgroundColor: 'grey.300',
                    color: 'grey.500',
                  }
                }}
              >
                {isLoading ? 'Processando...' : labels.next}
              </Button>
            )}
          </ButtonGroup>

          {/* Cancelar */}
          {onCancel && (
            <Tooltip title="Cancelar cadastro">
              <IconButton
                onClick={handleCancel}
                disabled={isLoading}
                color="error"
              >
                <Cancel />
              </IconButton>
            </Tooltip>
          )}
        </Box>
      </Box>

      {/* Progress indicator para mobile */}
      <Box sx={{ 
        display: { xs: 'block', sm: 'none' }, 
        mt: 2, 
        textAlign: 'center' 
      }}>
        <Typography variant="caption" color="text.secondary">
          Step {state.currentStep + 1} de {state.totalSteps}
        </Typography>
      </Box>

      {/* Dialog de confirmação de cancelamento */}
      <Dialog
        open={showCancelDialog}
        onClose={() => setShowCancelDialog(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          Cancelar Cadastro?
        </DialogTitle>
        <DialogContent>
          <Typography>
            Tem certeza de que deseja cancelar o cadastro?
            Todas as alterações serão perdidas.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button
            onClick={() => setShowCancelDialog(false)}
            color="primary"
          >
            Continuar Editando
          </Button>
          <Button
            onClick={confirmCancel}
            color="error"
            variant="contained"
          >
            Sim, Cancelar
          </Button>
        </DialogActions>
      </Dialog>
    </>
  )
}

export default StepperNavigation