import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { clinicService, ClinicQueryParams } from '@/services/clinic.service'
import { Clinic, CreateClinicRequest, UpdateClinicRequest } from '@/types/clinic'
import { useNotification } from '@/hooks/useNotification'

// Query keys
export const clinicKeys = {
  all: ['clinics'] as const,
  lists: () => [...clinicKeys.all, 'list'] as const,
  list: (params: ClinicQueryParams) => [...clinicKeys.lists(), params] as const,
  details: () => [...clinicKeys.all, 'detail'] as const,
  detail: (id: string) => [...clinicKeys.details(), id] as const,
  statistics: () => [...clinicKeys.all, 'statistics'] as const,
}

// Hook para listagem de clínicas ativas (público)
export function useActiveClinics() {
  return useQuery({
    queryKey: ['clinics', 'active'],
    queryFn: () => clinicService.getActiveClinics(),
    staleTime: 5 * 60 * 1000, // 5 minutos
    refetchOnWindowFocus: false,
  })
}

// Hook para listagem de clínicas com paginação e filtros
export function useClinics(params: ClinicQueryParams = {}) {
  return useQuery({
    queryKey: clinicKeys.list(params),
    queryFn: () => clinicService.getClinics(params),
    staleTime: 5 * 60 * 1000, // 5 minutos
    refetchOnWindowFocus: false,
  })
}

// Hook para obter uma clínica específica
export function useClinic(id: string, enabled = true) {
  return useQuery({
    queryKey: clinicKeys.detail(id),
    queryFn: () => clinicService.getClinic(id),
    enabled: enabled && !!id,
    staleTime: 5 * 60 * 1000, // 5 minutos
  })
}

// Hook para obter estatísticas de clínicas
export function useClinicStatistics() {
  return useQuery({
    queryKey: clinicKeys.statistics(),
    queryFn: () => clinicService.getClinicStatistics(),
    staleTime: 10 * 60 * 1000, // 10 minutos
    refetchOnWindowFocus: false,
  })
}

// Hook para criar uma nova clínica
export function useCreateClinic() {
  const queryClient = useQueryClient()
  const { showSuccess, showError } = useNotification()

  return useMutation({
    mutationFn: (data: CreateClinicRequest) => clinicService.createClinic(data),
    onSuccess: (newClinic) => {
      // Invalidar todas as queries de clínicas para refetch
      queryClient.invalidateQueries({ queryKey: clinicKeys.all })
      
      // Adicionar a nova clínica ao cache (otimistic update)
      queryClient.setQueryData(clinicKeys.detail(newClinic.id), newClinic)
      
      showSuccess('Clínica criada com sucesso!')
    },
    onError: (error: any) => {
      // Don't show notification for validation errors (400) - let the form handle them
      if (error.response?.status === 400 && error.response?.data?.errors) {
        return
      }
      
      const message = error.response?.data?.detail || 
                     error.response?.data?.message || 
                     'Erro ao criar clínica'
      showError(message)
    },
  })
}

// Hook para atualizar uma clínica
export function useUpdateClinic() {
  const queryClient = useQueryClient()
  const { showSuccess, showError } = useNotification()

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdateClinicRequest }) =>
      clinicService.updateClinic(id, data),
    onSuccess: (updatedClinic) => {
      // Atualizar a clínica no cache
      queryClient.setQueryData(clinicKeys.detail(updatedClinic.id), updatedClinic)
      
      // Invalidar listas para refetch com dados atualizados
      queryClient.invalidateQueries({ queryKey: clinicKeys.all })
      
      showSuccess('Clínica atualizada com sucesso!')
    },
    onError: (error: any) => {
      // Don't show notification for validation errors (400) - let the form handle them
      if (error.response?.status === 400 && error.response?.data?.errors) {
        return
      }
      
      const message = error.response?.data?.detail || 
                     error.response?.data?.message || 
                     'Erro ao atualizar clínica'
      showError(message)
    },
  })
}

// Hook para excluir uma clínica
export function useDeleteClinic() {
  const queryClient = useQueryClient()
  const { showSuccess, showError } = useNotification()

  return useMutation({
    mutationFn: (id: string) => clinicService.deleteClinic(id),
    onSuccess: (_, deletedId) => {
      // Remover a clínica do cache
      queryClient.removeQueries({ queryKey: clinicKeys.detail(deletedId) })
      
      // Invalidar listas para refetch
      queryClient.invalidateQueries({ queryKey: clinicKeys.all })
      
      showSuccess('Clínica excluída com sucesso!')
    },
    onError: (error: any) => {
      const message = error.response?.data?.detail || 
                     error.response?.data?.message || 
                     'Erro ao excluir clínica'
      showError(message)
    },
  })
}

// Hook para alternar status da clínica (ativar/desativar)
export function useToggleClinicStatus() {
  const queryClient = useQueryClient()
  const { showSuccess, showError } = useNotification()

  return useMutation({
    mutationFn: (id: string) => clinicService.toggleClinicStatus(id),
    onMutate: async (id) => {
      // Cancel any outgoing refetches
      await queryClient.cancelQueries({ queryKey: clinicKeys.detail(id) })
      
      // Snapshot the previous value
      const previousClinic = queryClient.getQueryData<Clinic>(clinicKeys.detail(id))
      
      // Optimistically update the cache
      if (previousClinic) {
        const optimisticClinic = { ...previousClinic, isActive: !previousClinic.isActive }
        queryClient.setQueryData(clinicKeys.detail(id), optimisticClinic)
      }
      
      return { previousClinic }
    },
    onSuccess: (updatedClinic) => {
      // Atualizar a clínica no cache com os dados reais do servidor
      queryClient.setQueryData(clinicKeys.detail(updatedClinic.id), updatedClinic)
      
      // Invalidar listas para refetch
      queryClient.invalidateQueries({ queryKey: clinicKeys.all })
      
      const status = updatedClinic.isActive ? 'ativada' : 'desativada'
      showSuccess(`Clínica ${status} com sucesso!`)
    },
    onError: (error: any, id, context) => {
      // Reverter para o estado anterior em caso de erro
      if (context?.previousClinic) {
        queryClient.setQueryData(clinicKeys.detail(id), context.previousClinic)
      }
      
      const message = error.response?.data?.detail || 
                     error.response?.data?.message || 
                     'Erro ao alterar status da clínica'
      showError(message)
    },
  })
}

// Hook para pré-carregar uma clínica (útil para hover effects ou navegação)
export function usePrefetchClinic() {
  const queryClient = useQueryClient()

  return (id: string) => {
    queryClient.prefetchQuery({
      queryKey: clinicKeys.detail(id),
      queryFn: () => clinicService.getClinic(id),
      staleTime: 5 * 60 * 1000, // 5 minutos
    })
  }
}

// Hook para invalidar todas as queries de clínicas (útil para refresh manual)
export function useInvalidateClinics() {
  const queryClient = useQueryClient()

  return () => {
    queryClient.invalidateQueries({ queryKey: clinicKeys.all })
  }
}