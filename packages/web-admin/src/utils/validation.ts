/**
 * Utilitários de validação para formulários
 */

// Regex patterns
export const REGEX_PATTERNS = {
  // Nome: letras, números, espaços, acentos, hífens e pontos
  NAME: /^[a-zA-ZÀ-ÿ0-9\s\-\.]{3,200}$/,
  
  // Email RFC compliant
  EMAIL: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  
  // CNPJ formatado: XX.XXX.XXX/XXXX-XX
  CNPJ_FORMATTED: /^\d{2}\.\d{3}\.\d{3}\/\d{4}\-\d{2}$/,
  
  // CNPJ apenas números
  CNPJ_NUMBERS_ONLY: /^\d{14}$/,
  
  // Telefone formatado: (XX) XXXXX-XXXX ou (XX) XXXX-XXXX
  PHONE_FORMATTED: /^\(\d{2}\)\s\d{4,5}\-\d{4}$/,
  
  // Telefone apenas números (com DDD)
  PHONE_NUMBERS_ONLY: /^\d{10,11}$/,
  
  // CEP formatado: XXXXX-XXX
  CEP_FORMATTED: /^\d{5}\-\d{3}$/,
  
  // CEP apenas números
  CEP_NUMBERS_ONLY: /^\d{8}$/,
} as const

// DDDs válidos no Brasil
export const VALID_DDDS = [
  11, 12, 13, 14, 15, 16, 17, 18, 19, // São Paulo
  21, 22, 24, // Rio de Janeiro
  27, 28, // Espírito Santo
  31, 32, 33, 34, 35, 37, 38, // Minas Gerais
  41, 42, 43, 44, 45, 46, // Paraná
  47, 48, 49, // Santa Catarina
  51, 53, 54, 55, // Rio Grande do Sul
  61, // Distrito Federal
  62, 64, // Goiás
  63, // Tocantins
  65, 66, // Mato Grosso
  67, // Mato Grosso do Sul
  68, // Acre
  69, // Rondônia
  71, 73, 74, 75, 77, // Bahia
  79, // Sergipe
  81, 87, // Pernambuco
  82, // Alagoas
  83, // Paraíba
  84, // Rio Grande do Norte
  85, 88, // Ceará
  86, 89, // Piauí
  91, 93, 94, // Pará
  92, 97, // Amazonas
  95, // Roraima
  96, // Amapá
  98, 99, // Maranhão
] as const

/**
 * Validação de nome de clínica
 */
export function validateClinicName(name: string): {
  isValid: boolean
  errors: string[]
} {
  const errors: string[] = []
  
  if (!name || name.trim().length === 0) {
    errors.push('Nome é obrigatório')
  } else if (name.trim().length < 3) {
    errors.push('Nome deve ter pelo menos 3 caracteres')
  } else if (name.trim().length > 200) {
    errors.push('Nome deve ter no máximo 200 caracteres')
  } else if (!REGEX_PATTERNS.NAME.test(name.trim())) {
    errors.push('Nome contém caracteres inválidos')
  }
  
  return {
    isValid: errors.length === 0,
    errors
  }
}

/**
 * Validação de email
 */
export function validateEmail(email: string): {
  isValid: boolean
  errors: string[]
} {
  const errors: string[] = []
  
  if (email && email.trim().length > 0) {
    if (email.trim().length > 320) {
      errors.push('Email deve ter no máximo 320 caracteres')
    } else if (!REGEX_PATTERNS.EMAIL.test(email.trim())) {
      errors.push('Formato de email inválido')
    }
  }
  
  return {
    isValid: errors.length === 0,
    errors
  }
}

/**
 * Validação de CNPJ com algoritmo de dígitos verificadores
 */
export function validateCNPJ(cnpj: string): {
  isValid: boolean
  errors: string[]
} {
  const errors: string[] = []
  
  if (cnpj && cnpj.trim().length > 0) {
    // Remove formatação
    const cleanCNPJ = cnpj.replace(/[^\d]/g, '')
    
    if (!REGEX_PATTERNS.CNPJ_NUMBERS_ONLY.test(cleanCNPJ)) {
      errors.push('CNPJ deve ter 14 dígitos')
    } else if (!isValidCNPJAlgorithm(cleanCNPJ)) {
      errors.push('CNPJ inválido')
    }
  }
  
  return {
    isValid: errors.length === 0,
    errors
  }
}

