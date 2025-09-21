import 'package:flutter/foundation.dart';

/// API configuration constants
class ApiConstants {
  // Private constructor to prevent instantiation
  ApiConstants._();

  /// App version for User-Agent header
  static const String appVersion = '1.0.0';

  /// Base API URL - Update this based on your environment
  static String get baseUrl => _getBaseUrl();

  /// API endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String profileEndpoint = '/auth/profile';
  static const String updateProfileEndpoint = '/auth/profile';
  static const String changePasswordEndpoint = '/auth/change-password';
  static const String deleteAccountEndpoint = '/auth/delete-account';

  /// Plans endpoints
  static const String plansEndpoint = '/plans';
  static const String planByIdEndpoint = '/plans';

  /// User endpoints
  static const String usersEndpoint = '/users';
  static const String userByIdEndpoint = '/users';

  /// Credit endpoints
  static const String creditsEndpoint = '/credits';
  static const String creditHistoryEndpoint = '/credits/history';
  static const String purchaseCreditsEndpoint = '/credits/purchase';

  /// QR Code endpoints
  static const String generateQrEndpoint = '/qr/generate';
  static const String validateQrEndpoint = '/qr/validate';
  static const String qrHistoryEndpoint = '/qr/history';

  /// Transaction endpoints
  static const String transactionsEndpoint = '/transactions';
  static const String transactionByIdEndpoint = '/transactions';

  /// Clinic endpoints
  static const String clinicsEndpoint = '/clinics';
  static const String clinicByIdEndpoint = '/clinics';
  static const String clinicStatsEndpoint = '/clinics/stats';

  /// Get base URL based on environment
  static String _getBaseUrl() {
    // Always use production API for all environments
    return 'https://api.singleclin.com.br/api';
  }

  /// API timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  /// HTTP status codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusNoContent = 204;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusUnprocessableEntity = 422;
  static const int statusTooManyRequests = 429;
  static const int statusInternalServerError = 500;

  /// API response keys
  static const String dataKey = 'data';
  static const String messageKey = 'message';
  static const String errorsKey = 'errors';
  static const String metaKey = 'meta';
  static const String linksKey = 'links';

  /// Pagination constants
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const String pageKey = 'page';
  static const String limitKey = 'limit';
  static const String totalKey = 'total';
  static const String currentPageKey = 'current_page';
  static const String lastPageKey = 'last_page';
  static const String perPageKey = 'per_page';

  /// Content types
  static const String jsonContentType = 'application/json';
  static const String formContentType = 'application/x-www-form-urlencoded';
  static const String multipartContentType = 'multipart/form-data';

  /// Header keys
  static const String authorizationHeader = 'Authorization';
  static const String bearerTokenPrefix = 'Bearer ';
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';
  static const String userAgentHeader = 'User-Agent';

  /// Cache settings
  static const Duration cacheMaxAge = Duration(minutes: 5);
  static const String cacheControlHeader = 'Cache-Control';
  static const String ifNoneMatchHeader = 'If-None-Match';
  static const String etagHeader = 'ETag';

  /// File upload settings
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx'];

  /// Retry settings
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  static const Duration exponentialBackoffBase = Duration(seconds: 2);
}
