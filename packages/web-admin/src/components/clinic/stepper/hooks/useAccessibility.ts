import { useEffect, useRef, useCallback, useState } from 'react'

export interface UseAccessibilityOptions {
  enableKeyboardNavigation?: boolean
  enableScreenReaderAnnouncements?: boolean
  enableFocusManagement?: boolean
  announceStepChanges?: boolean
}

export interface UseAccessibilityReturn {
  // ARIA attributes
  getStepperAriaProps: () => {
    role: string
    'aria-label': string
    'aria-orientation': 'horizontal' | 'vertical'
  }
  
  getStepAriaProps: (stepIndex: number, isActive: boolean, isCompleted: boolean) => {
    role: string
    'aria-current'?: 'step'
    'aria-expanded': boolean
    'aria-describedby'?: string
    tabIndex: number
  }
  
  // Screen reader announcements
  announceToScreenReader: (message: string, priority?: 'polite' | 'assertive') => void
  
  // Keyboard navigation
  handleKeyDown: (event: React.KeyboardEvent) => void
  
  // Focus management
  focusStep: (stepIndex: number) => void
  focusFirstError: () => void
  
  // Skip links
  skipLinksRef: React.RefObject<HTMLDivElement>
  
  // High contrast mode detection
  isHighContrast: boolean
  
  // Reduced motion preference
  prefersReducedMotion: boolean
}