/**
 * Algoritmo de validação de CNPJ
 */
function isValidCNPJAlgorithm(cnpj: string): boolean {
  // CNPJs inválidos conhecidos
  const invalidCNPJs = [
    '00000000000000',
    '11111111111111',
    '22222222222222',
    '33333333333333',
    '44444444444444',
    '55555555555555',
    '66666666666666',
    '77777777777777',
    '88888888888888',
    '99999999999999'
  ]
  
  if (invalidCNPJs.includes(cnpj)) {
    return false
  }
  
  // Validação do primeiro dígito verificador
  let sum = 0
  let weight = 5
  
  for (let i = 0; i < 12; i++) {
    sum += parseInt(cnpj[i]) * weight
    weight = weight === 2 ? 9 : weight - 1
  }
  
  const firstDigit = sum % 11 < 2 ? 0 : 11 - (sum % 11)
  
  if (firstDigit !== parseInt(cnpj[12])) {
    return false
  }
  
  // Validação do segundo dígito verificador
  sum = 0
  weight = 6
  
  for (let i = 0; i < 13; i++) {
    sum += parseInt(cnpj[i]) * weight
    weight = weight === 2 ? 9 : weight - 1
  }
  
  const secondDigit = sum % 11 < 2 ? 0 : 11 - (sum % 11)
  
  return secondDigit === parseInt(cnpj[13])
}

/**
 * Validação de telefone
 */
export function validatePhone(phone: string): {
  isValid: boolean
  errors: string[]
} {
  const errors: string[] = []
  
  if (phone && phone.trim().length > 0) {
    // Remove formatação
    const cleanPhone = phone.replace(/[^\d]/g, '')
    
    if (!REGEX_PATTERNS.PHONE_NUMBERS_ONLY.test(cleanPhone)) {
      errors.push('Telefone deve ter 10 ou 11 dígitos (com DDD)')
    } else {
      const ddd = parseInt(cleanPhone.substring(0, 2))
      
      if (!VALID_DDDS.includes(ddd as any)) {
        errors.push('DDD inválido')
      }
      
      // Validar se é celular (9º dígito deve ser 9 para celulares)
      if (cleanPhone.length === 11) {
        const ninthDigit = parseInt(cleanPhone[2])
        if (ninthDigit !== 9) {
          errors.push('Para celular, o terceiro dígito deve ser 9')
        }
      }
    }
  }
  
  return {
    isValid: errors.length === 0,
    errors
  }
}

/**
 * Verificação de duplicatas (mock - será integrado com API)
 */
export async function checkClinicNameExists(
  name: string,
  excludeId?: string
): Promise<boolean> {
  // Mock - substituir por chamada API real
  await new Promise(resolve => setTimeout(resolve, 500))
  
  // Simular alguns nomes que já existem
  const existingNames = [
    'Clínica São Paulo',
    'Hospital das Clínicas',
    'Clínica Exemplo',
    'Centro Médico ABC'
  ]
  
  return existingNames.some(existing => 
    existing.toLowerCase() === name.toLowerCase()
  )
}

/**
 * Verificação de CNPJ duplicado (mock - será integrado com API)
 */
export async function checkCNPJExists(
  cnpj: string,
  excludeId?: string
): Promise<boolean> {
  // Mock - substituir por chamada API real
  await new Promise(resolve => setTimeout(resolve, 500))
  
  // Simular alguns CNPJs que já existem
  const existingCNPJs = [
    '11.222.333/0001-81',
    '12.345.678/0001-90',
    '98.765.432/0001-10'
  ]
  
  const cleanCNPJ = cnpj.replace(/[^\d]/g, '')
  
  return existingCNPJs.some(existing => {
    const cleanExisting = existing.replace(/[^\d]/g, '')
    return cleanExisting === cleanCNPJ
  })
}

/**
 * Auto-complete para nomes de clínicas (mock)
 */
