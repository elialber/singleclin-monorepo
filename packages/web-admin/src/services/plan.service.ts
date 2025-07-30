import { api } from './api'
import { Plan, CreatePlanRequest, UpdatePlanRequest, PlanListResponse } from '@/types/plan'

export interface PlanQueryParams {
  page?: number
  limit?: number
  search?: string
  clinicId?: string
  isActive?: boolean
}

export const planService = {
  async getPlans(params: PlanQueryParams = {}): Promise<PlanListResponse> {
    const queryParams = new URLSearchParams()
    
    if (params.page) queryParams.append('page', params.page.toString())
    if (params.limit) queryParams.append('limit', params.limit.toString())
    if (params.search) queryParams.append('search', params.search)
    if (params.clinicId) queryParams.append('clinicId', params.clinicId)
    if (params.isActive !== undefined) queryParams.append('isActive', params.isActive.toString())

    const response = await api.get<PlanListResponse>(`/plans?${queryParams.toString()}`)
    return response.data
  },

  async getPlan(id: string): Promise<Plan> {
    const response = await api.get<{ data: Plan }>(`/plans/${id}`)
    return response.data.data
  },

  async createPlan(data: CreatePlanRequest): Promise<Plan> {
    const response = await api.post<{ data: Plan }>('/plans', data)
    return response.data.data
  },

  async updatePlan(id: string, data: UpdatePlanRequest): Promise<Plan> {
    const response = await api.put<{ data: Plan }>(`/plans/${id}`, data)
    return response.data.data
  },

  async deletePlan(id: string): Promise<void> {
    await api.delete(`/plans/${id}`)
  },

  async togglePlanStatus(id: string): Promise<Plan> {
    const response = await api.patch<{ data: Plan }>(`/plans/${id}/toggle-status`)
    return response.data.data
  },
}