export function useAccessibility(
  options: UseAccessibilityOptions = {}
): UseAccessibilityReturn {
  const {
    enableKeyboardNavigation = true,
    enableScreenReaderAnnouncements = true,
    enableFocusManagement = true,
    announceStepChanges = true
  } = options

  // Refs
  const skipLinksRef = useRef<HTMLDivElement>(null)
  const ariaLiveRef = useRef<HTMLDivElement | null>(null)
  const currentStepRef = useRef<number>(0)

  // Estados
  const [isHighContrast, setIsHighContrast] = useState(false)
  const [prefersReducedMotion, setPrefersReducedMotion] = useState(false)

  // Detectar preferências de acessibilidade
  useEffect(() => {
    // High contrast detection
    const highContrastQuery = window.matchMedia('(prefers-contrast: high)')
    setIsHighContrast(highContrastQuery.matches)
    
    const handleHighContrastChange = (e: MediaQueryListEvent) => {
      setIsHighContrast(e.matches)
    }
    
    highContrastQuery.addListener(handleHighContrastChange)

    // Reduced motion detection
    const reducedMotionQuery = window.matchMedia('(prefers-reduced-motion: reduce)')
    setPrefersReducedMotion(reducedMotionQuery.matches)
    
    const handleReducedMotionChange = (e: MediaQueryListEvent) => {
      setPrefersReducedMotion(e.matches)
    }
    
    reducedMotionQuery.addListener(handleReducedMotionChange)

    return () => {
      highContrastQuery.removeListener(handleHighContrastChange)
      reducedMotionQuery.removeListener(handleReducedMotionChange)
    }
  }, [])

  // Criar elemento aria-live se não existir
  useEffect(() => {
    if (!enableScreenReaderAnnouncements) return

    let ariaLiveElement = document.getElementById('stepper-aria-live')
    
    if (!ariaLiveElement) {
      ariaLiveElement = document.createElement('div')
      ariaLiveElement.id = 'stepper-aria-live'
      ariaLiveElement.setAttribute('aria-live', 'polite')
      ariaLiveElement.setAttribute('aria-atomic', 'true')
      ariaLiveElement.style.position = 'absolute'
      ariaLiveElement.style.left = '-10000px'
      ariaLiveElement.style.width = '1px'
      ariaLiveElement.style.height = '1px'
      ariaLiveElement.style.overflow = 'hidden'
      document.body.appendChild(ariaLiveElement)
    }
    
    ariaLiveRef.current = ariaLiveElement

    return () => {
      const element = document.getElementById('stepper-aria-live')
      if (element && element.parentNode) {
        element.parentNode.removeChild(element)
      }
    }
  }, [enableScreenReaderAnnouncements])

  // ARIA props para o stepper
  const getStepperAriaProps = useCallback(() => ({
    role: 'tablist',
    'aria-label': 'Etapas do cadastro de clínica',
    'aria-orientation': 'horizontal' as const
  }), [])

  // ARIA props para steps individuais
  const getStepAriaProps = useCallback((
    stepIndex: number,
    isActive: boolean,
    isCompleted: boolean
  ) => ({
    role: 'tab',
    'aria-current': isActive ? ('step' as const) : undefined,
    'aria-expanded': isActive,
    'aria-describedby': `step-${stepIndex}-description`,
    tabIndex: isActive ? 0 : -1
  }), [])

  // Anunciar para screen readers
  const announceToScreenReader = useCallback((
    message: string,
    priority: 'polite' | 'assertive' = 'polite'
  ) => {
    if (!enableScreenReaderAnnouncements || !ariaLiveRef.current) return

    ariaLiveRef.current.setAttribute('aria-live', priority)
    ariaLiveRef.current.textContent = message

    // Limpar após 1 segundo para evitar repetições
    setTimeout(() => {
      if (ariaLiveRef.current) {
        ariaLiveRef.current.textContent = ''
      }
    }, 1000)
  }, [enableScreenReaderAnnouncements])

  // Navegação por teclado
  const handleKeyDown = useCallback((event: React.KeyboardEvent) => {
    if (!enableKeyboardNavigation) return

    const target = event.target as HTMLElement
    const stepElements = document.querySelectorAll('[role="tab"]')
    const currentIndex = Array.from(stepElements).indexOf(target)

    switch (event.key) {
      case 'ArrowRight':
      case 'ArrowDown':
        event.preventDefault()
        if (currentIndex < stepElements.length - 1) {
          (stepElements[currentIndex + 1] as HTMLElement).focus()
        }
        break

      case 'ArrowLeft':
      case 'ArrowUp':
        event.preventDefault()
        if (currentIndex > 0) {
          (stepElements[currentIndex - 1] as HTMLElement).focus()
        }
        break

      case 'Home':
        event.preventDefault()
        (stepElements[0] as HTMLElement).focus()
        break

      case 'End':
        event.preventDefault()
        (stepElements[stepElements.length - 1] as HTMLElement).focus()
        break

      case 'Enter':
      case ' ':
        event.preventDefault()
        target.click()
        break

      case 'Escape':
        event.preventDefault()
        // Retornar foco para elemento principal
        const main = document.querySelector('main') || document.body
        if (main instanceof HTMLElement) {
          main.focus()
        }
        break
    }
  }, [enableKeyboardNavigation])

  // Gerenciamento de foco
  const focusStep = useCallback((stepIndex: number) => {
    if (!enableFocusManagement) return

    const stepElement = document.querySelector(`[role="tab"][data-step="${stepIndex}"]`) as HTMLElement
    if (stepElement) {
      stepElement.focus()
      
      if (announceStepChanges) {
        const stepName = stepElement.getAttribute('aria-label') || `Step ${stepIndex + 1}`
        announceToScreenReader(`Navegou para ${stepName}`)
      }
    }
  }, [enableFocusManagement, announceStepChanges, announceToScreenReader])

  // Focar primeiro erro
  const focusFirstError = useCallback(() => {
    if (!enableFocusManagement) return

    // Procurar por campos com erro
    const errorSelectors = [
      '[aria-invalid="true"]',
      '.Mui-error input',
      '.error input',
      '[data-error="true"]'
    ]

    for (const selector of errorSelectors) {
      const errorElement = document.querySelector(selector) as HTMLElement
      if (errorElement) {
        errorElement.focus()
        
        // Anunciar o erro
        const errorMessage = errorElement.getAttribute('aria-describedby')
        if (errorMessage) {
          const errorText = document.getElementById(errorMessage)?.textContent
          if (errorText) {
            announceToScreenReader(`Erro: ${errorText}`, 'assertive')
          }
        }
        
        break
      }
    }
  }, [enableFocusManagement, announceToScreenReader])

  // Criar skip links
  useEffect(() => {
    if (!skipLinksRef.current) return

    const skipLinks = [
      { href: '#stepper-content', text: 'Pular para conteúdo do formulário' },
      { href: '#stepper-navigation', text: 'Pular para navegação' },
      { href: '#stepper-progress', text: 'Pular para indicador de progresso' }
    ]

    skipLinks.forEach(({ href, text }) => {
      const link = document.createElement('a')
      link.href = href
      link.textContent = text
      link.className = 'skip-link'
      
      // Estilos para skip links (visível apenas no foco)
      Object.assign(link.style, {
        position: 'absolute',
        top: '-40px',
        left: '6px',
        background: '#000',
        color: '#fff',
        padding: '8px',
        textDecoration: 'none',
        zIndex: '1000',
        borderRadius: '4px',
        transition: 'top 0.3s'
      })
      
      link.addEventListener('focus', () => {
        link.style.top = '6px'
      })
      
      link.addEventListener('blur', () => {
        link.style.top = '-40px'
      })
      
      skipLinksRef.current?.appendChild(link)
    })

    return () => {
      if (skipLinksRef.current) {
        skipLinksRef.current.innerHTML = ''
      }
    }
  }, [])

  // Monitorar mudanças de step para anúncios
  useEffect(() => {
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === 'attributes' && mutation.attributeName === 'aria-current') {
          const target = mutation.target as HTMLElement
          if (target.getAttribute('aria-current') === 'step') {
            const stepLabel = target.getAttribute('aria-label') || target.textContent
            if (stepLabel && announceStepChanges) {
              announceToScreenReader(`Etapa atual: ${stepLabel}`)
            }
          }
        }
      })
    })

    // Observar mudanças nos elementos do stepper
    const stepperElements = document.querySelectorAll('[role="tab"]')
    stepperElements.forEach((element) => {
      observer.observe(element, { attributes: true, attributeFilter: ['aria-current'] })
    })

    return () => observer.disconnect()
  }, [announceStepChanges, announceToScreenReader])

  return {
    getStepperAriaProps,
    getStepAriaProps,
    announceToScreenReader,
    handleKeyDown,
    focusStep,
    focusFirstError,
    skipLinksRef,
    isHighContrast,
    prefersReducedMotion
  }
}

export default useAccessibility