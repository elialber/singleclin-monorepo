import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { patientService, PatientQueryParams } from '@/services/patient.service'
import { Patient, CreatePatientRequest, UpdatePatientRequest } from '@/types/patient'
import { useNotification } from '@/hooks/useNotification'

// Query keys
export const patientKeys = {
  all: ['patients'] as const,
  lists: () => [...patientKeys.all, 'list'] as const,
  list: (params: PatientQueryParams) => [...patientKeys.lists(), params] as const,
  details: () => [...patientKeys.all, 'detail'] as const,
  detail: (id: string) => [...patientKeys.details(), id] as const,
}

// Hook para listagem de pacientes com paginação e filtros
export function usePatients(params: PatientQueryParams = {}) {
  return useQuery({
    queryKey: patientKeys.list(params),
    queryFn: () => patientService.getPatients(params),
    staleTime: 5 * 60 * 1000, // 5 minutos
    refetchOnWindowFocus: false,
  })
}

// Hook para obter um paciente específico
export function usePatient(id: string, enabled = true) {
  return useQuery({
    queryKey: patientKeys.detail(id),
    queryFn: () => patientService.getPatient(id),
    enabled: enabled && !!id,
    staleTime: 5 * 60 * 1000, // 5 minutos
  })
}

// Hook para criar um novo paciente
export function useCreatePatient() {
  const queryClient = useQueryClient()
  const { showSuccess, showError } = useNotification()

  return useMutation({
    mutationFn: (data: CreatePatientRequest) => patientService.createPatient(data),
    onSuccess: (newPatient) => {
      // Invalidar todas as queries de pacientes para refetch
      queryClient.invalidateQueries({ queryKey: patientKeys.all })
      
      // Adicionar o novo paciente ao cache (optimistic update)
      queryClient.setQueryData(patientKeys.detail(newPatient.id), newPatient)
      
      showSuccess('Paciente criado com sucesso!')
    },
    onError: (error: any) => {
      // Don't show notification for validation errors (400) - let the form handle them
      if (error.response?.status === 400 && error.response?.data?.errors) {
        return
      }
      
      const message = error.response?.data?.detail || 
                     error.response?.data?.message || 
                     'Erro ao criar paciente'
      showError(message)
    },
  })
}

// Hook para atualizar um paciente
export function useUpdatePatient() {
  const queryClient = useQueryClient()
  const { showSuccess, showError } = useNotification()

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdatePatientRequest }) =>
      patientService.updatePatient(id, data),
    onSuccess: (updatedPatient) => {
      // Atualizar o paciente no cache
      queryClient.setQueryData(patientKeys.detail(updatedPatient.id), updatedPatient)
      
      // Invalidar listas para refetch com dados atualizados
      queryClient.invalidateQueries({ queryKey: patientKeys.all })
      
      showSuccess('Paciente atualizado com sucesso!')
    },
    onError: (error: any) => {
      // Don't show notification for validation errors (400) - let the form handle them
      if (error.response?.status === 400 && error.response?.data?.errors) {
        return
      }
      
      const message = error.response?.data?.detail || 
                     error.response?.data?.message || 
                     'Erro ao atualizar paciente'
      showError(message)
    },
  })
}

// Hook para excluir um paciente
export function useDeletePatient() {
  const queryClient = useQueryClient()
  const { showSuccess, showError } = useNotification()

  return useMutation({
    mutationFn: (id: string) => patientService.deletePatient(id),
    onSuccess: (_, deletedId) => {
      // Remover o paciente do cache
      queryClient.removeQueries({ queryKey: patientKeys.detail(deletedId) })
      
      // Invalidar listas para refetch
      queryClient.invalidateQueries({ queryKey: patientKeys.all })
      
      showSuccess('Paciente excluído com sucesso!')
    },
    onError: (error: any) => {
      const message = error.response?.data?.detail || 
                     error.response?.data?.message || 
                     'Erro ao excluir paciente'
      showError(message)
    },
  })
}

// Hook para alternar status do paciente (ativar/desativar)
export function useTogglePatientStatus() {
  const queryClient = useQueryClient()
  const { showSuccess, showError } = useNotification()

  return useMutation({
    mutationFn: (id: string) => patientService.togglePatientStatus(id),
    onMutate: async (id) => {
      // Cancel any outgoing refetches
      await queryClient.cancelQueries({ queryKey: patientKeys.detail(id) })
      
      // Snapshot the previous value
      const previousPatient = queryClient.getQueryData<Patient>(patientKeys.detail(id))
      
      // Optimistically update the cache
      if (previousPatient) {
        const optimisticPatient = { ...previousPatient, isActive: !previousPatient.isActive }
        queryClient.setQueryData(patientKeys.detail(id), optimisticPatient)
      }
      
      return { previousPatient }
    },
    onSuccess: (updatedPatient) => {
      // Atualizar o paciente no cache com os dados reais do servidor
      queryClient.setQueryData(patientKeys.detail(updatedPatient.id), updatedPatient)
      
      // Invalidar listas para refetch
      queryClient.invalidateQueries({ queryKey: patientKeys.all })
      
      const status = updatedPatient.isActive ? 'ativado' : 'desativado'
      showSuccess(`Paciente ${status} com sucesso!`)
    },
    onError: (error: any, id, context) => {
      // Reverter para o estado anterior em caso de erro
      if (context?.previousPatient) {
        queryClient.setQueryData(patientKeys.detail(id), context.previousPatient)
      }
      
      const message = error.response?.data?.detail || 
                     error.response?.data?.message || 
                     'Erro ao alterar status do paciente'
      showError(message)
    },
  })
}

// Hook para pré-carregar um paciente (útil para hover effects ou navegação)
export function usePrefetchPatient() {
  const queryClient = useQueryClient()

  return (id: string) => {
    queryClient.prefetchQuery({
      queryKey: patientKeys.detail(id),
      queryFn: () => patientService.getPatient(id),
      staleTime: 5 * 60 * 1000, // 5 minutos
    })
  }
}

// Hook para invalidar todas as queries de pacientes (útil para refresh manual)
export function useInvalidatePatients() {
  const queryClient = useQueryClient()

  return () => {
    queryClient.invalidateQueries({ queryKey: patientKeys.all })
  }
}