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