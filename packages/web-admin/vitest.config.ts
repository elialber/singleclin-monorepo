import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    globals: true,
    css: true,
    reporters: ['verbose', 'json'],
    outputFile: {
      json: './test-results/unit-tests.json'
    },
    exclude: [
      'node_modules/',
      'dist/',
      'build/',
      '**/*.spec.ts', // Exclude Playwright test files
      '**/*e2e*/**', // Exclude e2e test directories
      'tests/e2e/**', // Exclude e2e test directory
      'playwright-report/**',
      'test-results/**'
    ],
    coverage: {
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'src/test/',
        '**/*.d.ts',
        '**/*.config.*',
        '**/dist/',
        '**/__tests__/',
        '**/coverage/'
      ],
      thresholds: {
        global: {
          branches: 80,
          functions: 80,
          lines: 80,
          statements: 80
        }
      }
    }
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    }
  }
})