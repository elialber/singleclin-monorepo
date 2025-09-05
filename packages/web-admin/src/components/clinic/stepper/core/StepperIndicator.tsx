import React from 'react'
import {
  Box,
  Step,
  StepButton,
  StepContent,
  StepIcon,
  StepLabel,
  Stepper,
  Typography,
  Chip,
  alpha,
  useTheme
} from '@mui/material'
import {
  CheckCircle,
  RadioButtonUnchecked,
  Error,
  FiberManualRecord
} from '@mui/icons-material'
import { StepInfo, StepStatus } from '../../../../types/stepper'
import { useClinicStepper } from '../hooks/useClinicStepper'

interface StepperIndicatorProps {
  /** Informações dos steps */
  steps: StepInfo[]
  
  /** Step atual */
  currentStep: number
  
  /** Orientação do stepper */
  orientation?: 'horizontal' | 'vertical'
  
  /** Permitir navegação clicando nos steps */
  interactive?: boolean
  
  /** Modo compacto (menos espaçamento) */
  compact?: boolean
  
  /** Mostrar descrições dos steps */
  showDescriptions?: boolean
  
  /** Callback ao clicar em um step */
  onStepClick?: (stepIndex: number) => void
}

/**
 * Componente indicador visual do stepper
 * 
 * Mostra o progresso através dos steps com estados visuais apropriados
 */
export function StepperIndicator({
  steps,
  currentStep,
  orientation = 'horizontal',
  interactive = true,
  compact = false,
  showDescriptions = true,
  onStepClick
}: StepperIndicatorProps) {
  const theme = useTheme()
  const { goToStep } = useClinicStepper()

  // Handler para click no step
  const handleStepClick = (stepIndex: number) => {
    if (interactive && onStepClick) {
      onStepClick(stepIndex)
    } else if (interactive) {
      goToStep(stepIndex)
    }
  }

  // Renderização para orientação vertical personalizada
  if (orientation === 'vertical' && !compact) {
    return (
      <Box>
        {steps.map((step, index) => (
          <StepIndicatorItem
            key={step.index}
            step={step}
            isActive={index === currentStep}
            isClickable={interactive}
            showDescription={showDescriptions}
            onClick={() => handleStepClick(index)}
            isLast={index === steps.length - 1}
          />
        ))}
      </Box>
    )
  }

  // Renderização com Stepper do Material-UI
  return (
    <Stepper
      activeStep={currentStep}
      orientation={orientation}
      sx={{
        ...(compact && {
          '& .MuiStepLabel-label': {
            fontSize: '0.875rem'
          },
          '& .MuiStepContent-root': {
            ml: 2
          }
        })
      }}
    >
      {steps.map((step, index) => (
        <Step key={step.index} completed={step.status === 'completed'}>
          {interactive ? (
            <StepButton
              onClick={() => handleStepClick(index)}
              disabled={step.status === 'pending' && index > currentStep}
            >
              <StepLabel
                StepIconComponent={(props) => (
                  <CustomStepIcon {...props} step={step} />
                )}
                error={step.status === 'error'}
              >
                <Box>
                  <Typography
                    variant={compact ? 'body2' : 'body1'}
                    component="span"
                    sx={{
                      fontWeight: step.status === 'current' ? 600 : 400,
                      color: getStepColor(step.status, theme)
                    }}
                  >
                    {step.title}
                  </Typography>
                  
                  {showDescriptions && !compact && (
                    <Typography
                      variant="caption"
                      component="div"
                      color="text.secondary"
                      sx={{ mt: 0.5 }}
                    >
                      {step.description}
                    </Typography>
                  )}
                </Box>
              </StepLabel>
            </StepButton>
          ) : (
            <StepLabel
              StepIconComponent={(props) => (
                <CustomStepIcon {...props} step={step} />
              )}
              error={step.status === 'error'}
            >
              <Box>
                <Typography
                  variant={compact ? 'body2' : 'body1'}
                  component="span"
                  sx={{
                    fontWeight: step.status === 'current' ? 600 : 400,
                    color: getStepColor(step.status, theme)
                  }}
                >
                  {step.title}
                </Typography>
                
                {showDescriptions && !compact && (
                  <Typography
                    variant="caption"
                    component="div"
                    color="text.secondary"
                    sx={{ mt: 0.5 }}
                  >
                    {step.description}
                  </Typography>
                )}
              </Box>
            </StepLabel>
          )}
          
          {orientation === 'vertical' && step.status === 'current' && (
            <StepContent>
              <Typography variant="body2" color="text.secondary">
                {step.description}
              </Typography>
            </StepContent>
          )}
        </Step>
      ))}
    </Stepper>
  )
}

