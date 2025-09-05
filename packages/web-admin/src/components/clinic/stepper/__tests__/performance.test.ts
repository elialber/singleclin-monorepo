import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { renderHook, render } from '@testing-library/react'
import { usePerformanceOptimizations } from '../hooks/usePerformanceOptimizations'

// Mock performance API
Object.defineProperty(global, 'performance', {
  value: {
    mark: vi.fn(),
    measure: vi.fn(),
    getEntriesByName: vi.fn(() => [{ duration: 50 }]),
    clearMarks: vi.fn(),
    clearMeasures: vi.fn(),
    now: vi.fn(() => Date.now())
  },
  writable: true
})

// Mock IntersectionObserver
global.IntersectionObserver = vi.fn().mockImplementation((callback) => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn()
}))

// Mock canvas API for image optimization
const mockCanvas = {
  getContext: vi.fn(() => ({
    drawImage: vi.fn()
  })),
  toBlob: vi.fn((callback) => {
    const blob = new Blob(['mock'], { type: 'image/jpeg' })
    callback(blob)
  }),
  width: 0,
  height: 0
}

Object.defineProperty(global, 'HTMLCanvasElement', {
  value: vi.fn().mockImplementation(() => mockCanvas)
})

Object.defineProperty(document, 'createElement', {
  value: vi.fn((tagName) => {
    if (tagName === 'canvas') return mockCanvas
    return document.createElement.call(document, tagName)
  }),
  writable: true
})

