import { api } from './api'
import { Plan, CreatePlanRequest, UpdatePlanRequest, PlanListResponse } from '@/types/plan'

export interface PlanQueryParams {
  pageNumber?: number
  pageSize?: number
  searchTerm?: string
  isActive?: boolean
  minPrice?: number
  maxPrice?: number
  minCredits?: number
  maxCredits?: number
  isFeatured?: boolean
  sortBy?: 'name' | 'price' | 'credits' | 'validitydays' | 'createdat' | 'updatedat' | 'isfeatured' | 'isactive' | 'displayorder'
  sortDirection?: 'asc' | 'desc'
}

export const planService = {
  async getActivePlans(): Promise<Plan[]> {
    const response = await api.get<Plan[]>('/plan/active')
    return response.data
  },

  async getPlans(params: PlanQueryParams = {}): Promise<PlanListResponse> {
    // For now, use the public endpoint and simulate pagination
    const activePlans = await this.getActivePlans()
    
    // Apply client-side filtering and sorting
    let filteredPlans = activePlans

    if (params.searchTerm) {
      const searchLower = params.searchTerm.toLowerCase()
      filteredPlans = filteredPlans.filter(plan => 
        plan.name.toLowerCase().includes(searchLower) ||
        plan.description?.toLowerCase().includes(searchLower)
      )
    }

    if (params.minPrice !== undefined) {
      filteredPlans = filteredPlans.filter(plan => plan.price >= params.minPrice!)
    }

    if (params.maxPrice !== undefined) {
      filteredPlans = filteredPlans.filter(plan => plan.price <= params.maxPrice!)
    }

    if (params.minCredits !== undefined) {
      filteredPlans = filteredPlans.filter(plan => plan.credits >= params.minCredits!)
    }

    if (params.maxCredits !== undefined) {
      filteredPlans = filteredPlans.filter(plan => plan.credits <= params.maxCredits!)
    }

    if (params.isFeatured !== undefined) {
      filteredPlans = filteredPlans.filter(plan => plan.isFeatured === params.isFeatured)
    }

    // Apply sorting
    if (params.sortBy) {
      filteredPlans.sort((a, b) => {
        const direction = params.sortDirection === 'desc' ? -1 : 1
        
        switch (params.sortBy) {
          case 'name':
            return direction * a.name.localeCompare(b.name)
          case 'price':
            return direction * (a.price - b.price)
          case 'credits':
            return direction * (a.credits - b.credits)
          case 'validitydays':
            return direction * (a.validityDays - b.validityDays)
          case 'createdat':
            return direction * (new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime())
          case 'updatedat':
            return direction * (new Date(a.updatedAt).getTime() - new Date(b.updatedAt).getTime())
          case 'isfeatured':
            return direction * (Number(a.isFeatured) - Number(b.isFeatured))
          case 'isactive':
            return direction * (Number(a.isActive) - Number(b.isActive))
          case 'displayorder':
            return direction * (a.displayOrder - b.displayOrder)
          default:
            return 0
        }
      })
    }

    // Apply pagination
    const pageSize = params.pageSize || 10
    const pageNumber = params.pageNumber || 1
    const startIndex = (pageNumber - 1) * pageSize
    const endIndex = startIndex + pageSize
    const paginatedPlans = filteredPlans.slice(startIndex, endIndex)

    return {
      data: paginatedPlans,
      totalCount: filteredPlans.length,
      pageNumber: pageNumber,
      pageSize: pageSize,
      totalPages: Math.ceil(filteredPlans.length / pageSize)
    }
  },

  async getPlan(id: string): Promise<Plan> {
    const response = await api.get<Plan>(`/plan/${id}`)
    return response.data
  },

  async createPlan(data: CreatePlanRequest): Promise<Plan> {
    const response = await api.post<Plan>('/plan', data)
    return response.data
  },

  async updatePlan(id: string, data: UpdatePlanRequest): Promise<Plan> {
    const response = await api.put<Plan>(`/plan/${id}`, data)
    return response.data
  },

  async deletePlan(id: string): Promise<void> {
    await api.delete(`/plan/${id}`)
  },

  async togglePlanStatus(id: string): Promise<Plan> {
    const response = await api.patch<Plan>(`/plan/${id}/toggle-status`)
    return response.data
  },
}