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

    try {
      const response = await api.get<PlanListResponse>(`/plans?${queryParams.toString()}`)
      return response.data
    } catch (error: any) {
      if (error.response?.status === 404) {
        // Return mock data if endpoint not implemented yet
        console.warn('Plans endpoint not implemented, returning mock data')
        
        const mockPlans: Plan[] = [
          {
            id: '1',
            name: 'Plano Básico',
            description: 'Ideal para consultas de rotina e exames simples',
            credits: 10,
            price: 149.90,
            isActive: true,
            clinicId: '1',
            clinicName: 'Clínica Saúde Total',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '2',
            name: 'Plano Intermediário',
            description: 'Inclui consultas especializadas e exames laboratoriais',
            credits: 25,
            price: 299.90,
            isActive: true,
            clinicId: '1',
            clinicName: 'Clínica Saúde Total',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '3',
            name: 'Plano Premium',
            description: 'Acesso completo a todos os serviços e especialidades',
            credits: 50,
            price: 549.90,
            isActive: true,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '4',
            name: 'Plano Família',
            description: 'Ideal para famílias com até 4 pessoas',
            credits: 100,
            price: 899.90,
            isActive: true,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '5',
            name: 'Plano Empresarial',
            description: 'Soluções corporativas para empresas',
            credits: 200,
            price: 1499.90,
            isActive: false,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          },
        ]

        // Apply filters
        let filtered = [...mockPlans]
        
        if (params.search) {
          filtered = filtered.filter(p => 
            p.name.toLowerCase().includes(params.search!.toLowerCase()) ||
            p.description.toLowerCase().includes(params.search!.toLowerCase())
          )
        }
        
        if (params.clinicId) {
          filtered = filtered.filter(p => p.clinicId === params.clinicId)
        }
        
        if (params.isActive !== undefined) {
          filtered = filtered.filter(p => p.isActive === params.isActive)
        }

        // Pagination
        const page = params.page || 1
        const limit = params.limit || 10
        const start = (page - 1) * limit
        const end = start + limit
        const paginatedData = filtered.slice(start, end)

        return {
          data: paginatedData,
          total: filtered.length,
          page,
          limit,
        }
      }
      throw error
    }
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