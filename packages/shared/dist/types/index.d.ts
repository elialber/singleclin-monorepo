export interface IUser {
    id: string;
    email: string;
    role: UserRole;
    firstName?: string;
    lastName?: string;
    phone?: string;
    isActive: boolean;
    clinicId?: string;
    createdAt: Date;
    updatedAt: Date;
}
export interface IClinic {
    id: string;
    name: string;
    type: ClinicType;
    email: string;
    phone: string;
    address: string;
    city: string;
    state: string;
    zipCode: string;
    cnpj?: string;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
}
export interface IPlan {
    id: string;
    name: string;
    description: string;
    credits: number;
    price: number;
    durationDays: number;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
}
export interface IUserPlan {
    id: string;
    userId: string;
    planId: string;
    creditsRemaining: number;
    purchaseDate: Date;
    expiryDate: Date;
    status: UserPlanStatus;
    createdAt: Date;
    updatedAt: Date;
}
export interface ITransaction {
    id: string;
    userId: string;
    clinicId: string;
    planId: string;
    userPlanId: string;
    creditsUsed: number;
    serviceName: string;
    status: TransactionStatus;
    qrCodeToken?: string;
    createdAt: Date;
    updatedAt: Date;
}
export interface IQRCode {
    id: string;
    userId: string;
    token: string;
    nonce: string;
    expiresAt: Date;
    isUsed: boolean;
    createdAt: Date;
}
export interface INotification {
    id: string;
    userId: string;
    type: NotificationType;
    title: string;
    message: string;
    isRead: boolean;
    data?: Record<string, unknown>;
    createdAt: Date;
}
export declare enum UserRole {
    PATIENT = "patient",
    CLINIC = "clinic",
    ADMIN = "admin"
}
export declare enum ClinicType {
    ORIGIN = "origin",
    PARTNER = "partner"
}
export declare enum TransactionStatus {
    PENDING = "pending",
    COMPLETED = "completed",
    FAILED = "failed",
    CANCELLED = "cancelled"
}
export declare enum UserPlanStatus {
    ACTIVE = "active",
    EXPIRED = "expired",
    CANCELLED = "cancelled",
    SUSPENDED = "suspended"
}
export declare enum NotificationType {
    LOW_CREDITS = "low_credits",
    PLAN_EXPIRED = "plan_expired",
    TRANSACTION_SUCCESS = "transaction_success",
    TRANSACTION_FAILED = "transaction_failed",
    SYSTEM_MAINTENANCE = "system_maintenance"
}
export interface LoginRequest {
    email: string;
    password: string;
}
export interface LoginResponse {
    user: IUser;
    token: string;
    expiresIn: number;
}
export interface CreateUserRequest {
    email: string;
    password: string;
    firstName?: string;
    lastName?: string;
    phone?: string;
    role: UserRole;
    clinicId?: string;
}
export interface UpdateUserRequest {
    firstName?: string;
    lastName?: string;
    phone?: string;
    isActive?: boolean;
}
export interface CreatePlanRequest {
    name: string;
    description: string;
    credits: number;
    price: number;
    durationDays: number;
}
export interface UpdatePlanRequest {
    name?: string;
    description?: string;
    credits?: number;
    price?: number;
    durationDays?: number;
    isActive?: boolean;
}
export interface ValidateQRCodeRequest {
    qrToken: string;
    serviceName: string;
    creditsToUse: number;
}
export interface ValidateQRCodeResponse {
    success: boolean;
    transaction?: ITransaction;
    userPlan?: IUserPlan;
    message: string;
}
export interface PaginatedResponse<T> {
    data: T[];
    total: number;
    page: number;
    limit: number;
    totalPages: number;
}
export interface QueryParams {
    page?: number;
    limit?: number;
    search?: string;
    sortBy?: string;
    sortOrder?: 'asc' | 'desc';
    filters?: Record<string, unknown>;
}
//# sourceMappingURL=index.d.ts.map