describe('Performance Optimizations', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.clearAllTimers()
  })

  describe('usePerformanceOptimizations', () => {
    it('should provide throttled form update function', () => {
      const { result } = renderHook(() => usePerformanceOptimizations())

      const mockCallback = vi.fn()
      const throttledFn = result.current.throttledFormUpdate(mockCallback)

      expect(typeof throttledFn).toBe('function')
    })

    it('should provide debounced validation function', () => {
      const { result } = renderHook(() => usePerformanceOptimizations())

      const mockCallback = vi.fn()
      const debouncedFn = result.current.debouncedValidation(mockCallback)

      expect(typeof debouncedFn).toBe('function')
    })

    it('should optimize image uploads', async () => {
      const { result } = renderHook(() => usePerformanceOptimizations())

      const mockFile = new File(['mock'], 'test.jpg', { type: 'image/jpeg' })
      
      // Mock Image constructor
      const mockImage = {
        onload: null as any,
        onerror: null as any,
        src: '',
        width: 1920,
        height: 1080
      }
      
      global.Image = vi.fn().mockImplementation(() => mockImage)
      global.URL.createObjectURL = vi.fn(() => 'mock-url')

      const optimizationPromise = result.current.optimizeImageUpload(mockFile)
      
      // Trigger image load
      setTimeout(() => {
        if (mockImage.onload) mockImage.onload()
      }, 0)

      const optimizedFile = await optimizationPromise
      expect(optimizedFile).toBeInstanceOf(File)
    })

    it('should generate image thumbnails', async () => {
      const { result } = renderHook(() => usePerformanceOptimizations())

      const mockFile = new File(['mock'], 'test.jpg', { type: 'image/jpeg' })
      
      const mockImage = {
        onload: null as any,
        onerror: null as any,
        src: '',
        width: 800,
        height: 600
      }
      
      global.Image = vi.fn().mockImplementation(() => mockImage)
      mockCanvas.toDataURL = vi.fn(() => 'data:image/jpeg;base64,mock')

      const thumbnailPromise = result.current.generateImageThumbnail(mockFile, 200)
      
      setTimeout(() => {
        if (mockImage.onload) mockImage.onload()
      }, 0)

      const thumbnail = await thumbnailPromise
      expect(thumbnail).toMatch(/^data:image\/jpeg/)
    })

    it('should provide intersection observer for lazy loading', () => {
      const { result } = renderHook(() => usePerformanceOptimizations())

      const mockCallback = vi.fn()
      const inViewRef = result.current.useInView(mockCallback)

      expect(typeof inViewRef).toBe('function')
    })

    it('should measure performance', () => {
      const { result } = renderHook(() => usePerformanceOptimizations())

      const testFunction = () => 'test result'
      const measuredResult = result.current.measurePerformance('test-operation', testFunction)

      expect(measuredResult).toBe('test result')
      expect(performance.mark).toHaveBeenCalledTimes(2) // start and end marks
      expect(performance.measure).toHaveBeenCalledWith(
        'clinic-stepper-test-operation',
        expect.stringMatching(/test-operation.*-start/),
        expect.stringMatching(/test-operation.*-end/)
      )
    })

    it('should handle cleanup properly', () => {
      const { result, unmount } = renderHook(() => usePerformanceOptimizations())

      // Create some operations that need cleanup
      const throttledFn = result.current.throttledFormUpdate(() => {})
      const debouncedFn = result.current.debouncedValidation(() => {})

      // Unmount to trigger cleanup
      unmount()

      // Should not throw errors during cleanup
      expect(() => result.current.cleanup()).not.toThrow()
    })

    it('should disable optimizations when configured', () => {
      const { result } = renderHook(() => usePerformanceOptimizations({
        enableImageOptimization: false,
        enableFormThrottling: false,
        enableLazyLoading: false
      }))

      // Should still provide functions but they might behave differently
      expect(typeof result.current.throttledFormUpdate).toBe('function')
      expect(typeof result.current.optimizeImageUpload).toBe('function')
      expect(typeof result.current.useInView).toBe('function')
    })
  })

  describe('Throttling and Debouncing', () => {
    it('should throttle function calls', (done) => {
      vi.useFakeTimers()
      
      const { result } = renderHook(() => usePerformanceOptimizations({
        throttleDelay: 100
      }))

      const mockCallback = vi.fn()
      const throttledFn = result.current.throttledFormUpdate(mockCallback)

      // Call function multiple times rapidly
      throttledFn()
      throttledFn()
      throttledFn()

      // Should only be called once immediately
      expect(mockCallback).toHaveBeenCalledTimes(1)

      // Fast forward time
      vi.advanceTimersByTime(100)

      // Should allow another call after delay
      throttledFn()
      expect(mockCallback).toHaveBeenCalledTimes(2)

      vi.useRealTimers()
      done()
    })

    it('should debounce function calls', (done) => {
      vi.useFakeTimers()
      
      const { result } = renderHook(() => usePerformanceOptimizations({
        debounceDelay: 300
      }))

      const mockCallback = vi.fn()
      const debouncedFn = result.current.debouncedValidation(mockCallback)

      // Call function multiple times rapidly
      debouncedFn()
      debouncedFn()
      debouncedFn()

      // Should not be called immediately
      expect(mockCallback).not.toHaveBeenCalled()

      // Fast forward time
      vi.advanceTimersByTime(300)

      // Should be called once after delay
      expect(mockCallback).toHaveBeenCalledTimes(1)

      vi.useRealTimers()
      done()
    })
  })

  describe('Image Optimization Performance', () => {
    it('should resize large images', async () => {
      const { result } = renderHook(() => usePerformanceOptimizations())

      const mockFile = new File(['large-image'], 'large.jpg', { type: 'image/jpeg' })
      
      const mockImage = {
        onload: null as any,
        onerror: null as any,
        src: '',
        width: 4000, // Large width
        height: 3000  // Large height
      }
      
      global.Image = vi.fn().mockImplementation(() => mockImage)

      const optimizationPromise = result.current.optimizeImageUpload(mockFile)
      
      setTimeout(() => {
        if (mockImage.onload) mockImage.onload()
      }, 0)

      await optimizationPromise

      // Should have called drawImage with resized dimensions
      expect(mockCanvas.getContext().drawImage).toHaveBeenCalled()
    })

    it('should handle image optimization errors gracefully', async () => {
      const { result } = renderHook(() => usePerformanceOptimizations())

      const mockFile = new File(['invalid'], 'invalid.jpg', { type: 'image/jpeg' })
      
      const mockImage = {
        onload: null as any,
        onerror: null as any,
        src: ''
      }
      
      global.Image = vi.fn().mockImplementation(() => mockImage)

      const optimizationPromise = result.current.optimizeImageUpload(mockFile)
      
      // Trigger error
      setTimeout(() => {
        if (mockImage.onerror) mockImage.onerror()
      }, 0)

      const result_file = await optimizationPromise
      
      // Should return original file on error
      expect(result_file).toBe(mockFile)
    })
  })

  describe('Lazy Loading Performance', () => {
    it('should create intersection observer only once', () => {
      const { result } = renderHook(() => usePerformanceOptimizations())

      const mockCallback1 = vi.fn()
      const mockCallback2 = vi.fn()

      result.current.useInView(mockCallback1)
      result.current.useInView(mockCallback2)

      // Should reuse the same observer
      expect(IntersectionObserver).toHaveBeenCalledTimes(1)
    })

    it('should observe elements for intersection', () => {
      const { result } = renderHook(() => usePerformanceOptimizations())

      const mockCallback = vi.fn()
      const inViewRef = result.current.useInView(mockCallback)

      const mockElement = document.createElement('div')
      inViewRef(mockElement)

      // Should observe the element
      const observerInstance = (IntersectionObserver as any).mock.results[0].value
      expect(observerInstance.observe).toHaveBeenCalledWith(mockElement)
    })
  })
})

describe('Performance Benchmarks', () => {
  it('should complete form validation within performance budget', () => {
    const { result } = renderHook(() => usePerformanceOptimizations())

    const startTime = performance.now()
    
    // Simulate complex validation
    const mockValidation = () => {
      // Simulate work
      for (let i = 0; i < 1000; i++) {
        Math.random()
      }
      return true
    }

    result.current.measurePerformance('validation', mockValidation)

    const endTime = performance.now()
    const duration = endTime - startTime

    // Should complete within 100ms budget
    expect(duration).toBeLessThan(100)
  })

  it('should optimize images within reasonable time', async () => {
    const { result } = renderHook(() => usePerformanceOptimizations())

    const mockFile = new File(['test'], 'test.jpg', { type: 'image/jpeg' })
    
    const mockImage = {
      onload: null as any,
      onerror: null as any,
      src: '',
      width: 1920,
      height: 1080
    }
    
    global.Image = vi.fn().mockImplementation(() => mockImage)

    const startTime = Date.now()
    
    const optimizationPromise = result.current.optimizeImageUpload(mockFile)
    
    setTimeout(() => {
      if (mockImage.onload) mockImage.onload()
    }, 0)

    await optimizationPromise

    const duration = Date.now() - startTime

    // Should complete within 1 second
    expect(duration).toBeLessThan(1000)
  })
})