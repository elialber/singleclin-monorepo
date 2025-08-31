export interface Plan {
  id: string
  name: string
  description: string
  credits: number
  price: number
  originalPrice?: number
  validityDays: number
  isActive: boolean
  displayOrder: number
  isFeatured: boolean
  clinicId?: string
  clinicName?: string
  createdAt: string
  updatedAt: string
}

export interface CreatePlanRequest {
  name: string
  description?: string
  credits: number
  price: number
  originalPrice?: number
  validityDays?: number
  isActive?: boolean
  displayOrder?: number
  isFeatured?: boolean
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