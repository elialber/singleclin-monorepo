export declare const formatDate: (date: Date | string) => string;
export declare const formatDateTime: (date: Date | string) => string;
export declare const formatTime: (date: Date | string) => string;
export declare const addDays: (date: Date, days: number) => Date;
export declare const isDateExpired: (date: Date | string) => boolean;
export declare const formatRelativeTime: (date: Date | string) => string;
export declare const formatCurrency: (value: number) => string;
export declare const isValidEmail: (email: string) => boolean;
export declare const isValidPhone: (phone: string) => boolean;
export declare const isValidCNPJ: (cnpj: string) => boolean;
export declare const isValidPassword: (password: string, minLength?: number) => boolean;
export declare const formatCNPJ: (cnpj: string) => string;
export declare const formatPhone: (phone: string) => string;
export interface ApiResponse<T = unknown> {
    success: boolean;
    data?: T;
    message?: string;
    error?: string;
}
export declare const createSuccessResponse: <T>(data: T, message?: string) => ApiResponse<T>;
export declare const createErrorResponse: (error: string, message?: string) => ApiResponse;
export declare const capitalize: (str: string) => string;
export declare const formatName: (firstName?: string, lastName?: string) => string;
export declare const generateId: () => string;
export declare const slugify: (text: string) => string;
export declare const groupBy: <T, K extends string | number>(array: T[], key: (item: T) => K) => Record<K, T[]>;
export declare const sortBy: <T>(array: T[], key: keyof T | ((item: T) => string | number | Date), order?: "asc" | "desc") => T[];
export declare const uniqBy: <T>(array: T[], key: keyof T) => T[];
export declare const formatNumber: (num: number, decimals?: number) => string;
export declare const clamp: (value: number, min: number, max: number) => number;
export declare const percentage: (value: number, total: number) => number;
export declare const storage: {
    get: <T>(key: string, defaultValue?: T) => T | null;
    set: (key: string, value: unknown) => void;
    remove: (key: string) => void;
    clear: () => void;
};
export declare const debounce: <T extends (...args: unknown[]) => void>(func: T, wait: number) => T;
//# sourceMappingURL=index.d.ts.map