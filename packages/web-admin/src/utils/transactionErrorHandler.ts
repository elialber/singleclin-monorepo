import { AxiosError } from 'axios'

export interface TransactionError {
  type: 'validation' | 'business' | 'network' | 'server' | 'unknown'
  code: string
  title: string
  message: string
  details?: string
  suggestions?: string[]
  isRetryable: boolean
}

/**
 * Enhanced error handler for transaction-specific errors
 * Provides contextual messages and user-friendly suggestions
 */
export class TransactionErrorHandler {
  private static readonly ERROR_MESSAGES = {
    // Network errors
    NETWORK_ERROR: {
      title: 'Erro de Conexão',
      message: 'Não foi possível conectar com o servidor. Verifique sua conexão com a internet.',
      suggestions: [
        'Verifique sua conexão com a internet',
        'Tente novamente em alguns segundos',
        'Se o problema persistir, entre em contato com o suporte'
      ]
    },
    TIMEOUT_ERROR: {
      title: 'Tempo Esgotado',
      message: 'A operação demorou mais que o esperado para ser concluída.',
      suggestions: [
        'Tente novamente',
        'Verifique se a transação foi processada antes de tentar novamente'
      ]
    },

    // Business logic errors
    INSUFFICIENT_CREDITS: {
      title: 'Créditos Insuficientes',
      message: 'O paciente não possui créditos suficientes para esta transação.',
      suggestions: [
        'Verifique o saldo de créditos do paciente',
        'Solicite que o paciente adquira mais créditos',
        'Considere usar um plano diferente'
      ]
    },
    TRANSACTION_ALREADY_CANCELLED: {
      title: 'Transação Já Cancelada',
      message: 'Esta transação já foi cancelada anteriormente.',
      suggestions: [
        'Atualize a página para ver o status mais recente',
        'Verifique o histórico da transação'
      ]
    },
    TRANSACTION_ALREADY_VALIDATED: {
      title: 'Transação Já Validada',
      message: 'Esta transação já foi validada e não pode ser modificada.',
      suggestions: [
        'Para alterar uma transação validada, será necessário cancelá-la primeiro',
        'Entre em contato com o administrador se necessário'
      ]
    },
    INVALID_QR_CODE: {
      title: 'Código QR Inválido',
      message: 'O código QR fornecido é inválido ou já foi utilizado.',
      suggestions: [
        'Verifique se o código QR está correto',
        'Gere um novo código QR para o paciente',
        'Certifique-se de que o código não expirou'
      ]
    },
    PLAN_EXPIRED: {
      title: 'Plano Expirado',
      message: 'O plano do paciente expirou e não pode ser utilizado.',
      suggestions: [
        'Solicite que o paciente renove o plano',
        'Verifique a data de validade do plano',
        'Considere migrar para um plano ativo'
      ]
    },
    CLINIC_NOT_AUTHORIZED: {
      title: 'Clínica Não Autorizada',
      message: 'Esta clínica não está autorizada para este plano ou paciente.',
      suggestions: [
        'Verifique se a clínica é parceira do plano',
        'Entre em contato com o administrador para verificar as permissões',
        'Confirme se o paciente pode usar os serviços nesta clínica'
      ]
    },

    // Validation errors
    INVALID_DATA: {
      title: 'Dados Inválidos',
      message: 'Os dados fornecidos não atendem aos critérios necessários.',
      suggestions: [
        'Verifique se todos os campos obrigatórios foram preenchidos',
        'Confirme se os valores estão dentro dos limites permitidos',
        'Corrija os dados destacados em vermelho'
      ]
    },
    MISSING_REQUIRED_FIELDS: {
      title: 'Campos Obrigatórios',
      message: 'Alguns campos obrigatórios não foram preenchidos.',
      suggestions: [
        'Preencha todos os campos marcados com *',
        'Verifique se não há campos vazios'
      ]
    },

    // Server errors
    INTERNAL_SERVER_ERROR: {
      title: 'Erro do Servidor',
      message: 'Ocorreu um erro interno no servidor. Nossa equipe foi notificada.',
      suggestions: [
        'Tente novamente em alguns minutos',
        'Se o problema persistir, entre em contato com o suporte',
        'Anote o horário do erro para facilitar o suporte'
      ]
    },
    SERVICE_UNAVAILABLE: {
      title: 'Serviço Indisponível',
      message: 'O serviço está temporariamente indisponível para manutenção.',
      suggestions: [
        'Tente novamente em alguns minutos',
        'Verifique nossa página de status para atualizações'
      ]
    },

    // Default fallbacks
    UNKNOWN_ERROR: {
      title: 'Erro Inesperado',
      message: 'Ocorreu um erro inesperado. Por favor, tente novamente.',
      suggestions: [
        'Tente novamente',
        'Se o problema persistir, entre em contato com o suporte',
        'Anote as ações que levaram a este erro'
      ]
    }
  }

