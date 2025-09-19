export const API_ENDPOINTS = {
  AUTH: {
    LOGIN: '/api/auth/login',
    REGISTER: '/api/auth/register',
    REFRESH: '/api/auth/refresh',
    LOGOUT: '/api/auth/logout',
    FIREBASE_LOGIN: '/api/auth/firebase'
  },
  USERS: {
    BASE: '/api/users',
    PROFILE: '/api/users/profile',
    BY_ID: (id: string) => `/api/users/${id}`
  },
  CLINICS: {
    BASE: '/api/clinics',
    BY_ID: (id: string) => `/api/clinics/${id}`,
    PARTNERS: '/api/clinics/partners'
  },
  PLANS: {
    BASE: '/api/plans',
    BY_ID: (id: string) => `/api/plans/${id}`,
    ACTIVE: '/api/plans/active'
  },
  USER_PLANS: {
    BASE: '/api/user-plans',
    BY_ID: (id: string) => `/api/user-plans/${id}`,
    BY_USER: (userId: string) => `/api/user-plans/user/${userId}`,
    PURCHASE: '/api/user-plans/purchase'
  },
  QR_CODES: {
    BASE: '/api/qr-codes',
    GENERATE: '/api/qr-codes/generate',
    VALIDATE: '/api/qr-codes/validate'
  },
  TRANSACTIONS: {
    BASE: '/api/transactions',
    BY_ID: (id: string) => `/api/transactions/${id}`,
    BY_USER: (userId: string) => `/api/transactions/user/${userId}`,
    BY_CLINIC: (clinicId: string) => `/api/transactions/clinic/${clinicId}`,
    PROCESS: '/api/transactions/process'
  }
} as const;

export const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  NO_CONTENT: 204,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  UNPROCESSABLE_ENTITY: 422,
  INTERNAL_SERVER_ERROR: 500
} as const;

export const STORAGE_KEYS = {
  ACCESS_TOKEN: 'singleclin_access_token',
  REFRESH_TOKEN: 'singleclin_refresh_token',
  USER_DATA: 'singleclin_user_data',
  THEME: 'singleclin_theme',
  LANGUAGE: 'singleclin_language'
} as const;

export const QR_CODE_CONFIG = {
  EXPIRATION_MINUTES: 30,
  TOKEN_LENGTH: 32,
  NONCE_LENGTH: 16,
  MAX_SCAN_ATTEMPTS: 3
} as const;

export const PAGINATION = {
  DEFAULT_PAGE: 1,
  DEFAULT_LIMIT: 10,
  MAX_LIMIT: 100
} as const;

export const VALIDATION = {
  PASSWORD_MIN_LENGTH: 8,
  NAME_MIN_LENGTH: 2,
  NAME_MAX_LENGTH: 100,
  EMAIL_MAX_LENGTH: 255,
  DESCRIPTION_MAX_LENGTH: 500
} as const;

export const USER_ROLES = {
  PATIENT: 'patient',
  CLINIC: 'clinic',
  ADMIN: 'admin'
} as const;

export const TRANSACTION_STATUSES = {
  PENDING: 'pending',
  COMPLETED: 'completed',
  FAILED: 'failed',
  CANCELLED: 'cancelled'
} as const;

export const ERROR_MESSAGES = {
  INVALID_CREDENTIALS: 'Invalid email or password',
  USER_NOT_FOUND: 'User not found',
  EMAIL_ALREADY_EXISTS: 'Email already exists',
  INSUFFICIENT_CREDITS: 'Insufficient credits',
  INVALID_QR_CODE: 'Invalid or expired QR code',
  QR_CODE_ALREADY_USED: 'QR code has already been used',
  PLAN_NOT_FOUND: 'Plan not found',
  CLINIC_NOT_FOUND: 'Clinic not found',
  TRANSACTION_FAILED: 'Transaction failed to process',
  UNAUTHORIZED_ACCESS: 'Unauthorized access',
  SERVER_ERROR: 'Internal server error'
} as const;

export const SUCCESS_MESSAGES = {
  USER_CREATED: 'User created successfully',
  LOGIN_SUCCESS: 'Login successful',
  LOGOUT_SUCCESS: 'Logout successful',
  PLAN_PURCHASED: 'Plan purchased successfully',
  QR_CODE_GENERATED: 'QR code generated successfully',
  TRANSACTION_COMPLETED: 'Transaction completed successfully',
  PROFILE_UPDATED: 'Profile updated successfully'
} as const;

export const DATE_FORMATS = {
  ISO: 'YYYY-MM-DD',
  DISPLAY: 'DD/MM/YYYY',
  DATETIME: 'DD/MM/YYYY HH:mm',
  TIME: 'HH:mm'
} as const;

export const REGEX_PATTERNS = {
  EMAIL: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  PASSWORD: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$/,
  PHONE: /^\(\d{2}\)\s\d{4,5}-\d{4}$/,
  UUID: /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
} as const;