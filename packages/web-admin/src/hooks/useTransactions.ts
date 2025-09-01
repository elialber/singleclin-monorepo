import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { transactionService, TransactionQueryParams } from '@/services/transaction.service'
import { 
  Transaction, 
  TransactionUpdate, 
  TransactionCancel, 
  DashboardMetrics 
} from '@/types/transaction'
import { useNotification } from '@/hooks/useNotification'
import { getTransactionErrorMessage } from '@/utils/transactionErrorHandler'

// Query keys following TanStack Query best practices
export const transactionKeys = {
  all: ['transactions'] as const,
  lists: () => [...transactionKeys.all, 'list'] as const,
  list: (params: TransactionQueryParams) => [...transactionKeys.lists(), params] as const,
  details: () => [...transactionKeys.all, 'detail'] as const,
  detail: (id: string) => [...transactionKeys.details(), id] as const,
  metrics: () => [...transactionKeys.all, 'metrics'] as const,
}

/**
 * Hook para listagem de transações com filtros avançados e paginação
 * Suporta todos os filtros do backend: busca, datas, valores, créditos, etc.
 */
export function useTransactions(params: TransactionQueryParams = {}) {
  return useQuery({
    queryKey: transactionKeys.list(params),
    queryFn: () => transactionService.getTransactions(params),
    staleTime: 2 * 60 * 1000, // 2 minutos (dados mudam com frequência)
    refetchOnWindowFocus: true, // Refetch quando usuário volta à janela
    refetchInterval: 5 * 60 * 1000, // Refetch automático a cada 5 minutos
    keepPreviousData: true, // Manter dados anteriores durante loading de nova página
  })
}

/**
 * Hook para obter uma transação específica por ID
 */
export function useTransaction(id: string, enabled = true) {
  return useQuery({
    queryKey: transactionKeys.detail(id),
    queryFn: () => transactionService.getTransaction(id),
    enabled: enabled && !!id,
    staleTime: 5 * 60 * 1000, // 5 minutos
    refetchOnWindowFocus: false,
  })
}

/**
 * Hook para obter métricas do dashboard de transações
 */
export function useTransactionMetrics() {
  return useQuery({
    queryKey: transactionKeys.metrics(),
    queryFn: () => transactionService.getDashboardMetrics(),
    staleTime: 1 * 60 * 1000, // 1 minuto (métricas devem ser atualizadas)
    refetchOnWindowFocus: true,
    refetchInterval: 2 * 60 * 1000, // Refetch a cada 2 minutos
  })
}

/**
 * Hook para atualizar uma transação (campos editáveis limitados)
 */
export function useUpdateTransaction() {
  const queryClient = useQueryClient()
  const { showSuccess, showError } = useNotification()

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: TransactionUpdate }) =>
      transactionService.updateTransaction(id, data),
    onMutate: async ({ id, data }) => {
      // Cancel outgoing refetches para evitar conflitos
      await queryClient.cancelQueries({ queryKey: transactionKeys.detail(id) })
      
      // Snapshot do valor anterior
      const previousTransaction = queryClient.getQueryData<Transaction>(transactionKeys.detail(id))
      
      // Update otimista do cache
      if (previousTransaction) {
        const optimisticTransaction = { 
          ...previousTransaction, 
          ...data,
          updatedAt: new Date().toISOString()
        }
        queryClient.setQueryData(transactionKeys.detail(id), optimisticTransaction)
      }
      
      return { previousTransaction }
    },
    onSuccess: (updatedTransaction) => {
      // Atualizar o cache com dados reais do servidor
      queryClient.setQueryData(transactionKeys.detail(updatedTransaction.id), updatedTransaction)
      
      // Invalidar listas para refetch
      queryClient.invalidateQueries({ queryKey: transactionKeys.lists() })
      
      // Invalidar métricas pois podem ter mudado
      queryClient.invalidateQueries({ queryKey: transactionKeys.metrics() })
      
      showSuccess('Transação atualizada com sucesso!')
    },
    onError: (error: any, { id }, context) => {
      // Reverter para estado anterior em caso de erro
      if (context?.previousTransaction) {
        queryClient.setQueryData(transactionKeys.detail(id), context.previousTransaction)
      }
      
      // Don't show notification for validation errors (400) - let the form handle them
      if (error.response?.status === 400 && error.response?.data?.errors) {
        return
      }
      
      const message = getTransactionErrorMessage(error, 'Atualização de transação')
      showError(message)
    },
  })
}

/**
 * Hook para cancelar uma transação com opção de refund
 */
