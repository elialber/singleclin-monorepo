import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { userPlanService } from '@/services/userplan.service'
import { patientService } from '@/services/patient.service'
import { PurchasePlanRequest } from '@/types/userplan'
import { useNotification } from './useNotification'

export const useUserPlans = (userId: string) => {
  return useQuery({
    queryKey: ['userPlans', userId],
    queryFn: () => patientService.getUserPlans(userId),
    enabled: !!userId,
    staleTime: 5 * 60 * 1000, // 5 minutes
  })
}

export const useUserPlan = (userId: string, planId: string) => {
  return useQuery({
    queryKey: ['userPlan', userId, planId],
    queryFn: () => userPlanService.getUserPlan(userId, planId),
    enabled: !!userId && !!planId,
  })
}

export const usePurchasePlan = () => {
  const queryClient = useQueryClient()
  const { showNotification } = useNotification()

  return useMutation({
    mutationFn: ({ userId, request }: { userId: string; request: PurchasePlanRequest }) =>
      patientService.purchasePlan(userId, request.planId, request.paymentMethod),
    
    onSuccess: (data, variables) => {
      // Invalidate and refetch user plans
      queryClient.invalidateQueries({ queryKey: ['userPlans', variables.userId] })
      
      showNotification('Plano atribuído com sucesso!', 'success')
    },
    
    onError: (error: Error) => {
      showNotification(error.message || 'Erro ao atribuir plano', 'error')
    }
  })
}

export const useCancelUserPlan = () => {
  const queryClient = useQueryClient()
  const { showNotification } = useNotification()

  return useMutation({
    mutationFn: ({ userId, userPlanId, reason }: { userId: string; userPlanId: string; reason?: string }) =>
      patientService.cancelUserPlan(userId, userPlanId, reason),
    
    onSuccess: (data, variables) => {
      // Invalidate and refetch user plans
      queryClient.invalidateQueries({ queryKey: ['userPlans', variables.userId] })
      
      showNotification('Plano cancelado com sucesso!', 'success')
    },
    
    onError: (error: Error) => {
      showNotification(error.message || 'Erro ao cancelar plano', 'error')
    }
  })
}