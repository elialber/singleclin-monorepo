/**
 * Utilitários para tratamento de erros da API
 */

/**
 * Extrai mensagens de erro específicas da resposta da API
 * @param error - Erro da requisição
 * @param fallbackMessage - Mensagem padrão se não conseguir extrair erros específicos
 * @returns Mensagem de erro formatada
 */
export function extractErrorMessage(error: any, fallbackMessage: string = 'Ocorreu um erro'): string {
  // Handle specific validation errors
  if (error.response?.status === 400 && error.response?.data?.errors) {
    const errors = error.response.data.errors
    
    if (Array.isArray(errors)) {
      // Handle array of error messages (like from .NET)
      return errors.join('\n')
    } else if (typeof errors === 'object') {
      // Handle object-style errors (like validation errors)
      const errorMessages = Object.values(errors).flat().join('\n')
      return errorMessages
    }
  }
  
  // Handle single error message
  if (error.response?.data?.message) {
    return error.response.data.message
  }
  
  // Handle other properties that might contain the error
  if (error.response?.data?.detail) {
    return error.response.data.detail
  }
  
  // Handle error message from error object itself
  if (error.message) {
    return error.message
  }
  
  // Fallback to generic message
  return fallbackMessage
}

/**
 * Verifica se o erro é de validação (400 com erros específicos)
 * @param error - Erro da requisição
 * @returns true se for erro de validação
 */
export function isValidationError(error: any): boolean {
  return error.response?.status === 400 && error.response?.data?.errors
}

/**
 * Verifica se o erro é de autorização
 * @param error - Erro da requisição
 * @returns true se for erro de autorização
 */
export function isAuthorizationError(error: any): boolean {
  return error.response?.status === 401 || error.response?.status === 403
}

/**
 * Verifica se o erro é de recurso não encontrado
 * @param error - Erro da requisição
 * @returns true se for erro 404
 */
export function isNotFoundError(error: any): boolean {
  return error.response?.status === 404
}

/**
 * Verifica se o erro é de conflito (ex: email já existe)
 * @param error - Erro da requisição
 * @returns true se for erro de conflito
 */
export function isConflictError(error: any): boolean {
  return error.response?.status === 409
}