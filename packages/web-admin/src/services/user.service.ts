import { api } from './api'
import { User } from '@/types/user'

export interface UserFilters {
  search?: string
  role?: string
  isActive?: boolean
  clinicId?: string
}

export interface UserQueryParams extends UserFilters {
  page?: number
  limit?: number
}

export interface UserListResponse {
  data: User[]
  total: number
  page: number
  limit: number
}

export interface CreateUserDto {
  email: string
  firstName: string
  lastName: string
  role: string
  phoneNumber?: string
  clinicId?: string
  password: string
}

export interface UpdateUserDto {
  firstName?: string
  lastName?: string
  phoneNumber?: string
  isActive?: boolean
  role?: string
  clinicId?: string
}

export const userService = {
  async getUsers(params: UserQueryParams = {}): Promise<UserListResponse> {
    const queryParams = new URLSearchParams()
    
    if (params.page) queryParams.append('page', params.page.toString())
    if (params.limit) queryParams.append('limit', params.limit.toString())
    if (params.search) queryParams.append('search', params.search)
    if (params.role) queryParams.append('role', params.role)
    if (params.isActive !== undefined) queryParams.append('isActive', params.isActive.toString())
    if (params.clinicId) queryParams.append('clinicId', params.clinicId)

    try {
      const response = await api.get<UserListResponse>(`/users?${queryParams.toString()}`)
      return response.data
    } catch (error: any) {
      if (error.response?.status === 404) {
        // Return mock data if endpoint not implemented yet
        console.warn('Users endpoint not implemented, returning mock data')
        
        const mockUsers: User[] = [
          {
            id: '1',
            email: 'admin@singleclin.com',
            firstName: 'Admin',
            lastName: 'Sistema',
            fullName: 'Admin Sistema',
            role: 'Administrator',
            isActive: true,
            isEmailVerified: true,
            createdAt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '2',
            email: 'clinica.origem@singleclin.com',
            firstName: 'Maria',
            lastName: 'Silva',
            fullName: 'Maria Silva',
            role: 'ClinicOrigin',
            isActive: true,
            isEmailVerified: true,
            phoneNumber: '(11) 98765-4321',
            clinicId: 'clinic-1',
            createdAt: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000).toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '3',
            email: 'clinica.parceira@singleclin.com',
            firstName: 'João',
            lastName: 'Santos',
            fullName: 'João Santos',
            role: 'ClinicPartner',
            isActive: true,
            isEmailVerified: true,
            phoneNumber: '(21) 97654-3210',
            clinicId: 'clinic-2',
            createdAt: new Date(Date.now() - 45 * 24 * 60 * 60 * 1000).toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '4',
            email: 'paciente1@email.com',
            firstName: 'Carlos',
            lastName: 'Oliveira',
            fullName: 'Carlos Oliveira',
            role: 'Patient',
            isActive: true,
            isEmailVerified: false,
            phoneNumber: '(31) 96543-2109',
            createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '5',
            email: 'paciente2@email.com',
            firstName: 'Ana',
            lastName: 'Costa',
            fullName: 'Ana Costa',
            role: 'Patient',
            isActive: false,
            isEmailVerified: true,
            phoneNumber: '(41) 95432-1098',
            createdAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '6',
            email: 'clinica.parceira2@singleclin.com',
            firstName: 'Pedro',
            lastName: 'Almeida',
            fullName: 'Pedro Almeida',
            role: 'ClinicPartner',
            isActive: true,
            isEmailVerified: true,
            phoneNumber: '(51) 94321-0987',
            clinicId: 'clinic-3',
            createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
            updatedAt: new Date().toISOString(),
          },
        ]

        // Apply filters
        let filtered = [...mockUsers]
        
        if (params.search) {
          const searchLower = params.search.toLowerCase()
          filtered = filtered.filter(u => 
            u.fullName.toLowerCase().includes(searchLower) ||
            u.email.toLowerCase().includes(searchLower) ||
            (u.phoneNumber && u.phoneNumber.includes(params.search!))
          )
        }
        
        if (params.role) {
          filtered = filtered.filter(u => u.role === params.role)
        }
        
        if (params.isActive !== undefined) {
          filtered = filtered.filter(u => u.isActive === params.isActive)
        }
        
        if (params.clinicId) {
          filtered = filtered.filter(u => u.clinicId === params.clinicId)
        }

        // Sort by creation date (newest first)
        filtered.sort((a, b) => 
          new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
        )

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

  async getUser(id: string): Promise<User> {
    try {
      const response = await api.get<{ data: User }>(`/users/${id}`)
      return response.data.data
    } catch (error: any) {
      if (error.response?.status === 404) {
        // Try to find in mock data
        const users = await this.getUsers({ limit: 100 })
        const user = users.data.find(u => u.id === id)
        if (user) return user
      }
      throw error
    }
  },

  async createUser(data: CreateUserDto): Promise<User> {
    try {
      const response = await api.post<{ data: User }>('/users', data)
      return response.data.data
    } catch (error: any) {
      if (error.response?.status === 404) {
        // Mock response for development
        console.warn('Create user endpoint not implemented, returning mock data')
        const newUser: User = {
          id: Date.now().toString(),
          email: data.email,
          firstName: data.firstName,
          lastName: data.lastName,
          fullName: `${data.firstName} ${data.lastName}`,
          role: data.role as any,
          phoneNumber: data.phoneNumber,
          clinicId: data.clinicId,
          isActive: true,
          isEmailVerified: false,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        }
        return newUser
      }
      throw error
    }
  },

  async updateUser(id: string, data: UpdateUserDto): Promise<User> {
    try {
      const response = await api.put<{ data: User }>(`/users/${id}`, data)
      return response.data.data
    } catch (error: any) {
      if (error.response?.status === 404) {
        // Mock response for development
        console.warn('Update user endpoint not implemented, returning mock data')
        const user = await this.getUser(id)
        return {
          ...user,
          ...data,
          fullName: data.firstName && data.lastName 
            ? `${data.firstName} ${data.lastName}`
            : user.fullName,
          updatedAt: new Date().toISOString(),
        }
      }
      throw error
    }
  },

  async deleteUser(id: string): Promise<void> {
    try {
      await api.delete(`/users/${id}`)
    } catch (error: any) {
      if (error.response?.status === 404) {
        console.warn('Delete user endpoint not implemented')
        return
      }
      throw error
    }
  },

  async toggleUserStatus(id: string, isActive: boolean): Promise<User> {
    return this.updateUser(id, { isActive })
  },

  async resetPassword(id: string): Promise<void> {
    try {
      await api.post(`/users/${id}/reset-password`)
    } catch (error: any) {
      if (error.response?.status === 404) {
        console.warn('Reset password endpoint not implemented')
        return
      }
      throw error
    }
  },
}