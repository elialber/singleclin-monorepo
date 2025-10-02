import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:singleclin_mobile/core/errors/api_exceptions.dart';
import 'package:singleclin_mobile/data/services/auth_service.dart';
import 'package:singleclin_mobile/data/services/token_refresh_service.dart';
import 'package:singleclin_mobile/core/constants/api_constants.dart';
import 'package:singleclin_mobile/core/constants/app_constants.dart';
import 'package:singleclin_mobile/core/services/storage_service.dart';

/// HTTP interceptor for automatic JWT token authentication
///
/// This interceptor automatically adds the Firebase Auth ID token
/// to all HTTP requests and handles token refresh when expired.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    FirebaseAuth? firebaseAuth,
    TokenRefreshService? tokenRefreshService,
    AuthService? authService,
    StorageService? storageService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _tokenRefreshService = tokenRefreshService ?? Get.find<TokenRefreshService>(),
        _authService = authService ?? Get.find<AuthService>(),
        _storageService = storageService ?? Get.find<StorageService>();

  final FirebaseAuth _firebaseAuth;
  final TokenRefreshService _tokenRefreshService;
  final AuthService _authService;
  final StorageService _storageService;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final String? token = await _tokenRefreshService.getCurrentToken();

      if (token != null) {
        options.headers[ApiConstants.authorizationHeader] =
            '${ApiConstants.bearerTokenPrefix}$token';

        if (kDebugMode) {
          print('🔑 Auth token added to request: ${options.path}');
        }
      } else {
        if (kDebugMode) {
          print(
            '⚠️ No authenticated token available - request sent without token: ${options.path}',
          );
        }
      }

      handler.next(options);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding auth token: $e');
      }

      handler.next(options);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;

    if (statusCode == 401) {
      try {
        if (kDebugMode) {
          print('🔄 401 Unauthorized - attempting token refresh and retry');
        }

        final Response? retryResponse =
            await _retryWithRefreshedToken(err.requestOptions);

        if (retryResponse != null) {
          handler.resolve(retryResponse);
          return;
        }

        await _handleAuthenticationFailure(
          reason: 'Sua sessão expirou. Faça login novamente.',
        );
      } catch (retryError) {
        if (kDebugMode) {
          print('❌ Token refresh failed: $retryError');
        }
        await _handleAuthenticationFailure(
          reason: 'Sua sessão expirou. Faça login novamente.',
        );
      }
    } else if (statusCode == 403 || statusCode == 409) {
      await _handleAuthenticationFailure(
        reason: 'Seu acesso foi revogado. Faça login novamente.',
      );
    }

    // Convert DioException to custom API exception
    final ApiException apiException = _mapDioExceptionToApiException(err);

    // Create new DioException with custom exception
    final DioException customException = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: apiException,
      message: apiException.message,
    );

    handler.next(customException);
  }

  /// Retry the failed request with a refreshed token
  Future<Response?> _retryWithRefreshedToken(RequestOptions failedRequest) async {
    try {
      final User? user = _firebaseAuth.currentUser;

      if (user == null) {
        if (kDebugMode) {
          print('❌ No authenticated user for token refresh');
        }
        return null;
      }

      final String? newToken = await _tokenRefreshService.refreshToken();

      if (newToken == null) {
        if (kDebugMode) {
          print('❌ Failed to refresh token - token is null');
        }
        return null;
      }

      if (kDebugMode) {
        print('✅ Token refreshed successfully');
      }

      final RequestOptions retryOptions = failedRequest.copyWith();
      retryOptions.headers[ApiConstants.authorizationHeader] =
          '${ApiConstants.bearerTokenPrefix}$newToken';

      final Dio retryDio = Dio()
        ..options = BaseOptions(
          baseUrl: failedRequest.baseUrl,
          connectTimeout: failedRequest.connectTimeout,
          sendTimeout: failedRequest.sendTimeout,
          receiveTimeout: failedRequest.receiveTimeout,
        );

      final Response response = await retryDio.fetch(retryOptions);

      if (kDebugMode) {
        print('✅ Request retry successful: ${failedRequest.path}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Request retry failed: $e');
      }
      return null;
    }
  }

  /// Map DioException to custom ApiException
  ApiException _mapDioExceptionToApiException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiTimeoutException(
          'Request timed out. Please check your internet connection.',
          'timeout',
        );

      case DioExceptionType.badResponse:
        final int statusCode = err.response?.statusCode ?? 0;
        final String message = _getErrorMessageFromResponse(err.response);

        switch (statusCode) {
          case 400:
            return ApiBadRequestException(message, 'bad_request');
          case 401:
            return ApiUnauthorizedException(message, 'unauthorized');
          case 403:
            return ApiForbiddenException(message, 'forbidden');
          case 404:
            return ApiNotFoundException(message, 'not_found');
          case 422:
            return ApiValidationException(message, 'validation_error');
          case 429:
            return ApiTooManyRequestsException(message, 'too_many_requests');
          case 500:
            return ApiServerException(message, 'server_error');
          default:
            return ApiServerException(message, 'http_error_$statusCode');
        }

      case DioExceptionType.cancel:
        return const ApiConnectionException(
          'Request was cancelled',
          'request_cancelled',
        );

      case DioExceptionType.connectionError:
        return const ApiConnectionException(
          'Connection error. Please check your internet connection.',
          'connection_error',
        );

      case DioExceptionType.badCertificate:
        return const ApiConnectionException(
          'SSL certificate error',
          'ssl_error',
        );

      case DioExceptionType.unknown:
        return ApiConnectionException(
          err.message ?? 'An unknown error occurred',
          'unknown_error',
        );
    }
  }

  /// Extract error message from response
  String _getErrorMessageFromResponse(Response? response) {
    if (response?.data != null) {
      final dynamic data = response!.data;

      // Try to extract message from common response formats
      if (data is Map<String, dynamic>) {
        return data['message'] ??
            data['error'] ??
            data['detail'] ??
            'Request failed with status ${response.statusCode}';
      } else if (data is String) {
        return data;
      }
    }

    return 'Request failed with status ${response?.statusCode ?? 'unknown'}';
  }

  /// Handle authentication failure by signing out and redirecting to login
  Future<void> _handleAuthenticationFailure({String? reason}) async {
    try {
      if (kDebugMode) {
        print('🚨 Handling authentication failure - signing out user');
      }

      _tokenRefreshService.dispose();
      await _authService.signOut();
      await _storageService.remove(AppConstants.tokenKey);
      await _tokenRefreshService.initialize();

      if (Get.currentRoute != '/login' && Get.currentRoute != '/splash') {
        await Get.offAllNamed('/login');

        Get.snackbar(
          'Sessão Expirada',
          reason ?? 'Sua sessão expirou. Faça login novamente.',
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
          icon: const Icon(Icons.info_outline),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling authentication failure: $e');
      }
    }
  }
}