export function useCancelTransaction() {
  const queryClient = useQueryClient()
  const { showSuccess, showError } = useNotification()

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: TransactionCancel }) =>
      transactionService.cancelTransaction(id, data),
    onMutate: async ({ id }) => {
      // Cancel outgoing refetches
      await queryClient.cancelQueries({ queryKey: transactionKeys.detail(id) })
      
      // Snapshot do valor anterior
      const previousTransaction = queryClient.getQueryData<Transaction>(transactionKeys.detail(id))
      
      // Update otimista - marcar como cancelada
      if (previousTransaction) {
        const optimisticTransaction = { 
          ...previousTransaction, 
          status: 'Cancelled' as const,
          cancellationDate: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }
        queryClient.setQueryData(transactionKeys.detail(id), optimisticTransaction)
      }
      
      return { previousTransaction }
    },
    onSuccess: (cancelledTransaction) => {
      // Atualizar cache com dados reais
      queryClient.setQueryData(transactionKeys.detail(cancelledTransaction.id), cancelledTransaction)
      
      // Invalidar listas e métricas
      queryClient.invalidateQueries({ queryKey: transactionKeys.lists() })
      queryClient.invalidateQueries({ queryKey: transactionKeys.metrics() })
      
      const refundMessage = cancelledTransaction.cancellationReason?.includes('refund') ? 
        ' e créditos foram devolvidos' : ''
      showSuccess(`Transação cancelada com sucesso${refundMessage}!`)
    },
    onError: (error: any, { id }, context) => {
      // Reverter para estado anterior
      if (context?.previousTransaction) {
        queryClient.setQueryData(transactionKeys.detail(id), context.previousTransaction)
      }
      
      // Don't show notification for validation errors (400) - let the form handle them
      if (error.response?.status === 400 && error.response?.data?.errors) {
        return
      }
      
      const message = getTransactionErrorMessage(error, 'Cancelamento de transação')
      showError(message)
    },
  })
}

/**
 * Hook para exportar transações em diferentes formatos
 */
export function useExportTransactions() {
  const { showSuccess, showError } = useNotification()

  return useMutation({
    mutationFn: ({ 
      params = {}, 
      format = 'xlsx' 
    }: { 
      params?: TransactionQueryParams
      format?: 'xlsx' | 'csv' | 'pdf'
    }) => transactionService.exportTransactions(params, format),
    onSuccess: (blob, { format }) => {
      // Create download link
      const url = window.URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      
      // Set filename based on format and current date
      const date = new Date().toISOString().split('T')[0]
      const filename = `transacoes_${date}.${format}`
      link.setAttribute('download', filename)
      
      // Trigger download
      document.body.appendChild(link)
      link.click()
      
      // Cleanup
      link.remove()
      window.URL.revokeObjectURL(url)
      
      const formatName = format === 'xlsx' ? 'Excel' : format.toUpperCase()
      showSuccess(`Relatório exportado em ${formatName} com sucesso!`)
    },
    onError: (error: any) => {
      const message = getTransactionErrorMessage(error, 'Exportação de transações')
      showError(message)
    },
  })
}

/**
 * Hook para pré-carregar uma transação (útil para hover effects, etc.)
 */
export function usePrefetchTransaction() {
  const queryClient = useQueryClient()

  return (id: string) => {
    queryClient.prefetchQuery({
      queryKey: transactionKeys.detail(id),
      queryFn: () => transactionService.getTransaction(id),
      staleTime: 5 * 60 * 1000, // 5 minutos
    })
  }
}

/**
 * Hook para invalidar queries de transações (útil para refresh manual)
 */
export function useInvalidateTransactions() {
  const queryClient = useQueryClient()

  return {
    // Invalidar todas as queries de transações
    invalidateAll: () => {
      queryClient.invalidateQueries({ queryKey: transactionKeys.all })
    },
    
    // Invalidar apenas listas (manter detalhes individuais)
    invalidateLists: () => {
      queryClient.invalidateQueries({ queryKey: transactionKeys.lists() })
    },
    
    // Invalidar apenas métricas
    invalidateMetrics: () => {
      queryClient.invalidateQueries({ queryKey: transactionKeys.metrics() })
    },
    
    // Invalidar uma transação específica
    invalidateTransaction: (id: string) => {
      queryClient.invalidateQueries({ queryKey: transactionKeys.detail(id) })
    }
  }
}

/**
 * Hook para remover dados de transação do cache
 */
export function useRemoveTransactionCache() {
  const queryClient = useQueryClient()

  return (id: string) => {
    queryClient.removeQueries({ queryKey: transactionKeys.detail(id) })
  }
}

/**
 * Hook helper para verificar se existem transações em cache
 */
export function useTransactionCacheStatus() {
  const queryClient = useQueryClient()

  return {
    hasListsInCache: () => {
      return queryClient.getQueriesData({ queryKey: transactionKeys.lists() }).length > 0
    },
    
    hasMetricsInCache: () => {
      return queryClient.getQueryData(transactionKeys.metrics()) !== undefined
    },
    
    hasTransactionInCache: (id: string) => {
      return queryClient.getQueryData(transactionKeys.detail(id)) !== undefined
    }
  }
}