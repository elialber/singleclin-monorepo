import { test, expect } from '@playwright/test'

test.describe('Clinic Stepper E2E Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to stepper page
    await page.goto('/clinic/stepper')
  })

  test('should complete full clinic registration flow', async ({ page }) => {
    // Step 1: Basic Information
    await expect(page.locator('[data-testid="step-indicator-0"]')).toHaveClass(/active/)
    
    await page.fill('[name="name"]', 'Clínica Teste E2E')
    await page.selectOption('[name="type"]', 'regular')
    await page.fill('[name="cnpj"]', '11.222.333/0001-81')
    await page.fill('[name="phone"]', '(11) 99999-9999')
    await page.fill('[name="email"]', 'teste@clinica.com')
    await page.check('[name="isActive"]')

    // Proceed to next step
    await page.click('[data-testid="next-button"]')
    await expect(page.locator('[data-testid="step-indicator-1"]')).toHaveClass(/active/)

    // Step 2: Address and Location
    await page.fill('[name="cep"]', '01310-100')
    
    // Wait for CEP API response
    await page.waitForTimeout(2000)
    
    await expect(page.locator('[name="street"]')).toHaveValue('Avenida Paulista')
    await page.fill('[name="number"]', '1000')
    await page.fill('[name="complement"]', 'Sala 1001')

    // Interact with map (if visible)
    const mapContainer = page.locator('[data-testid="google-map"]')
    if (await mapContainer.isVisible()) {
      await mapContainer.click()
    }

    await page.click('[data-testid="next-button"]')
    await expect(page.locator('[data-testid="step-indicator-2"]')).toHaveClass(/active/)

    // Step 3: Image Upload
    const fileInput = page.locator('input[type="file"]')
    
    // Upload test images
    await fileInput.setInputFiles([
      'src/components/clinic/stepper/__tests__/fixtures/test-image-1.jpg',
      'src/components/clinic/stepper/__tests__/fixtures/test-image-2.jpg'
    ])

    // Wait for uploads to complete
    await expect(page.locator('[data-testid="upload-progress"]')).not.toBeVisible({ timeout: 10000 })
    
    // Set featured image
    await page.click('[data-testid="set-featured-0"]')
    
    await page.click('[data-testid="next-button"]')
    await expect(page.locator('[data-testid="step-indicator-3"]')).toHaveClass(/active/)

    // Step 4: Review
    await expect(page.locator('[data-testid="review-basic-info"]')).toContainText('Clínica Teste E2E')
    await expect(page.locator('[data-testid="review-address"]')).toContainText('Avenida Paulista')
    await expect(page.locator('[data-testid="review-images"]')).toBeVisible()

    // Final submission
    await page.click('[data-testid="submit-button"]')
    
    // Wait for submission to complete
    await expect(page.locator('[data-testid="success-message"]')).toBeVisible({ timeout: 5000 })
  })

  test('should validate required fields', async ({ page }) => {
    // Try to proceed without filling required fields
    await page.click('[data-testid="next-button"]')

    // Should show validation errors
    await expect(page.locator('.Mui-error')).toHaveCount(5) // name, cnpj, phone, email
    await expect(page.locator('[data-testid="error-summary"]')).toContainText('campos que precisam ser corrigidos')
  })

  test('should validate CNPJ format', async ({ page }) => {
    await page.fill('[name="cnpj"]', '11.222.333/0001-82') // Invalid CNPJ
    await page.blur('[name="cnpj"]')

    await expect(page.locator('[data-testid="cnpj-error"]')).toContainText('CNPJ inválido')
  })

  test('should validate phone format', async ({ page }) => {
    await page.fill('[name="phone"]', '(11) 1999-9999') // Invalid mobile format
    await page.blur('[name="phone"]')

    await expect(page.locator('[data-testid="phone-error"]')).toContainText('Telefone inválido')
  })

  test('should validate email format', async ({ page }) => {
    await page.fill('[name="email"]', 'invalid-email')
    await page.blur('[name="email"]')

    await expect(page.locator('[data-testid="email-error"]')).toContainText('E-mail inválido')
  })
})

