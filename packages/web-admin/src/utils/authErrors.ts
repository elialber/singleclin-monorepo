// Utility to map Firebase Auth error codes to user-friendly Portuguese messages

export const getFirebaseErrorMessage = (errorCode: string): string => {
  const errorMessages: Record<string, string> = {
    // Authentication errors
    'auth/invalid-credential': 'Email ou senha incorretos. Verifique suas credenciais e tente novamente.',
    'auth/wrong-password': 'Senha incorreta. Tente novamente.',
    'auth/invalid-email': 'Email inválido. Digite um email válido.',
    'auth/user-disabled': 'Esta conta foi desabilitada. Entre em contato com o suporte.',
    'auth/email-already-in-use': 'Este email já está sendo usado por outra conta.',
    'auth/weak-password': 'A senha deve ter pelo menos 6 caracteres.',
    'auth/operation-not-allowed': 'Operação não permitida. Entre em contato com o suporte.',
    
    // Network and connectivity
    'auth/network-request-failed': 'Erro de conexão. Verifique sua internet e tente novamente.',
    'auth/too-many-requests': 'Muitas tentativas de login. Aguarde alguns minutos e tente novamente.',
    'auth/timeout': 'A operação demorou muito para responder. Tente novamente.',
    
    // Token related
    'auth/invalid-api-key': 'Erro de configuração. Entre em contato com o suporte.',
    'auth/app-deleted': 'Erro de configuração. Entre em contato with suporte.',
    'auth/app-not-authorized': 'Aplicativo não autorizado. Entre em contato com o suporte.',
    'auth/argument-error': 'Dados inválidos fornecidos.',
    'auth/invalid-user-token': 'Sua sessão expirou. Faça login novamente.',
    'auth/user-token-expired': 'Sua sessão expirou. Faça login novamente.',
    'auth/null-user': 'Nenhum usuário autenticado. Faça login novamente.',
    'auth/tenant-id-mismatch': 'Erro de configuração. Entre em contato com o suporte.',
    
    // Google Sign-in specific
    'auth/popup-blocked': 'Por favor, permita popups para fazer login com Google.',
    'auth/popup-closed-by-user': 'Janela de login foi fechada. Tente novamente.',
    'auth/cancelled-popup-request': 'Login cancelado pelo usuário.',
    'auth/redirect-cancelled-by-user': 'Login cancelado pelo usuário.',
    'auth/redirect-operation-pending': 'Uma operação de login já está em andamento.',
    
    // Registration specific
    'auth/email-already-exists': 'Já existe uma conta com este email.',
    'auth/phone-number-already-exists': 'Este número de telefone já está sendo usado.',
    'auth/uid-already-exists': 'Este usuário já existe no sistema.',
    
    // Password reset
    'auth/user-not-found': 'Nenhuma conta encontrada com este email.',
    'auth/invalid-continue-uri': 'URL de continuação inválida.',
    'auth/missing-continue-uri': 'URL de continuação obrigatória.',
    
    // Generic fallbacks
    'auth/internal-error': 'Erro interno do servidor. Tente novamente mais tarde.',
    'auth/invalid-tenant-id': 'Configuração inválida. Entre em contato com o suporte.',
    'auth/multi-factor-info-not-found': 'Informações de autenticação não encontradas.',
    'auth/multi-factor-auth-required': 'Autenticação adicional necessária.',
  }

  return errorMessages[errorCode] || 'Ocorreu um erro inesperado. Tente novamente.'
}

export const getBackendErrorMessage = (error: any): string => {
  // Handle different types of backend errors
  if (error.response) {
    const status = error.response.status
    const data = error.response.data
    
    // Check if backend provided a custom message
    if (data?.message) {
      return data.message
    }
    
    if (data?.detail) {
      return data.detail
    }
    
    // Handle by HTTP status
    switch (status) {
      case 400:
        return 'Dados inválidos fornecidos. Verifique as informações e tente novamente.'
      case 401:
        return 'Email ou senha incorretos. Verifique suas credenciais.'
      case 403:
        return 'Você não tem permissão para realizar esta ação.'
      case 404:
        return 'Serviço não encontrado. Verifique se o sistema está funcionando corretamente.'
      case 409:
        return 'Este email já está sendo usado por outra conta.'
      case 422:
        return 'Os dados fornecidos são inválidos. Verifique e tente novamente.'
      case 429:
        return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.'
      case 500:
        return 'Erro no servidor. Tente novamente mais tarde.'
      case 502:
        return 'Servidor temporariamente indisponível. Tente novamente em alguns minutos.'
      case 503:
        return 'Serviço em manutenção. Tente novamente mais tarde.'
      default:
        return 'Erro de comunicação com o servidor. Tente novamente.'
    }
  }
  
  // Network or connection errors
  if (error.code === 'NETWORK_ERROR' || error.message?.includes('Network Error')) {
    return 'Erro de conexão. Verifique sua internet e tente novamente.'
  }
  
  if (error.code === 'TIMEOUT' || error.message?.includes('timeout')) {
    return 'A operação demorou muito para responder. Tente novamente.'
  }
  
  // Firebase specific errors that might leak through
  if (error.code && error.code.startsWith('auth/')) {
    return getFirebaseErrorMessage(error.code)
  }
  
  // Generic fallback
  return error.message || 'Ocorreu um erro inesperado. Tente novamente.'
}

// Helper to create a user-friendly error object
export const createAuthError = (originalError: any, context?: string): Error => {
  let message: string
  
  if (originalError.code && originalError.code.startsWith('auth/')) {
    message = getFirebaseErrorMessage(originalError.code)
  } else if (originalError.response) {
    message = getBackendErrorMessage(originalError)
  } else {
    message = getBackendErrorMessage(originalError)
  }
  
  const error = new Error(message)
  error.name = 'AuthError'
  
  // Preserve original error for debugging
  ;(error as any).originalError = originalError
  ;(error as any).context = context
  
  return error
}