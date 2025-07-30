import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/data/interceptors/auth_interceptor.dart';
import 'package:mobile/data/interceptors/logging_interceptor.dart';

/// HTTP client service using Dio with authentication and logging
///
/// This service provides a configured Dio instance with automatic
/// JWT authentication, request/response logging, and error handling.
class ApiClient {
  /// Private constructor for singleton pattern
  ApiClient._() {
    _dio = Dio();
    _setupInterceptors();
    _configureOptions();
  }
  static ApiClient? _instance;
  late final Dio _dio;

  /// Get singleton instance
  static ApiClient get instance {
    return _instance ??= ApiClient._();
  }

  /// Get the configured Dio instance
  Dio get dio => _dio;

  /// Setup interceptors in correct order
  void _setupInterceptors() {
    _dio.interceptors.clear();

    // 1. Logging interceptor (first to log everything)
    _dio.interceptors.add(LoggingInterceptor(logRequestBody: true));

    // 2. Auth interceptor (adds tokens and handles auth errors)
    _dio.interceptors.add(AuthInterceptor());
  }

  /// Configure Dio options
  void _configureOptions() {
    _dio.options = BaseOptions(
      // Base URL from constants
      baseUrl: ApiConstants.baseUrl,

      // Timeouts
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),

      // Headers
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'SingleClin-Mobile/${ApiConstants.appVersion}',
      },

      // Follow redirects
      followRedirects: true,
      maxRedirects: 3,

      // Validate status codes
      validateStatus: (status) {
        // Accept all status codes to handle them in interceptors
        return status != null && status >= 200 && status < 500;
      },
    );
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Upload file with progress tracking
  Future<Response<T>> uploadFile<T>(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    final FormData formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
      if (data != null) ...data,
    });

    return _dio.post<T>(
      path,
      data: formData,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }

  /// Download file with progress tracking
  Future<Response> downloadFile(
    String path,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.download(
      path,
      savePath,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Update base URL (useful for environment switching)
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
    if (kDebugMode) {
      print('🔄 API base URL updated to: $newBaseUrl');
    }
  }

  /// Update timeout settings
  void updateTimeouts({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) {
    if (connectTimeout != null) {
      _dio.options.connectTimeout = connectTimeout;
    }
    if (receiveTimeout != null) {
      _dio.options.receiveTimeout = receiveTimeout;
    }
    if (sendTimeout != null) {
      _dio.options.sendTimeout = sendTimeout;
    }

    if (kDebugMode) {
      print('🔄 API timeouts updated');
    }
  }

  /// Add custom header
  void addHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }

  /// Remove header
  void removeHeader(String key) {
    _dio.options.headers.remove(key);
  }

  /// Clear all custom headers (keeps default ones)
  void clearCustomHeaders() {
    _dio.options.headers.clear();
    _dio.options.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'SingleClin-Mobile/${ApiConstants.appVersion}',
    });
  }

  /// Dispose resources (if needed)
  void dispose() {
    _dio.close();
  }
}
