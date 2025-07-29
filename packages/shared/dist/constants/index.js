"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ROUTES = exports.DATE_FORMATS = exports.PAGINATION_CONFIG = exports.FILE_CONFIG = exports.UI_CONFIG = exports.NOTIFICATION_CONFIG = exports.SUCCESS_MESSAGES = exports.ERROR_MESSAGES = exports.VALIDATION_RULES = exports.AUTH_CONFIG = exports.QR_CODE_CONFIG = exports.API_CONFIG = void 0;
exports.API_CONFIG = {
    BASE_URL: (typeof process !== 'undefined' && process.env?.REACT_APP_API_URL) ||
        'http://localhost:5000',
    TIMEOUT: 30000,
    RETRY_ATTEMPTS: 3,
    DEFAULT_PAGE_SIZE: 20,
    MAX_PAGE_SIZE: 100,
};
exports.QR_CODE_CONFIG = {
    EXPIRY_MINUTES: 5,
    SIZE: 256,
    MARGIN: 2,
    ERROR_CORRECTION_LEVEL: 'M',
    COLOR_DARK: '#000000',
    COLOR_LIGHT: '#FFFFFF',
};
exports.AUTH_CONFIG = {
    TOKEN_KEY: 'singleclin_token',
    REFRESH_TOKEN_KEY: 'singleclin_refresh_token',
    USER_KEY: 'singleclin_user',
    TOKEN_EXPIRY_BUFFER_MINUTES: 5,
    SESSION_TIMEOUT_MINUTES: 60,
};
exports.VALIDATION_RULES = {
    EMAIL_REGEX: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
    PHONE_REGEX: /^\+?[\d\s\-()]+$/,
    CNPJ_REGEX: /^\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}$/,
    MIN_PASSWORD_LENGTH: 8,
    MAX_NAME_LENGTH: 100,
    MAX_DESCRIPTION_LENGTH: 500,
    MIN_CREDITS: 1,
    MAX_CREDITS: 9999,
    MIN_PRICE: 0.01,
    MAX_PRICE: 99999.99,
};
exports.ERROR_MESSAGES = {
    NETWORK_ERROR: 'Erro de conexão. Tente novamente.',
    INVALID_CREDENTIALS: 'Credenciais inválidas.',
    INSUFFICIENT_CREDITS: 'Créditos insuficientes.',
    EXPIRED_QR_CODE: 'QR Code expirado.',
    INVALID_QR_CODE: 'QR Code inválido.',
    UNAUTHORIZED: 'Acesso não autorizado.',
    FORBIDDEN: 'Você não tem permissão para esta ação.',
    NOT_FOUND: 'Recurso não encontrado.',
    VALIDATION_ERROR: 'Dados inválidos.',
    SERVER_ERROR: 'Erro interno do servidor.',
    EXPIRED_SESSION: 'Sessão expirada. Faça login novamente.',
    PLAN_EXPIRED: 'Seu plano expirou.',
    USER_INACTIVE: 'Usuário inativo.',
    CLINIC_INACTIVE: 'Clínica inativa.',
};
exports.SUCCESS_MESSAGES = {
    LOGIN_SUCCESS: 'Login realizado com sucesso.',
    LOGOUT_SUCCESS: 'Logout realizado com sucesso.',
    PLAN_CREATED: 'Plano criado com sucesso.',
    PLAN_UPDATED: 'Plano atualizado com sucesso.',
    PLAN_DELETED: 'Plano removido com sucesso.',
    USER_CREATED: 'Usuário criado com sucesso.',
    USER_UPDATED: 'Usuário atualizado com sucesso.',
    QR_CODE_GENERATED: 'QR Code gerado com sucesso.',
    TRANSACTION_SUCCESS: 'Transação realizada com sucesso.',
    NOTIFICATION_SENT: 'Notificação enviada com sucesso.',
};
exports.NOTIFICATION_CONFIG = {
    LOW_CREDITS_THRESHOLD: 5,
    PLAN_EXPIRY_WARNING_DAYS: 7,
    MAX_PUSH_NOTIFICATIONS_PER_DAY: 10,
    EMAIL_RETRY_ATTEMPTS: 3,
    BATCH_SIZE: 100,
};
exports.UI_CONFIG = {
    DEBOUNCE_DELAY: 300,
    LOADING_DELAY: 200,
    TOAST_DURATION: 5000,
    MODAL_ANIMATION_DURATION: 300,
    REFRESH_INTERVAL: 30000,
};
exports.FILE_CONFIG = {
    MAX_FILE_SIZE: 5 * 1024 * 1024,
    ALLOWED_IMAGE_TYPES: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
    ALLOWED_DOCUMENT_TYPES: ['application/pdf', 'text/plain'],
};
exports.PAGINATION_CONFIG = {
    DEFAULT_PAGE: 1,
    DEFAULT_LIMIT: 20,
    MAX_LIMIT: 100,
    PAGE_SIZE_OPTIONS: [10, 20, 50, 100],
};
exports.DATE_FORMATS = {
    DATE_ONLY: 'dd/MM/yyyy',
    DATE_TIME: 'dd/MM/yyyy HH:mm',
    TIME_ONLY: 'HH:mm',
    ISO_DATE: 'yyyy-MM-dd',
    FULL_DATE: "EEEE, dd 'de' MMMM 'de' yyyy",
};
exports.ROUTES = {
    HOME: '/',
    LOGIN: '/login',
    REGISTER: '/register',
    DASHBOARD: '/dashboard',
    PROFILE: '/profile',
    PLANS: '/plans',
    TRANSACTIONS: '/transactions',
    QR_CODE: '/qr-code',
    SCANNER: '/scanner',
    ADMIN: '/admin',
    CLINICS: '/admin/clinics',
    USERS: '/admin/users',
    REPORTS: '/admin/reports',
};
//# sourceMappingURL=index.js.map