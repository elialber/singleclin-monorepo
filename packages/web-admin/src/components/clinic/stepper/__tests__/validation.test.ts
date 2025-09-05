import { describe, it, expect, vi, beforeEach } from 'vitest'
import {
  validateCNPJ,
  validatePhone,
  validateCEP,
  validateCoordinates,
  validateEmail,
  validateRequired,
  isValidBrazilianState
} from '../../../../utils/validation'

describe('Validation Utils', () => {
  describe('validateCNPJ', () => {
    it('should validate correct CNPJ', () => {
      const validCNPJs = [
        '11.222.333/0001-81',
        '11.444.777/0001-61'
      ]
      
      validCNPJs.forEach(cnpj => {
        expect(validateCNPJ(cnpj)).toBe(true)
      })
    })

    it('should reject invalid CNPJ', () => {
      const invalidCNPJs = [
        '11.222.333/0001-82', // Wrong check digit
        '11.111.111/1111-11', // Known invalid pattern
        '123456789', // Too short
        '', // Empty
        'invalid'
      ]
      
      invalidCNPJs.forEach(cnpj => {
        expect(validateCNPJ(cnpj)).toBe(false)
      })
    })

    it('should handle CNPJ without formatting', () => {
      expect(validateCNPJ('11222333000181')).toBe(true)
      expect(validateCNPJ('11222333000182')).toBe(false)
    })
  })

  describe('validatePhone', () => {
    it('should validate mobile phones', () => {
      const validMobiles = [
        '(11) 99999-9999',
        '(21) 98888-8888',
        '(85) 97777-7777'
      ]
      
      validMobiles.forEach(phone => {
        expect(validatePhone(phone)).toBe(true)
      })
    })

    it('should validate landline phones', () => {
      const validLandlines = [
        '(11) 3333-3333',
        '(21) 2222-2222',
        '(85) 4444-4444'
      ]
      
      validLandlines.forEach(phone => {
        expect(validatePhone(phone)).toBe(true)
      })
    })

    it('should reject invalid phones', () => {
      const invalidPhones = [
        '(11) 1999-9999', // Mobile without 9
        '(99) 99999-9999', // Invalid area code
        '(11) 99999-999', // Too short
        '1199999999', // Without formatting
        ''
      ]
      
      invalidPhones.forEach(phone => {
        expect(validatePhone(phone)).toBe(false)
      })
    })
  })

  describe('validateCEP', () => {
    it('should validate correct CEP format', () => {
      const validCEPs = [
        '01310-100',
        '20040-020',
        '80010-000'
      ]
      
      validCEPs.forEach(cep => {
        expect(validateCEP(cep)).toBe(true)
      })
    })

    it('should reject invalid CEP', () => {
      const invalidCEPs = [
        '0131-100', // Too short
        '01310-10', // Wrong format
        '01310100', // Without dash
        '',
        'invalid'
      ]
      
      invalidCEPs.forEach(cep => {
        expect(validateCEP(cep)).toBe(false)
      })
    })
  })

  describe('validateCoordinates', () => {
    it('should validate coordinates within Brazil', () => {
      const validCoordinates = [
        { lat: -23.5505, lng: -46.6333 }, // São Paulo
        { lat: -22.9068, lng: -43.1729 }, // Rio de Janeiro
        { lat: -3.7319, lng: -38.5267 }   // Fortaleza
      ]
      
      validCoordinates.forEach(coord => {
        expect(validateCoordinates(coord.lat, coord.lng)).toBe(true)
      })
    })

    it('should reject coordinates outside valid range', () => {
      const invalidCoordinates = [
        { lat: 91, lng: 0 }, // Invalid latitude
        { lat: 0, lng: 181 }, // Invalid longitude
        { lat: -91, lng: 0 }, // Invalid latitude
        { lat: 0, lng: -181 } // Invalid longitude
      ]
      
      invalidCoordinates.forEach(coord => {
        expect(validateCoordinates(coord.lat, coord.lng)).toBe(false)
      })
    })
  })

  describe('validateEmail', () => {
    it('should validate correct emails', () => {
      const validEmails = [
        'user@example.com',
        'test.user@domain.co.uk',
        'user+tag@example.org',
        'user123@test-domain.com'
      ]
      
      validEmails.forEach(email => {
        expect(validateEmail(email)).toBe(true)
      })
    })

    it('should reject invalid emails', () => {
      const invalidEmails = [
        'invalid-email',
        '@domain.com',
        'user@',
        'user@.com',
        '',
        'user space@domain.com'
      ]
      
      invalidEmails.forEach(email => {
        expect(validateEmail(email)).toBe(false)
      })
    })
  })

  describe('validateRequired', () => {
    it('should validate non-empty values', () => {
      expect(validateRequired('test')).toBe(true)
      expect(validateRequired('0')).toBe(true)
      expect(validateRequired(' text ')).toBe(true)
    })

    it('should reject empty values', () => {
      expect(validateRequired('')).toBe(false)
      expect(validateRequired('   ')).toBe(false)
      expect(validateRequired(null)).toBe(false)
      expect(validateRequired(undefined)).toBe(false)
    })
  })

  describe('isValidBrazilianState', () => {
    it('should validate correct state codes', () => {
      const validStates = ['SP', 'RJ', 'MG', 'RS', 'PR', 'SC', 'BA', 'GO', 'DF']
      
      validStates.forEach(state => {
        expect(isValidBrazilianState(state)).toBe(true)
      })
    })

    it('should reject invalid state codes', () => {
      const invalidStates = ['XX', 'YY', 'ZZ', '', 'SPP', '12']
      
      invalidStates.forEach(state => {
        expect(isValidBrazilianState(state)).toBe(false)
      })
    })
  })
})

describe('Integration Tests - Cross-validation', () => {
  it('should validate complete address data', () => {
    const validAddress = {
      cep: '01310-100',
      state: 'SP',
      coordinates: { lat: -23.5505, lng: -46.6333 }
    }
    
    expect(validateCEP(validAddress.cep)).toBe(true)
    expect(isValidBrazilianState(validAddress.state)).toBe(true)
    expect(validateCoordinates(validAddress.coordinates.lat, validAddress.coordinates.lng)).toBe(true)
  })

  it('should validate complete clinic basic info', () => {
    const validBasicInfo = {
      cnpj: '11.222.333/0001-81',
      phone: '(11) 99999-9999',
      email: 'clinic@example.com'
    }
    
    expect(validateCNPJ(validBasicInfo.cnpj)).toBe(true)
    expect(validatePhone(validBasicInfo.phone)).toBe(true)
    expect(validateEmail(validBasicInfo.email)).toBe(true)
  })
})