test.describe('Draft System E2E', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/clinic/stepper')
  })

  test('should auto-save draft', async ({ page }) => {
    // Fill some data
    await page.fill('[name="name"]', 'Draft Test Clinic')
    await page.fill('[name="cnpj"]', '11.222.333/0001-81')

    // Wait for auto-save
    await page.waitForTimeout(31000) // Auto-save interval + buffer

    // Check for auto-save indicator
    await expect(page.locator('[data-testid="draft-status"]')).toContainText('Salvo')
  })

  test('should load recent draft on page reload', async ({ page }) => {
    // Create a draft
    await page.fill('[name="name"]', 'Reload Test Clinic')
    await page.waitForTimeout(31000) // Wait for auto-save

    // Reload page
    await page.reload()

    // Should show recent draft alert
    await expect(page.locator('[data-testid="recent-draft-alert"]')).toBeVisible()
    
    // Load the draft
    await page.click('[data-testid="load-recent-draft"]')
    
    // Check data was loaded
    await expect(page.locator('[name="name"]')).toHaveValue('Reload Test Clinic')
  })

  test('should manage draft list', async ({ page }) => {
    // Create multiple drafts by saving manually
    await page.fill('[name="name"]', 'Draft 1')
    await page.click('[data-testid="save-draft-button"]')
    
    await page.fill('[name="name"]', 'Draft 2')
    await page.click('[data-testid="save-draft-button"]')

    // Open drafts modal
    await page.click('[data-testid="drafts-button"]')
    
    // Should show both drafts
    await expect(page.locator('[data-testid="draft-item"]')).toHaveCount(2)
    
    // Delete one draft
    await page.click('[data-testid="delete-draft-0"]')
    await page.click('[data-testid="confirm-delete"]')
    
    await expect(page.locator('[data-testid="draft-item"]')).toHaveCount(1)
  })

  test('should export and import draft', async ({ page }) => {
    // Create a draft
    await page.fill('[name="name"]', 'Export Test Clinic')
    await page.fill('[name="cnpj"]', '11.222.333/0001-81')
    await page.click('[data-testid="save-draft-button"]')

    // Open drafts modal
    await page.click('[data-testid="drafts-button"]')
    
    // Export draft
    const [download] = await Promise.all([
      page.waitForEvent('download'),
      page.click('[data-testid="export-draft-0"]')
    ])
    
    expect(download.suggestedFilename()).toMatch(/clinic-draft.*\.json/)

    // Import draft (would require file upload simulation)
    await page.click('[data-testid="import-button"]')
    // ... additional import testing would require file handling
  })
})

test.describe('Responsive Design E2E', () => {
  test('should work on mobile devices', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 })
    await page.goto('/clinic/stepper')

    // Should show mobile layout
    await expect(page.locator('[data-testid="mobile-stepper"]')).toBeVisible()
    
    // Should show hamburger menu
    await expect(page.locator('[data-testid="menu-button"]')).toBeVisible()
    
    // Open mobile navigation
    await page.click('[data-testid="menu-button"]')
    await expect(page.locator('[data-testid="mobile-nav"]')).toBeVisible()

    // Fill form on mobile
    await page.fill('[name="name"]', 'Mobile Test Clinic')
    await page.click('[data-testid="next-button"]')

    // Should navigate to next step
    await expect(page.locator('[data-testid="step-indicator-1"]')).toHaveClass(/active/)
  })

  test('should work on tablet devices', async ({ page }) => {
    // Set tablet viewport
    await page.setViewportSize({ width: 768, height: 1024 })
    await page.goto('/clinic/stepper')

    // Should show compact horizontal stepper
    await expect(page.locator('[data-testid="compact-stepper"]')).toBeVisible()
    
    // Should be able to complete form flow
    await page.fill('[name="name"]', 'Tablet Test Clinic')
    await page.click('[data-testid="next-button"]')
    
    await expect(page.locator('[data-testid="step-indicator-1"]')).toHaveClass(/active/)
  })
})

test.describe('Accessibility E2E', () => {
  test('should be navigable with keyboard', async ({ page }) => {
    await page.goto('/clinic/stepper')

    // Tab through form elements
    await page.keyboard.press('Tab')
    await expect(page.locator('[name="name"]')).toBeFocused()
    
    await page.keyboard.press('Tab')
    await expect(page.locator('[name="type"]')).toBeFocused()
    
    // Use arrow keys in stepper
    await page.focus('[data-testid="step-indicator-0"]')
    await page.keyboard.press('ArrowRight')
    await expect(page.locator('[data-testid="step-indicator-1"]')).toBeFocused()
  })

  test('should announce changes to screen readers', async ({ page }) => {
    await page.goto('/clinic/stepper')

    // Check aria-live regions exist
    await expect(page.locator('[aria-live]')).toHaveCount(1)
    
    // Navigate to next step
    await page.fill('[name="name"]', 'Accessibility Test')
    await page.click('[data-testid="next-button"]')
    
    // Check aria-current is updated
    await expect(page.locator('[data-testid="step-indicator-1"]')).toHaveAttribute('aria-current', 'step')
  })

  test('should have proper ARIA labels', async ({ page }) => {
    await page.goto('/clinic/stepper')

    // Check stepper has proper ARIA attributes
    await expect(page.locator('[role="tablist"]')).toHaveAttribute('aria-label', 'Etapas do cadastro de clínica')
    
    // Check individual steps have proper attributes
    await expect(page.locator('[data-testid="step-indicator-0"]')).toHaveAttribute('role', 'tab')
    await expect(page.locator('[data-testid="step-indicator-0"]')).toHaveAttribute('aria-expanded', 'true')
  })
})