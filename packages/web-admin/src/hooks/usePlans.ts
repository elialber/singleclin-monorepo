import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { planService, PlanQueryParams } from '@/services/plan.service'
import { Plan, CreatePlanRequest, UpdatePlanRequest } from '@/types/plan'
import { useNotification } from '@/hooks/useNotification'

// Query keys
export const planKeys = {
  all: ['plans'] as const,
  lists: () => [...planKeys.all, 'list'] as const,
  list: (params: PlanQueryParams) => [...planKeys.lists(), params] as const,
  details: () => [...planKeys.all, 'detail'] as const,
  detail: (id: string) => [...planKeys.details(), id] as const,
}

// Hook para listagem de planos ativos (público)
export function useActivePlans() {
  return useQuery({
    queryKey: ['plans', 'active'],
    queryFn: () => planService.getActivePlans(),
    staleTime: 5 * 60 * 1000, // 5 minutos
    refetchOnWindowFocus: false,
  })
}

// Hook para listagem de planos com paginação e filtros
export function usePlans(params: PlanQueryParams = {}) {
  return useQuery({
    queryKey: planKeys.list(params),
    queryFn: () => planService.getPlans(params),
    staleTime: 5 * 60 * 1000, // 5 minutos
    refetchOnWindowFocus: false,
  })
}

// Hook para obter um plano específico
export function usePlan(id: string, enabled = true) {
  return useQuery({
    queryKey: planKeys.detail(id),
    queryFn: () => planService.getPlan(id),
    enabled: enabled && !!id,
    staleTime: 5 * 60 * 1000, // 5 minutos
  })
}

// Hook para criar um novo plano
export function useCreatePlan() {
  const queryClient = useQueryClient()
  const { showSuccess, showError } = useNotification()

  return useMutation({
    mutationFn: (data: CreatePlanRequest) => planService.createPlan(data),
    onSuccess: (newPlan) => {
      // Invalidar todas as queries de planos para refetch
      queryClient.invalidateQueries({ queryKey: planKeys.all })
      
      // Adicionar o novo plano ao cache (otimistic update)
      queryClient.setQueryData(planKeys.detail(newPlan.id), newPlan)
      
      showSuccess('Plano criado com sucesso!')
    },
    onError: (error: any) => {
      // Don't show notification for validation errors (400) - let the form handle them
      if (error.response?.status === 400 && error.response?.data?.errors) {
        return
      }
      
      const message = error.response?.data?.detail || 
                     error.response?.data?.message || 
                     'Erro ao criar plano'
      showError(message)
    },
  })
}

// Hook para atualizar um plano
export function useUpdatePlan() {
  const queryClient = useQueryClient()
  const { showSuccess, showError } = useNotification()

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdatePlanRequest }) =>
      planService.updatePlan(id, data),
    onSuccess: (updatedPlan) => {
      // Atualizar o plano no cache
      queryClient.setQueryData(planKeys.detail(updatedPlan.id), updatedPlan)
      
      // Invalidar listas para refetch com dados atualizados
      queryClient.invalidateQueries({ queryKey: planKeys.all })
      
      showSuccess('Plano atualizado com sucesso!')
    },
    onError: (error: any) => {
      // Don't show notification for validation errors (400) - let the form handle them
      if (error.response?.status === 400 && error.response?.data?.errors) {
        return
      }
      
      const message = error.response?.data?.detail || 
                     error.response?.data?.message || 
                     'Erro ao atualizar plano'
      showError(message)
    },
  })
}

// Hook para excluir um plano
export function useDeletePlan() {
  const queryClient = useQueryClient()
  const { showSuccess, showError } = useNotification()

  return useMutation({
    mutationFn: (id: string) => planService.deletePlan(id),
    onSuccess: (_, deletedId) => {
      // Remover o plano do cache
      queryClient.removeQueries({ queryKey: planKeys.detail(deletedId) })
      
      // Invalidar listas para refetch
      queryClient.invalidateQueries({ queryKey: planKeys.all })
      
      showSuccess('Plano excluído com sucesso!')
    },
    onError: (error: any) => {
      const message = error.response?.data?.detail || 
                     error.response?.data?.message || 
                     'Erro ao excluir plano'
      showError(message)
    },
  })
}

// Hook para alternar status do plano (ativar/desativar)
export function useTogglePlanStatus() {
  const queryClient = useQueryClient()
  const { showSuccess, showError } = useNotification()

  return useMutation({
    mutationFn: (id: string) => planService.togglePlanStatus(id),
    onMutate: async (id) => {
      // Cancel any outgoing refetches
      await queryClient.cancelQueries({ queryKey: planKeys.detail(id) })
      
      // Snapshot the previous value
      const previousPlan = queryClient.getQueryData<Plan>(planKeys.detail(id))
      
      // Optimistically update the cache
      if (previousPlan) {
        const optimisticPlan = { ...previousPlan, isActive: !previousPlan.isActive }
        queryClient.setQueryData(planKeys.detail(id), optimisticPlan)
      }
      
      return { previousPlan }
    },
    onSuccess: (updatedPlan) => {
      // Atualizar o plano no cache com os dados reais do servidor
      queryClient.setQueryData(planKeys.detail(updatedPlan.id), updatedPlan)
      
      // Invalidar listas para refetch
      queryClient.invalidateQueries({ queryKey: planKeys.all })
      
      const status = updatedPlan.isActive ? 'ativado' : 'desativado'
      showSuccess(`Plano ${status} com sucesso!`)
    },
    onError: (error: any, id, context) => {
      // Reverter para o estado anterior em caso de erro
      if (context?.previousPlan) {
        queryClient.setQueryData(planKeys.detail(id), context.previousPlan)
      }
      
      const message = error.response?.data?.detail || 
                     error.response?.data?.message || 
                     'Erro ao alterar status do plano'
      showError(message)
    },
  })
}

// Hook para pré-carregar um plano (útil para hover effects ou navegação)
export function usePrefetchPlan() {
  const queryClient = useQueryClient()

  return (id: string) => {
    queryClient.prefetchQuery({
      queryKey: planKeys.detail(id),
      queryFn: () => planService.getPlan(id),
      staleTime: 5 * 60 * 1000, // 5 minutos
    })
  }
}

// Hook para invalidar todas as queries de planos (útil para refresh manual)
export function useInvalidatePlans() {
  const queryClient = useQueryClient()

  return () => {
    queryClient.invalidateQueries({ queryKey: planKeys.all })
  }
}