  static handle(error: any, context?: string): TransactionError {
    // Handle network errors
    if (!error.response) {
      if (error.code === 'ECONNABORTED' || error.message?.includes('timeout')) {
        return this.createError('network', 'TIMEOUT_ERROR', true)
      }
      return this.createError('network', 'NETWORK_ERROR', true)
    }

    const status = error.response?.status
    const data = error.response?.data
    const errorCode = data?.error_code || data?.code
    const errorMessage = data?.detail || data?.message || data?.error

    // Handle specific HTTP status codes
    switch (status) {
      case 400: // Bad Request
        return this.handleBadRequest(data, errorCode, errorMessage, context)
      
      case 401: // Unauthorized
        return this.createError('business', 'UNAUTHORIZED', false, {
          title: 'Não Autorizado',
          message: 'Sua sessão expirou. Faça login novamente.',
          suggestions: ['Faça login novamente', 'Verifique suas credenciais']
        })
      
      case 403: // Forbidden
        return this.createError('business', 'CLINIC_NOT_AUTHORIZED', false)
      
      case 404: // Not Found
        return this.createError('business', 'NOT_FOUND', false, {
          title: 'Não Encontrado',
          message: context ? `${context} não foi encontrado(a).` : 'O recurso solicitado não foi encontrado.',
          suggestions: [
            'Verifique se o ID está correto',
            'A transação pode ter sido removida',
            'Atualize a página e tente novamente'
          ]
        })
      
      case 409: // Conflict
        return this.handleConflict(data, errorCode, errorMessage)
      
      case 422: // Unprocessable Entity
        return this.createError('validation', 'INVALID_DATA', false)
      
      case 429: // Too Many Requests
        return this.createError('network', 'TOO_MANY_REQUESTS', true, {
          title: 'Muitas Tentativas',
          message: 'Muitas tentativas em pouco tempo. Aguarde um momento.',
          suggestions: [
            'Aguarde alguns segundos antes de tentar novamente',
            'Evite clicar múltiplas vezes no mesmo botão'
          ]
        })
      
      case 500: // Internal Server Error
        return this.createError('server', 'INTERNAL_SERVER_ERROR', true)
      
      case 502: // Bad Gateway
      case 503: // Service Unavailable
      case 504: // Gateway Timeout
        return this.createError('server', 'SERVICE_UNAVAILABLE', true)
      
      default:
        return this.createError('unknown', 'UNKNOWN_ERROR', true, {
          details: errorMessage || `HTTP ${status}`
        })
    }
  }

  private static handleBadRequest(data: any, errorCode: string, errorMessage: string, context?: string): TransactionError {
    // Check for specific business logic errors
    if (errorCode || errorMessage) {
      const message = errorMessage?.toLowerCase() || ''
      
      if (message.includes('insufficient') || message.includes('créditos insuficientes')) {
        return this.createError('business', 'INSUFFICIENT_CREDITS', false)
      }
      
      if (message.includes('already cancelled') || message.includes('já cancelada')) {
        return this.createError('business', 'TRANSACTION_ALREADY_CANCELLED', false)
      }
      
      if (message.includes('already validated') || message.includes('já validada')) {
        return this.createError('business', 'TRANSACTION_ALREADY_VALIDATED', false)
      }
      
      if (message.includes('invalid qr') || message.includes('qr inválido')) {
        return this.createError('business', 'INVALID_QR_CODE', false)
      }
      
      if (message.includes('plan expired') || message.includes('plano expirado')) {
        return this.createError('business', 'PLAN_EXPIRED', false)
      }
    }

    // Check for validation errors
    if (data?.errors && typeof data.errors === 'object') {
      return this.createError('validation', 'MISSING_REQUIRED_FIELDS', false, {
        details: Object.keys(data.errors).join(', ')
      })
    }

    return this.createError('validation', 'INVALID_DATA', false, {
      details: errorMessage
    })
  }

  private static handleConflict(data: any, errorCode: string, errorMessage: string): TransactionError {
    const message = errorMessage?.toLowerCase() || ''
    
    if (message.includes('already exists') || message.includes('já existe')) {
      return this.createError('business', 'ALREADY_EXISTS', false, {
        title: 'Conflito de Dados',
        message: 'Este recurso já existe no sistema.',
        suggestions: [
          'Verifique se você não está duplicando informações',
          'Use dados únicos para criar novos registros'
        ]
      })
    }
    
    return this.createError('business', 'CONFLICT', false, {
      title: 'Conflito de Dados',
      message: errorMessage || 'Há um conflito com os dados existentes.',
      suggestions: [
        'Atualize a página e tente novamente',
        'Verifique se outro usuário já fez alterações'
      ]
    })
  }

  private static createError(
    type: TransactionError['type'], 
    code: string, 
    isRetryable: boolean,
    overrides?: Partial<Omit<TransactionError, 'type' | 'code' | 'isRetryable'>>
  ): TransactionError {
    const template = this.ERROR_MESSAGES[code as keyof typeof this.ERROR_MESSAGES] || this.ERROR_MESSAGES.UNKNOWN_ERROR
    
    return {
      type,
      code,
      isRetryable,
      title: overrides?.title || template.title,
      message: overrides?.message || template.message,
      details: overrides?.details,
      suggestions: overrides?.suggestions || template.suggestions
    }
  }

  /**
   * Get a user-friendly error message for notifications
   */
  static getNotificationMessage(error: any, context?: string): string {
    const transactionError = this.handle(error, context)
    return transactionError.message
  }

  /**
   * Check if an error should be retried automatically
   */
  static shouldRetry(error: any): boolean {
    const transactionError = this.handle(error)
    return transactionError.isRetryable
  }

  /**
   * Get detailed error info for error boundaries or logging
   */
  static getErrorInfo(error: any, context?: string) {
    const transactionError = this.handle(error, context)
    return {
      ...transactionError,
      originalError: error,
      timestamp: new Date().toISOString(),
      context
    }
  }
}

// Export utility functions for common use cases
export const getTransactionErrorMessage = (error: any, context?: string) => 
  TransactionErrorHandler.getNotificationMessage(error, context)

export const shouldRetryTransactionError = (error: any) => 
  TransactionErrorHandler.shouldRetry(error)

export const handleTransactionError = (error: any, context?: string) => 
  TransactionErrorHandler.handle(error, context)