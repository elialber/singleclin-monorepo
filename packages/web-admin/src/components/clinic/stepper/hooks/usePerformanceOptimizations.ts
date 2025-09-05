import { useEffect, useMemo, useCallback, useRef } from 'react'
import { throttle, debounce } from 'lodash'

export interface UsePerformanceOptimizationsOptions {
  enableImageOptimization?: boolean
  enableFormThrottling?: boolean
  enableLazyLoading?: boolean
  throttleDelay?: number
  debounceDelay?: number
}

export interface UsePerformanceOptimizationsReturn {
  // Throttled/debounced functions
  throttledFormUpdate: (callback: Function) => Function
  debouncedValidation: (callback: Function) => Function
  
  // Image optimization
  optimizeImageUpload: (file: File) => Promise<File>
  generateImageThumbnail: (file: File, maxSize: number) => Promise<string>
  
  // Lazy loading
  intersectionObserverRef: React.RefObject<IntersectionObserver | null>
  useInView: (callback: () => void) => React.RefCallback<Element>
  
  // Memory management
  cleanup: () => void
  
  // Performance monitoring
  measurePerformance: <T>(name: string, fn: () => T) => T
}

export function usePerformanceOptimizations(
  options: UsePerformanceOptimizationsOptions = {}
): UsePerformanceOptimizationsReturn {
  const {
    enableImageOptimization = true,
    enableFormThrottling = true,
    enableLazyLoading = true,
    throttleDelay = 100,
    debounceDelay = 300
  } = options

  // Refs para cleanup
  const throttledFunctionsRef = useRef<Function[]>([])
  const debouncedFunctionsRef = useRef<Function[]>([])
  const intersectionObserverRef = useRef<IntersectionObserver | null>(null)
  const performanceMarksRef = useRef<string[]>([])

  // Throttled form updates
  const throttledFormUpdate = useCallback((callback: Function) => {
    if (!enableFormThrottling) return callback

    const throttledFn = throttle(callback, throttleDelay, {
      leading: true,
      trailing: true
    })
    
    throttledFunctionsRef.current.push(throttledFn)
    return throttledFn
  }, [enableFormThrottling, throttleDelay])

  // Debounced validation
  const debouncedValidation = useCallback((callback: Function) => {
    const debouncedFn = debounce(callback, debounceDelay, {
      leading: false,
      trailing: true
    })
    
    debouncedFunctionsRef.current.push(debouncedFn)
    return debouncedFn
  }, [debounceDelay])

  // Image optimization
  const optimizeImageUpload = useCallback(async (file: File): Promise<File> => {
    if (!enableImageOptimization) return file

    return new Promise((resolve, reject) => {
      const canvas = document.createElement('canvas')
      const ctx = canvas.getContext('2d')
      const img = new Image()

      img.onload = () => {
        try {
          // Definir dimensões máximas
          const MAX_WIDTH = 1920
          const MAX_HEIGHT = 1080
          const QUALITY = 0.8

          let { width, height } = img

          // Redimensionar se necessário
          if (width > MAX_WIDTH || height > MAX_HEIGHT) {
            const ratio = Math.min(MAX_WIDTH / width, MAX_HEIGHT / height)
            width = Math.floor(width * ratio)
            height = Math.floor(height * ratio)
          }

          canvas.width = width
          canvas.height = height

          // Desenhar imagem redimensionada
          ctx?.drawImage(img, 0, 0, width, height)

          // Converter para blob
          canvas.toBlob(
            (blob) => {
              if (blob) {
                const optimizedFile = new File([blob], file.name, {
                  type: 'image/jpeg',
                  lastModified: Date.now()
                })
                resolve(optimizedFile)
              } else {
                resolve(file)
              }
            },
            'image/jpeg',
            QUALITY
          )
        } catch (error) {
          console.warn('Erro na otimização de imagem:', error)
          resolve(file)
        }
      }

      img.onerror = () => resolve(file)
      img.src = URL.createObjectURL(file)
    })
  }, [enableImageOptimization])

  // Geração de thumbnails
  const generateImageThumbnail = useCallback(async (
    file: File, 
    maxSize: number = 200
  ): Promise<string> => {
    return new Promise((resolve, reject) => {
      const canvas = document.createElement('canvas')
      const ctx = canvas.getContext('2d')
      const img = new Image()

      img.onload = () => {
        const size = Math.min(maxSize, Math.max(img.width, img.height))
        canvas.width = size
        canvas.height = size

        // Calcular posição para crop centralizado
        const scale = size / Math.min(img.width, img.height)
        const scaledWidth = img.width * scale
        const scaledHeight = img.height * scale
        const offsetX = (size - scaledWidth) / 2
        const offsetY = (size - scaledHeight) / 2

        ctx?.drawImage(img, offsetX, offsetY, scaledWidth, scaledHeight)
        resolve(canvas.toDataURL('image/jpeg', 0.7))
      }

      img.onerror = () => reject(new Error('Erro ao gerar thumbnail'))
      img.src = URL.createObjectURL(file)
    })
  }, [])

  // Lazy loading com Intersection Observer
  const useInView = useCallback((callback: () => void) => {
    return (node: Element | null) => {
      if (!enableLazyLoading || !node) return

      if (!intersectionObserverRef.current) {
        intersectionObserverRef.current = new IntersectionObserver(
          (entries) => {
            entries.forEach((entry) => {
              if (entry.isIntersecting) {
                callback()
                intersectionObserverRef.current?.unobserve(entry.target)
              }
            })
          },
          {
            rootMargin: '50px',
            threshold: 0.1
          }
        )
      }

      intersectionObserverRef.current.observe(node)
    }
  }, [enableLazyLoading])

  // Performance monitoring
  const measurePerformance = useCallback(<T>(name: string, fn: () => T): T => {
    const markName = `clinic-stepper-${name}-${Date.now()}`
    performanceMarksRef.current.push(markName)
    
    performance.mark(`${markName}-start`)
    const result = fn()
    performance.mark(`${markName}-end`)
    
    performance.measure(
      `clinic-stepper-${name}`,
      `${markName}-start`,
      `${markName}-end`
    )
    
    // Log performance se estiver em desenvolvimento
    if (process.env.NODE_ENV === 'development') {
      const measures = performance.getEntriesByName(`clinic-stepper-${name}`)
      const latestMeasure = measures[measures.length - 1]
      if (latestMeasure) {
        console.log(`⚡ ${name}: ${latestMeasure.duration.toFixed(2)}ms`)
      }
    }
    
    return result
  }, [])

  // Cleanup function
  const cleanup = useCallback(() => {
    // Cancel throttled/debounced functions
    throttledFunctionsRef.current.forEach(fn => {
      if (typeof (fn as any).cancel === 'function') {
        (fn as any).cancel()
      }
    })
    
    debouncedFunctionsRef.current.forEach(fn => {
      if (typeof (fn as any).cancel === 'function') {
        (fn as any).cancel()
      }
    })

    // Disconnect intersection observer
    if (intersectionObserverRef.current) {
      intersectionObserverRef.current.disconnect()
      intersectionObserverRef.current = null
    }

    // Clear performance marks
    performanceMarksRef.current.forEach(markName => {
      try {
        performance.clearMarks(`${markName}-start`)
        performance.clearMarks(`${markName}-end`)
      } catch (error) {
        // Ignore errors in mark cleanup
      }
    })
    
    // Clear arrays
    throttledFunctionsRef.current = []
    debouncedFunctionsRef.current = []
    performanceMarksRef.current = []
  }, [])

  // Cleanup on unmount
  useEffect(() => {
    return cleanup
  }, [cleanup])

  // Performance monitoring setup
  useEffect(() => {
    if (process.env.NODE_ENV === 'development') {
      const observer = new PerformanceObserver((list) => {
        list.getEntries().forEach((entry) => {
          if (entry.name.startsWith('clinic-stepper-')) {
            // Alertar sobre operações lentas
            if (entry.duration > 100) {
              console.warn(`🐌 Operação lenta detectada: ${entry.name} (${entry.duration.toFixed(2)}ms)`)
            }
          }
        })
      })
      
      observer.observe({ entryTypes: ['measure'] })
      
      return () => observer.disconnect()
    }
  }, [])

  return {
    throttledFormUpdate,
    debouncedValidation,
    optimizeImageUpload,
    generateImageThumbnail,
    intersectionObserverRef,
    useInView,
    cleanup,
    measurePerformance
  }
}

export default usePerformanceOptimizations