import { Plan } from './plan'

export interface UserPlan {
  id: string
  userId: string
  planId: string
  plan: Plan
  credits: number
  creditsRemaining: number
  creditsUsed: number
  amountPaid: number
  expirationDate: string
  isActive: boolean
  isExpired: boolean
  paymentMethod?: string
  paymentTransactionId?: string
  notes?: string
  createdAt: string
  updatedAt: string
}

export interface PurchasePlanRequest {
  planId: string
  paymentMethod?: string
  paymentTransactionId?: string
  notes?: string
}

export interface UserPlanResponse {
  success: boolean
  data: UserPlan | null
  message: string
  errors: string[]
}

export interface UserPlansResponse {
  success: boolean
  data: UserPlan[]
  message: string
  errors: string[]
}