export async function getClinicNameSuggestions(
  query: string,
  limit: number = 5
): Promise<string[]> {
  // Mock - substituir por chamada API real
  await new Promise(resolve => setTimeout(resolve, 300))
  
  if (query.length < 2) return []
  
  const suggestions = [
    'Clínica São Paulo',
    'Clínica Nossa Senhora',
    'Clínica Santa Maria',
    'Clínica Central',
    'Clínica do Centro',
    'Clínica Especializada',
    'Clínica Médica Avançada',
    'Clínica de Diagnóstico',
    'Clínica Vida Saudável',
    'Clínica Bem Estar'
  ]
  
  const filtered = suggestions.filter(name =>
    name.toLowerCase().includes(query.toLowerCase())
  )
  
  return filtered.slice(0, limit)
}

/**
 * Debounce function para validações assíncronas
 */
export function debounce<T extends (...args: any[]) => any>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeout: NodeJS.Timeout
  
  return (...args: Parameters<T>) => {
    clearTimeout(timeout)
    timeout = setTimeout(() => func(...args), wait)
  }
}

/**
 * Função para limpar strings de formatação
 */
export function cleanNumericString(value: string): string {
  return value.replace(/[^\d]/g, '')
}

/**
 * Função para formatar CNPJ
 */
export function formatCNPJ(value: string): string {
  const cleaned = cleanNumericString(value)
  
  if (cleaned.length <= 14) {
    return cleaned
      .replace(/^(\d{2})(\d)/, '$1.$2')
      .replace(/^(\d{2})\.(\d{3})(\d)/, '$1.$2.$3')
      .replace(/\.(\d{3})(\d)/, '.$1/$2')
      .replace(/(\d{4})(\d)/, '$1-$2')
  }
  
  return value
}

/**
 * Função para formatar telefone
 */
export function formatPhone(value: string): string {
  const cleaned = cleanNumericString(value)
  
  if (cleaned.length <= 11) {
    if (cleaned.length <= 10) {
      // Telefone fixo: (XX) XXXX-XXXX
      return cleaned
        .replace(/^(\d{2})(\d)/, '($1) $2')
        .replace(/(\d{4})(\d)/, '$1-$2')
    } else {
      // Celular: (XX) XXXXX-XXXX
      return cleaned
        .replace(/^(\d{2})(\d)/, '($1) $2')
        .replace(/(\d{5})(\d)/, '$1-$2')
    }
  }
  
  return value
}

/**
 * Função para formatar CEP
 */
export function formatCEP(value: string): string {
  const cleaned = cleanNumericString(value)
  
  if (cleaned.length <= 8) {
    return cleaned.replace(/^(\d{5})(\d)/, '$1-$2')
  }
  
  return value
}

/**
 * Validação de CEP
 */
export function validateCEP(cep: string): {
  isValid: boolean
  errors: string[]
} {
  const errors: string[] = []
  
  if (!cep || cep.trim().length === 0) {
    errors.push('CEP é obrigatório')
  } else {
    const cleanCEP = cep.replace(/[^\d]/g, '')
    
    if (!REGEX_PATTERNS.CEP_NUMBERS_ONLY.test(cleanCEP)) {
      errors.push('CEP deve ter 8 dígitos')
    }
  }
  
  return {
    isValid: errors.length === 0,
    errors
  }
}

/**
 * Interface para resposta do ViaCEP
 */
export interface ViaCEPResponse {
  cep: string
  logradouro: string
  complemento: string
  bairro: string
  localidade: string
  uf: string
  ibge: string
  gia?: string
  ddd: string
  siafi: string
  erro?: boolean
}

/**
 * Buscar endereço por CEP usando ViaCEP API
 */
export async function getAddressByCEP(cep: string): Promise<ViaCEPResponse | null> {
  const cleanCEP = cep.replace(/[^\d]/g, '')
  
  if (!REGEX_PATTERNS.CEP_NUMBERS_ONLY.test(cleanCEP)) {
    throw new Error('CEP deve ter 8 dígitos')
  }
  
  try {
    const response = await fetch(`https://viacep.com.br/ws/${cleanCEP}/json/`)
    
    if (!response.ok) {
      throw new Error('Erro ao consultar CEP')
    }
    
    const data: ViaCEPResponse = await response.json()
    
    if (data.erro) {
      throw new Error('CEP não encontrado')
    }
    
    return data
  } catch (error) {
    if (error instanceof Error) {
      throw error
    }
    throw new Error('Erro ao consultar CEP')
  }
}

