export declare const API_CONFIG: {
    readonly BASE_URL: string;
    readonly TIMEOUT: 30000;
    readonly RETRY_ATTEMPTS: 3;
    readonly DEFAULT_PAGE_SIZE: 20;
    readonly MAX_PAGE_SIZE: 100;
};
export declare const QR_CODE_CONFIG: {
    readonly EXPIRY_MINUTES: 5;
    readonly SIZE: 256;
    readonly MARGIN: 2;
    readonly ERROR_CORRECTION_LEVEL: "M";
    readonly COLOR_DARK: "#000000";
    readonly COLOR_LIGHT: "#FFFFFF";
};
export declare const AUTH_CONFIG: {
    readonly TOKEN_KEY: "singleclin_token";
    readonly REFRESH_TOKEN_KEY: "singleclin_refresh_token";
    readonly USER_KEY: "singleclin_user";
    readonly TOKEN_EXPIRY_BUFFER_MINUTES: 5;
    readonly SESSION_TIMEOUT_MINUTES: 60;
};
export declare const VALIDATION_RULES: {
    readonly EMAIL_REGEX: RegExp;
    readonly PHONE_REGEX: RegExp;
    readonly CNPJ_REGEX: RegExp;
    readonly MIN_PASSWORD_LENGTH: 8;
    readonly MAX_NAME_LENGTH: 100;
    readonly MAX_DESCRIPTION_LENGTH: 500;
    readonly MIN_CREDITS: 1;
    readonly MAX_CREDITS: 9999;
    readonly MIN_PRICE: 0.01;
    readonly MAX_PRICE: 99999.99;
};
export declare const ERROR_MESSAGES: {
    readonly NETWORK_ERROR: "Erro de conexão. Tente novamente.";
    readonly INVALID_CREDENTIALS: "Credenciais inválidas.";
    readonly INSUFFICIENT_CREDITS: "Créditos insuficientes.";
    readonly EXPIRED_QR_CODE: "QR Code expirado.";
    readonly INVALID_QR_CODE: "QR Code inválido.";
    readonly UNAUTHORIZED: "Acesso não autorizado.";
    readonly FORBIDDEN: "Você não tem permissão para esta ação.";
    readonly NOT_FOUND: "Recurso não encontrado.";
    readonly VALIDATION_ERROR: "Dados inválidos.";
    readonly SERVER_ERROR: "Erro interno do servidor.";
    readonly EXPIRED_SESSION: "Sessão expirada. Faça login novamente.";
    readonly PLAN_EXPIRED: "Seu plano expirou.";
    readonly USER_INACTIVE: "Usuário inativo.";
    readonly CLINIC_INACTIVE: "Clínica inativa.";
};
export declare const SUCCESS_MESSAGES: {
    readonly LOGIN_SUCCESS: "Login realizado com sucesso.";
    readonly LOGOUT_SUCCESS: "Logout realizado com sucesso.";
    readonly PLAN_CREATED: "Plano criado com sucesso.";
    readonly PLAN_UPDATED: "Plano atualizado com sucesso.";
    readonly PLAN_DELETED: "Plano removido com sucesso.";
    readonly USER_CREATED: "Usuário criado com sucesso.";
    readonly USER_UPDATED: "Usuário atualizado com sucesso.";
    readonly QR_CODE_GENERATED: "QR Code gerado com sucesso.";
    readonly TRANSACTION_SUCCESS: "Transação realizada com sucesso.";
    readonly NOTIFICATION_SENT: "Notificação enviada com sucesso.";
};
export declare const NOTIFICATION_CONFIG: {
    readonly LOW_CREDITS_THRESHOLD: 5;
    readonly PLAN_EXPIRY_WARNING_DAYS: 7;
    readonly MAX_PUSH_NOTIFICATIONS_PER_DAY: 10;
    readonly EMAIL_RETRY_ATTEMPTS: 3;
    readonly BATCH_SIZE: 100;
};
export declare const UI_CONFIG: {
    readonly DEBOUNCE_DELAY: 300;
    readonly LOADING_DELAY: 200;
    readonly TOAST_DURATION: 5000;
    readonly MODAL_ANIMATION_DURATION: 300;
    readonly REFRESH_INTERVAL: 30000;
};
export declare const FILE_CONFIG: {
    readonly MAX_FILE_SIZE: number;
    readonly ALLOWED_IMAGE_TYPES: readonly ["image/jpeg", "image/png", "image/gif", "image/webp"];
    readonly ALLOWED_DOCUMENT_TYPES: readonly ["application/pdf", "text/plain"];
};
export declare const PAGINATION_CONFIG: {
    readonly DEFAULT_PAGE: 1;
    readonly DEFAULT_LIMIT: 20;
    readonly MAX_LIMIT: 100;
    readonly PAGE_SIZE_OPTIONS: readonly [10, 20, 50, 100];
};
export declare const DATE_FORMATS: {
    readonly DATE_ONLY: "dd/MM/yyyy";
    readonly DATE_TIME: "dd/MM/yyyy HH:mm";
    readonly TIME_ONLY: "HH:mm";
    readonly ISO_DATE: "yyyy-MM-dd";
    readonly FULL_DATE: "EEEE, dd 'de' MMMM 'de' yyyy";
};
export declare const ROUTES: {
    readonly HOME: "/";
    readonly LOGIN: "/login";
    readonly REGISTER: "/register";
    readonly DASHBOARD: "/dashboard";
    readonly PROFILE: "/profile";
    readonly PLANS: "/plans";
    readonly TRANSACTIONS: "/transactions";
    readonly QR_CODE: "/qr-code";
    readonly SCANNER: "/scanner";
    readonly ADMIN: "/admin";
    readonly CLINICS: "/admin/clinics";
    readonly USERS: "/admin/users";
    readonly REPORTS: "/admin/reports";
};
//# sourceMappingURL=index.d.ts.map