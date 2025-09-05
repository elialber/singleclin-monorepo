import { expect, afterEach, vi } from 'vitest'
import { cleanup } from '@testing-library/react'
import * as matchers from '@testing-library/jest-dom/matchers'

// Extend Vitest's expect with jest-dom matchers
expect.extend(matchers)

// Cleanup after each test case
afterEach(() => {
  cleanup()
})

// Mock Google Maps API
const mockGoogleMaps = {
  Map: vi.fn().mockImplementation(() => ({
    setCenter: vi.fn(),
    setZoom: vi.fn(),
    addListener: vi.fn()
  })),
  Marker: vi.fn().mockImplementation(() => ({
    setPosition: vi.fn(),
    setMap: vi.fn(),
    addListener: vi.fn()
  })),
  Geocoder: vi.fn().mockImplementation(() => ({
    geocode: vi.fn((request, callback) => {
      callback([{
        geometry: {
          location: {
            lat: () => -23.5505,
            lng: () => -46.6333
          }
        }
      }], 'OK')
    })
  })),
  places: {
    AutocompleteService: vi.fn()
  }
}

// Mock global google object
Object.defineProperty(global, 'google', {
  value: {
    maps: mockGoogleMaps
  },
  writable: true
})

// Mock IntersectionObserver
global.IntersectionObserver = vi.fn().mockImplementation((callback) => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn(),
  root: null,
  rootMargin: '',
  thresholds: []
}))

// Mock ResizeObserver
global.ResizeObserver = vi.fn().mockImplementation(() => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn()
}))

// Mock matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(), // deprecated
    removeListener: vi.fn(), // deprecated
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  }))
})

// Mock localStorage
const localStorageMock = {
  getItem: vi.fn(),
  setItem: vi.fn(),
  removeItem: vi.fn(),
  clear: vi.fn(),
  length: 0,
  key: vi.fn()
}

Object.defineProperty(window, 'localStorage', {
  value: localStorageMock
})

// Mock sessionStorage
const sessionStorageMock = {
  getItem: vi.fn(),
  setItem: vi.fn(),
  removeItem: vi.fn(),
  clear: vi.fn(),
  length: 0,
  key: vi.fn()
}

Object.defineProperty(window, 'sessionStorage', {
  value: sessionStorageMock
})

// Mock URL.createObjectURL
global.URL.createObjectURL = vi.fn(() => 'mocked-url')
global.URL.revokeObjectURL = vi.fn()

// Mock File constructor
global.File = class MockFile {
  name: string
  type: string
  size: number
  lastModified: number

  constructor(parts: (string | Blob | ArrayBuffer | ArrayBufferView)[], name: string, options?: FilePropertyBag) {
    this.name = name
    this.type = options?.type || ''
    this.size = parts.reduce((acc, part) => {
      if (typeof part === 'string') return acc + part.length
      if (part instanceof Blob) return acc + part.size
      return acc + part.byteLength
    }, 0)
    this.lastModified = options?.lastModified || Date.now()
  }
} as any

// Mock FormData
global.FormData = class MockFormData {
  private data = new Map()

  append(key: string, value: any) {
    this.data.set(key, value)
  }

  get(key: string) {
    return this.data.get(key)
  }

  has(key: string) {
    return this.data.has(key)
  }

  delete(key: string) {
    this.data.delete(key)
  }

  entries() {
    return this.data.entries()
  }
} as any

// Mock fetch
global.fetch = vi.fn()

// Mock XMLHttpRequest for file uploads
global.XMLHttpRequest = vi.fn().mockImplementation(() => ({
  open: vi.fn(),
  send: vi.fn(),
  setRequestHeader: vi.fn(),
  addEventListener: vi.fn(),
  upload: {
    addEventListener: vi.fn()
  },
  status: 200,
  responseText: '{"success": true}'
})) as any

// Console warnings as errors in tests
const originalError = console.error
beforeEach(() => {
  console.error = (...args: any[]) => {
    if (
      typeof args[0] === 'string' &&
      args[0].includes('Warning:')
    ) {
      throw new Error(args[0])
    }
    originalError.call(console, ...args)
  }
})

afterEach(() => {
  console.error = originalError
})

// Mock process.env for tests
process.env.NODE_ENV = 'test'
process.env.VITE_GOOGLE_MAPS_API_KEY = 'test-api-key'