export interface Plan {
  id: string
  name: string
  description: string
  credits: number
  price: number
  isActive: boolean
  clinicId?: string
  clinicName?: string
  createdAt: string
  updatedAt: string
}

export interface CreatePlanRequest {
  name: string
  description: string
  credits: number
  price: number
  clinicId?: string
}

export interface UpdatePlanRequest extends Partial<CreatePlanRequest> {
  isActive?: boolean
}

export interface PlanListResponse {
  data: Plan[]
  total: number
  page: number
  limit: number
}