/**
 * Item individual do step (para layout vertical customizado)
 */
interface StepIndicatorItemProps {
  step: StepInfo
  isActive: boolean
  isClickable: boolean
  showDescription: boolean
  onClick: () => void
  isLast: boolean
}

function StepIndicatorItem({
  step,
  isActive,
  isClickable,
  showDescription,
  onClick,
  isLast
}: StepIndicatorItemProps) {
  const theme = useTheme()

  return (
    <Box
      sx={{
        display: 'flex',
        alignItems: 'flex-start',
        position: 'relative',
        cursor: isClickable ? 'pointer' : 'default',
        '&:hover': isClickable && {
          bgcolor: alpha(theme.palette.primary.main, 0.04),
          borderRadius: 1
        },
        p: 1,
        mr: -1
      }}
      onClick={isClickable ? onClick : undefined}
    >
      {/* Connector line */}
      {!isLast && (
        <Box
          sx={{
            position: 'absolute',
            left: 20,
            top: 32,
            bottom: -8,
            width: 2,
            bgcolor: step.status === 'completed' 
              ? 'success.main' 
              : 'divider'
          }}
        />
      )}

      {/* Step icon */}
      <Box sx={{ mr: 2, zIndex: 1 }}>
        <CustomStepIcon
          active={isActive}
          completed={step.status === 'completed'}
          error={step.status === 'error'}
          step={step}
        />
      </Box>

      {/* Step content */}
      <Box sx={{ flex: 1, minWidth: 0 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Typography
            variant="body1"
            sx={{
              fontWeight: isActive ? 600 : 400,
              color: getStepColor(step.status, theme)
            }}
          >
            {step.icon} {step.title}
          </Typography>
          
          {step.isDirty && (
            <Chip
              label="Editado"
              size="small"
              variant="outlined"
              color="info"
              sx={{ height: 20, fontSize: '0.75rem' }}
            />
          )}
        </Box>

        {showDescription && (
          <Typography
            variant="body2"
            color="text.secondary"
            sx={{ mt: 0.5 }}
          >
            {step.description}
          </Typography>
        )}

        {/* Status indicators */}
        {step.status === 'error' && (
          <Typography
            variant="caption"
            color="error"
            sx={{ mt: 0.5, display: 'block' }}
          >
            Este step possui erros
          </Typography>
        )}
      </Box>
    </Box>
  )
}

/**
 * Ícone customizado do step
 */
interface CustomStepIconProps {
  active?: boolean
  completed?: boolean
  error?: boolean
  step: StepInfo
}

function CustomStepIcon({
  active,
  completed,
  error,
  step
}: CustomStepIconProps) {
  const theme = useTheme()

  if (error) {
    return (
      <Error
        sx={{
          color: theme.palette.error.main,
          fontSize: 24
        }}
      />
    )
  }

  if (completed) {
    return (
      <CheckCircle
        sx={{
          color: theme.palette.success.main,
          fontSize: 24
        }}
      />
    )
  }

  if (active) {
    return (
      <FiberManualRecord
        sx={{
          color: theme.palette.primary.main,
          fontSize: 24
        }}
      />
    )
  }

  return (
    <RadioButtonUnchecked
      sx={{
        color: theme.palette.action.disabled,
        fontSize: 24
      }}
    />
  )
}

/**
 * Função auxiliar para obter cor do step
 */
function getStepColor(status: StepStatus, theme: any): string {
  switch (status) {
    case 'completed':
      return theme.palette.success.main
    case 'current':
      return theme.palette.primary.main
    case 'error':
      return theme.palette.error.main
    case 'pending':
    default:
      return theme.palette.text.secondary
  }
}

export default StepperIndicator