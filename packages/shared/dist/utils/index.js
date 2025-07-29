"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.debounce = exports.storage = exports.percentage = exports.clamp = exports.formatNumber = exports.uniqBy = exports.sortBy = exports.groupBy = exports.slugify = exports.generateId = exports.formatName = exports.capitalize = exports.createErrorResponse = exports.createSuccessResponse = exports.formatPhone = exports.formatCNPJ = exports.isValidPassword = exports.isValidCNPJ = exports.isValidPhone = exports.isValidEmail = exports.formatCurrency = exports.formatRelativeTime = exports.isDateExpired = exports.addDays = exports.formatTime = exports.formatDateTime = exports.formatDate = void 0;
const formatDate = (date) => {
    const dateObj = typeof date === 'string' ? new Date(date) : date;
    return dateObj.toLocaleDateString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
    });
};
exports.formatDate = formatDate;
const formatDateTime = (date) => {
    const dateObj = typeof date === 'string' ? new Date(date) : date;
    return dateObj.toLocaleString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
    });
};
exports.formatDateTime = formatDateTime;
const formatTime = (date) => {
    const dateObj = typeof date === 'string' ? new Date(date) : date;
    return dateObj.toLocaleTimeString('pt-BR', {
        hour: '2-digit',
        minute: '2-digit',
    });
};
exports.formatTime = formatTime;
const addDays = (date, days) => {
    const result = new Date(date);
    result.setDate(result.getDate() + days);
    return result;
};
exports.addDays = addDays;
const isDateExpired = (date) => {
    const dateObj = typeof date === 'string' ? new Date(date) : date;
    return dateObj < new Date();
};
exports.isDateExpired = isDateExpired;
const formatRelativeTime = (date) => {
    const dateObj = typeof date === 'string' ? new Date(date) : date;
    const now = new Date();
    const diffInMs = now.getTime() - dateObj.getTime();
    const diffInMinutes = Math.floor(diffInMs / (1000 * 60));
    const diffInHours = Math.floor(diffInMs / (1000 * 60 * 60));
    const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24));
    if (diffInMinutes < 1)
        return 'agora mesmo';
    if (diffInMinutes < 60)
        return `${diffInMinutes}m atrás`;
    if (diffInHours < 24)
        return `${diffInHours}h atrás`;
    if (diffInDays < 7)
        return `${diffInDays}d atrás`;
    return (0, exports.formatDate)(dateObj);
};
exports.formatRelativeTime = formatRelativeTime;
const formatCurrency = (value) => {
    return new Intl.NumberFormat('pt-BR', {
        style: 'currency',
        currency: 'BRL',
    }).format(value);
};
exports.formatCurrency = formatCurrency;
const isValidEmail = (email) => {
    const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return regex.test(email);
};
exports.isValidEmail = isValidEmail;
const isValidPhone = (phone) => {
    const regex = /^\+?[\d\s\-()]+$/;
    return regex.test(phone);
};
exports.isValidPhone = isValidPhone;
const isValidCNPJ = (cnpj) => {
    const cleanCNPJ = cnpj.replace(/[^\d]/g, '');
    if (cleanCNPJ.length !== 14)
        return false;
    let sum = 0;
    let pos = 5;
    for (let i = 0; i < 12; i++) {
        sum += parseInt(cleanCNPJ.charAt(i)) * pos--;
        if (pos < 2)
            pos = 9;
    }
    let result = sum % 11 < 2 ? 0 : 11 - (sum % 11);
    if (result !== parseInt(cleanCNPJ.charAt(12)))
        return false;
    sum = 0;
    pos = 6;
    for (let i = 0; i < 13; i++) {
        sum += parseInt(cleanCNPJ.charAt(i)) * pos--;
        if (pos < 2)
            pos = 9;
    }
    result = sum % 11 < 2 ? 0 : 11 - (sum % 11);
    return result === parseInt(cleanCNPJ.charAt(13));
};
exports.isValidCNPJ = isValidCNPJ;
const isValidPassword = (password, minLength = 8) => {
    return password.length >= minLength;
};
exports.isValidPassword = isValidPassword;
const formatCNPJ = (cnpj) => {
    const cleanCNPJ = cnpj.replace(/[^\d]/g, '');
    return cleanCNPJ.replace(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '$1.$2.$3/$4-$5');
};
exports.formatCNPJ = formatCNPJ;
const formatPhone = (phone) => {
    const cleanPhone = phone.replace(/[^\d]/g, '');
    if (cleanPhone.length === 11) {
        return cleanPhone.replace(/(\d{2})(\d{5})(\d{4})/, '($1) $2-$3');
    }
    if (cleanPhone.length === 10) {
        return cleanPhone.replace(/(\d{2})(\d{4})(\d{4})/, '($1) $2-$3');
    }
    return phone;
};
exports.formatPhone = formatPhone;
const createSuccessResponse = (data, message) => {
    const response = {
        success: true,
        data,
    };
    if (message) {
        response.message = message;
    }
    return response;
};
exports.createSuccessResponse = createSuccessResponse;
const createErrorResponse = (error, message) => {
    const response = {
        success: false,
        error,
    };
    if (message) {
        response.message = message;
    }
    return response;
};
exports.createErrorResponse = createErrorResponse;
const capitalize = (str) => {
    return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
};
exports.capitalize = capitalize;
const formatName = (firstName, lastName) => {
    const parts = [firstName, lastName].filter(Boolean);
    return parts.map(exports.capitalize).join(' ');
};
exports.formatName = formatName;
const generateId = () => {
    return Math.random().toString(36).substring(2) + Date.now().toString(36);
};
exports.generateId = generateId;
const slugify = (text) => {
    return text
        .toLowerCase()
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .replace(/[^a-z0-9 -]/g, '')
        .replace(/\s+/g, '-')
        .replace(/-+/g, '-')
        .trim();
};
exports.slugify = slugify;
const groupBy = (array, key) => {
    return array.reduce((groups, item) => {
        const groupKey = key(item);
        if (!groups[groupKey]) {
            groups[groupKey] = [];
        }
        groups[groupKey].push(item);
        return groups;
    }, {});
};
exports.groupBy = groupBy;
const sortBy = (array, key, order = 'asc') => {
    const getter = typeof key === 'function'
        ? key
        : (item) => item[key];
    return [...array].sort((a, b) => {
        const aVal = getter(a);
        const bVal = getter(b);
        if (aVal < bVal)
            return order === 'asc' ? -1 : 1;
        if (aVal > bVal)
            return order === 'asc' ? 1 : -1;
        return 0;
    });
};
exports.sortBy = sortBy;
const uniqBy = (array, key) => {
    const seen = new Set();
    return array.filter(item => {
        const value = item[key];
        if (seen.has(value)) {
            return false;
        }
        seen.add(value);
        return true;
    });
};
exports.uniqBy = uniqBy;
const formatNumber = (num, decimals = 0) => {
    return new Intl.NumberFormat('pt-BR', {
        minimumFractionDigits: decimals,
        maximumFractionDigits: decimals,
    }).format(num);
};
exports.formatNumber = formatNumber;
const clamp = (value, min, max) => {
    return Math.min(Math.max(value, min), max);
};
exports.clamp = clamp;
const percentage = (value, total) => {
    return total === 0 ? 0 : (value / total) * 100;
};
exports.percentage = percentage;
exports.storage = {
    get: (key, defaultValue) => {
        try {
            const item = localStorage.getItem(key);
            return item ? JSON.parse(item) : defaultValue || null;
        }
        catch {
            return defaultValue || null;
        }
    },
    set: (key, value) => {
        try {
            localStorage.setItem(key, JSON.stringify(value));
        }
        catch {
        }
    },
    remove: (key) => {
        try {
            localStorage.removeItem(key);
        }
        catch {
        }
    },
    clear: () => {
        try {
            localStorage.clear();
        }
        catch {
        }
    },
};
const debounce = (func, wait) => {
    let timeout;
    return ((...args) => {
        clearTimeout(timeout);
        timeout = setTimeout(() => func(...args), wait);
    });
};
exports.debounce = debounce;
//# sourceMappingURL=index.js.map