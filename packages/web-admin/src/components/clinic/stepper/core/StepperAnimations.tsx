import React from 'react'
import { 
  Fade, 
  Slide, 
  Grow, 
  Collapse,
  useTheme,
  useMediaQuery,
  Box 
} from '@mui/material'
import { TransitionGroup, CSSTransition } from 'react-transition-group'

export interface StepperAnimationsProps {
  children: React.ReactNode
  currentStep: number
  direction?: 'left' | 'right' | 'up' | 'down'
  animationType?: 'slide' | 'fade' | 'grow' | 'none'
  duration?: number
  respectMotionPreference?: boolean
}

export function StepperAnimations({
  children,
  currentStep,
  direction = 'right',
  animationType = 'slide',
  duration = 300,
  respectMotionPreference = true
}: StepperAnimationsProps) {
  const theme = useTheme()
  const prefersReducedMotion = useMediaQuery('(prefers-reduced-motion: reduce)')
  
  // Desabilitar animações se o usuário preferir movimento reduzido
  const shouldAnimate = respectMotionPreference ? !prefersReducedMotion : true
  const effectiveAnimationType = shouldAnimate ? animationType : 'none'

  // Slide Animation
  if (effectiveAnimationType === 'slide') {
    return (
      <Slide
        direction={direction}
        in={true}
        timeout={duration}
        appear
      >
        <Box>{children}</Box>
      </Slide>
    )
  }

  // Fade Animation
  if (effectiveAnimationType === 'fade') {
    return (
      <Fade
        in={true}
        timeout={duration}
        appear
      >
        <Box>{children}</Box>
      </Fade>
    )
  }

  // Grow Animation
  if (effectiveAnimationType === 'grow') {
    return (
      <Grow
        in={true}
        timeout={duration}
        appear
      >
        <Box>{children}</Box>
      </Grow>
    )
  }

  // No Animation
  return <Box>{children}</Box>
}

export interface StepTransitionProps {
  children: React.ReactNode
  stepKey: string | number
  direction?: 'horizontal' | 'vertical'
  respectMotionPreference?: boolean
}

export function StepTransition({
  children,
  stepKey,
  direction = 'horizontal',
  respectMotionPreference = true
}: StepTransitionProps) {
  const prefersReducedMotion = useMediaQuery('(prefers-reduced-motion: reduce)')
  const shouldAnimate = respectMotionPreference ? !prefersReducedMotion : true

  if (!shouldAnimate) {
    return <Box key={stepKey}>{children}</Box>
  }

  const classNames = {
    enter: 'step-enter',
    enterActive: 'step-enter-active',
    exit: 'step-exit',
    exitActive: 'step-exit-active'
  }

  return (
    <Box
      sx={{
        '& .step-enter': {
          opacity: 0,
          transform: direction === 'horizontal' ? 'translateX(20px)' : 'translateY(20px)'
        },
        '& .step-enter-active': {
          opacity: 1,
          transform: 'translate(0)',
          transition: 'all 300ms ease-in-out'
        },
        '& .step-exit': {
          opacity: 1,
          transform: 'translate(0)'
        },
        '& .step-exit-active': {
          opacity: 0,
          transform: direction === 'horizontal' ? 'translateX(-20px)' : 'translateY(-20px)',
          transition: 'all 300ms ease-in-out'
        }
      }}
    >
      <TransitionGroup>
        <CSSTransition
          key={stepKey}
          classNames={classNames}
          timeout={300}
          appear
        >
          <Box>{children}</Box>
        </CSSTransition>
      </TransitionGroup>
    </Box>
  )
}

export interface ProgressAnimationProps {
  progress: number
  animated?: boolean
  respectMotionPreference?: boolean
}

export function ProgressAnimation({
  progress,
  animated = true,
  respectMotionPreference = true
}: ProgressAnimationProps) {
  const prefersReducedMotion = useMediaQuery('(prefers-reduced-motion: reduce)')
  const shouldAnimate = animated && (respectMotionPreference ? !prefersReducedMotion : true)

  return (
    <Box
      sx={{
        position: 'relative',
        height: 8,
        bgcolor: 'grey.200',
        borderRadius: 4,
        overflow: 'hidden'
      }}
    >
      <Box
        sx={{
          position: 'absolute',
          top: 0,
          left: 0,
          height: '100%',
          bgcolor: 'primary.main',
          borderRadius: 4,
          width: `${progress}%`,
          transition: shouldAnimate ? 'width 0.5s ease-in-out' : 'none',
          
          // Animação de shimmer para indicar progresso ativo
          ...(shouldAnimate && progress > 0 && progress < 100 && {
            '&::after': {
              content: '""',
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent)',
              animation: 'shimmer 1.5s infinite'
            }
          })
        }}
      />
      
      {/* Keyframes para animação shimmer */}
      <style>
        {`
          @keyframes shimmer {
            0% { transform: translateX(-100%); }
            100% { transform: translateX(100%); }
          }
        `}
      </style>
    </Box>
  )
}

export interface LoadingAnimationProps {
  loading: boolean
  children: React.ReactNode
  type?: 'fade' | 'skeleton' | 'shimmer'
}

export function LoadingAnimation({
  loading,
  children,
  type = 'fade'
}: LoadingAnimationProps) {
  if (type === 'fade') {
    return (
      <Fade in={!loading} timeout={300}>
        <Box sx={{ opacity: loading ? 0.5 : 1 }}>
          {children}
        </Box>
      </Fade>
    )
  }

  if (type === 'skeleton') {
    return (
      <Box sx={{ position: 'relative' }}>
        {loading && (
          <Box
            sx={{
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              bgcolor: 'grey.100',
              borderRadius: 1,
              zIndex: 1,
              
              '&::after': {
                content: '""',
                position: 'absolute',
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.6), transparent)',
                animation: 'skeleton-loading 1.5s ease-in-out infinite'
              }
            }}
          />
        )}
        
        <Box sx={{ opacity: loading ? 0 : 1 }}>
          {children}
        </Box>
        
        <style>
          {`
            @keyframes skeleton-loading {
              0% { transform: translateX(-100%); }
              100% { transform: translateX(100%); }
            }
          `}
        </style>
      </Box>
    )
  }

  return <Box>{children}</Box>
}

export interface CollapsibleSectionProps {
  open: boolean
  children: React.ReactNode
  timeout?: number
  respectMotionPreference?: boolean
}

export function CollapsibleSection({
  open,
  children,
  timeout = 300,
  respectMotionPreference = true
}: CollapsibleSectionProps) {
  const prefersReducedMotion = useMediaQuery('(prefers-reduced-motion: reduce)')
  const shouldAnimate = respectMotionPreference ? !prefersReducedMotion : true

  return (
    <Collapse
      in={open}
      timeout={shouldAnimate ? timeout : 0}
    >
      <Box>{children}</Box>
    </Collapse>
  )
}

// Hook para controle de animações
export function useStepperAnimations(respectMotionPreference: boolean = true) {
  const prefersReducedMotion = useMediaQuery('(prefers-reduced-motion: reduce)')
  
  return {
    shouldAnimate: respectMotionPreference ? !prefersReducedMotion : true,
    getTransitionProps: (duration: number = 300) => ({
      timeout: respectMotionPreference && prefersReducedMotion ? 0 : duration
    })
  }
}

export default StepperAnimations