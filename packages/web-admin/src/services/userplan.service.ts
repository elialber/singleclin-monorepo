import { api } from './api'
import { UserPlan, PurchasePlanRequest, UserPlanResponse, UserPlansResponse } from '@/types/userplan'

export const userPlanService = {
  /**
   * Get user's active plans
   */
  async getUserPlans(userId: string): Promise<UserPlan[]> {
    try {
      const response = await api.get<UserPlansResponse>(`/users/${userId}/plans`)
      return response.data.data || []
    } catch (error: any) {
      console.error('Error fetching user plans:', error)
      
      // Mock data for development
      const mockPlans: UserPlan[] = [
        {
          id: '1',
          userId,
          planId: 'plan-1',
          plan: {
            id: 'plan-1',
            name: 'Plano Básico',
            description: 'Plano com 100 créditos',
            credits: 100,
            price: 999.00,
            originalPrice: 1299.00,
            validityDays: 365,
            isActive: true,
            displayOrder: 0,
            isFeatured: false,
            createdAt: '2024-01-15T10:00:00Z',
            updatedAt: '2024-01-15T10:00:00Z',
            discountPercentage: 23.09,
            pricePerCredit: 9.99
          },
          credits: 100,
          creditsRemaining: 75,
          creditsUsed: 25,
          amountPaid: 999.00,
          expirationDate: '2025-12-15T10:00:00Z',
          isActive: true,
          isExpired: false,
          paymentMethod: 'Cartão de Crédito',
          notes: 'Compra via app móvel',
          createdAt: '2024-12-15T10:00:00Z',
          updatedAt: '2024-12-15T10:00:00Z'
        }
      ]
      
      return mockPlans
    }
  },

  /**
   * Purchase a plan for a user
   */
  async purchasePlan(userId: string, request: PurchasePlanRequest): Promise<UserPlan> {
    try {
      const response = await api.post<UserPlanResponse>(`/users/${userId}/purchase-plan`, request)
      if (!response.data.success || !response.data.data) {
        throw new Error(response.data.message || 'Failed to purchase plan')
      }
      return response.data.data
    } catch (error: any) {
      console.error('Error purchasing plan:', error)
      
      if (error.response?.data?.message) {
        throw new Error(error.response.data.message)
      }
      
      throw new Error('Erro ao comprar plano. Tente novamente.')
    }
  },

  /**
   * Get specific user plan by ID
   */
  async getUserPlan(userId: string, planId: string): Promise<UserPlan | null> {
    try {
      const response = await api.get<UserPlanResponse>(`/users/${userId}/plans/${planId}`)
      return response.data.data
    } catch (error: any) {
      console.error('Error fetching user plan:', error)
      return null
    }
  }
}