/**
 * Validação de endereço
 */
export function validateAddress(address: string, required: boolean = true): {
  isValid: boolean
  errors: string[]
} {
  const errors: string[] = []
  
  if (required && (!address || address.trim().length === 0)) {
    errors.push('Endereço é obrigatório')
  } else if (address && address.trim().length > 0) {
    if (address.trim().length < 5) {
      errors.push('Endereço deve ter pelo menos 5 caracteres')
    } else if (address.trim().length > 255) {
      errors.push('Endereço deve ter no máximo 255 caracteres')
    }
  }
  
  return {
    isValid: errors.length === 0,
    errors
  }
}

/**
 * Validação de número do endereço
 */
export function validateAddressNumber(number: string, required: boolean = true): {
  isValid: boolean
  errors: string[]
} {
  const errors: string[] = []
  
  if (required && (!number || number.trim().length === 0)) {
    errors.push('Número é obrigatório')
  } else if (number && number.trim().length > 0) {
    if (number.trim().length > 20) {
      errors.push('Número deve ter no máximo 20 caracteres')
    }
  }
  
  return {
    isValid: errors.length === 0,
    errors
  }
}

/**
 * Validação de complemento
 */
export function validateComplement(complement: string): {
  isValid: boolean
  errors: string[]
} {
  const errors: string[] = []
  
  if (complement && complement.trim().length > 100) {
    errors.push('Complemento deve ter no máximo 100 caracteres')
  }
  
  return {
    isValid: errors.length === 0,
    errors
  }
}

/**
 * Validação de bairro
 */
export function validateNeighborhood(neighborhood: string, required: boolean = true): {
  isValid: boolean
  errors: string[]
} {
  const errors: string[] = []
  
  if (required && (!neighborhood || neighborhood.trim().length === 0)) {
    errors.push('Bairro é obrigatório')
  } else if (neighborhood && neighborhood.trim().length > 0) {
    if (neighborhood.trim().length < 2) {
      errors.push('Bairro deve ter pelo menos 2 caracteres')
    } else if (neighborhood.trim().length > 100) {
      errors.push('Bairro deve ter no máximo 100 caracteres')
    }
  }
  
  return {
    isValid: errors.length === 0,
    errors
  }
}

/**
 * Validação de cidade
 */
export function validateCity(city: string, required: boolean = true): {
  isValid: boolean
  errors: string[]
} {
  const errors: string[] = []
  
  if (required && (!city || city.trim().length === 0)) {
    errors.push('Cidade é obrigatória')
  } else if (city && city.trim().length > 0) {
    if (city.trim().length < 2) {
      errors.push('Cidade deve ter pelo menos 2 caracteres')
    } else if (city.trim().length > 100) {
      errors.push('Cidade deve ter no máximo 100 caracteres')
    }
  }
  
  return {
    isValid: errors.length === 0,
    errors
  }
}

/**
 * Validação de estado
 */
export function validateState(state: string, required: boolean = true): {
  isValid: boolean
  errors: string[]
} {
  const errors: string[] = []
  
  if (required && (!state || state.trim().length === 0)) {
    errors.push('Estado é obrigatório')
  }
  
  return {
    isValid: errors.length === 0,
    errors
  }
}

/**
 * Interface para coordenadas geográficas
 */
export interface GeolocationCoordinates {
  latitude: number
  longitude: number
  accuracy?: number
}

/**
 * Validação de coordenadas geográficas
 */
export function validateCoordinates(coordinates: GeolocationCoordinates): {
  isValid: boolean
  errors: string[]
} {
  const errors: string[] = []
  
  if (coordinates.latitude < -90 || coordinates.latitude > 90) {
    errors.push('Latitude deve estar entre -90 e 90')
  }
  
  if (coordinates.longitude < -180 || coordinates.longitude > 180) {
    errors.push('Longitude deve estar entre -180 e 180')
  }
  
  return {
    isValid: errors.length === 0,
    errors
  }
}