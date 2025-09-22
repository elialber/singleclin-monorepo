export interface IUser {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  firebaseUid: string;
  createdAt: Date;
  updatedAt: Date;
  isActive: boolean;
  clinicId?: string;
}

export interface IClinic {
  id: string;
  name: string;
  address: string;
  phone: string;
  email: string;
  isOrigin: boolean;
  isPartner: boolean;
  createdAt: Date;
  updatedAt: Date;
  isActive: boolean;
}

export interface IPlan {
  id: string;
  name: string;
  description: string;
  totalCredits: number;
  price: number;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
  validityPeriod: number; // in days
}

export interface IUserPlan {
  id: string;
  userId: string;
  planId: string;
  purchaseDate: Date;
  expirationDate: Date;
  remainingCredits: number;
  isActive: boolean;
  originClinicId: string;
}

export interface ITransaction {
  id: string;
  userPlanId: string;
  clinicId: string;
  creditsUsed: number;
  qrCodeToken: string;
  transactionDate: Date;
  description?: string;
  status: TransactionStatus;
}

export interface IQRCode {
  id: string;
  userId: string;
  userPlanId: string;
  token: string;
  nonce: string;
  expirationTime: Date;
  isUsed: boolean;
  createdAt: Date;
  clinicId?: string;
}

export enum UserRole {
  PATIENT = 'patient',
  CLINIC = 'clinic',
  ADMIN = 'admin'
}

export enum TransactionStatus {
  PENDING = 'pending',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled'
}

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message?: string;
  errors?: string[];
}

export interface PaginatedResponse<T> extends ApiResponse<T[]> {
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
  name: string;
  role?: UserRole;
}

export interface QRCodeRequest {
  userPlanId: string;
  clinicId?: string;
}

export interface TransactionRequest {
  qrCodeToken: string;
  creditsToUse: number;
  description?: string;
}

export interface IService {
  id: string;
  name: string;
  description: string;
  creditCost: number;
  duration: number; // in minutes
  isActive: boolean;
  clinicId: string;
  category: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface IAppointment {
  id: string;
  userId: string;
  serviceId: string;
  clinicId: string;
  scheduledDate: Date;
  status: AppointmentStatus;
  transactionId?: string;
  totalCredits: number;
  confirmationToken?: string;
  createdAt: Date;
  updatedAt: Date;
}

export enum AppointmentStatus {
  SCHEDULED = 'scheduled',
  CONFIRMED = 'confirmed',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled'
}

export interface AppointmentScheduleRequest {
  serviceId: string;
  clinicId: string;
  scheduledDate: Date;
}

export interface AppointmentConfirmationRequest {
  confirmationToken: string;
}

export interface AppointmentSummaryDto {
  id: string;
  service: IService;
  clinic: IClinic;
  scheduledDate: Date;
  totalCredits: number;
  confirmationToken: string;
  userCurrentCredits: number;
  userRemainingCredits: number;
}

export interface ServiceDto {
  id: string;
  name: string;
  description: string;
  creditCost: number;
  duration: number;
  category: string;
  clinic: IClinic;
}