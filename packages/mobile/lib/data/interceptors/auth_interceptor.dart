import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;

import 'package:singleclin_mobile/core/constants/api_constants.dart';
import 'package:singleclin_mobile/core/services/session_manager.dart';
import 'package:singleclin_mobile/core/errors/api_exceptions.dart';

/// HTTP interceptor for automatic JWT token authentication.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    FirebaseAuth? firebaseAuth,
    SessionManager? sessionManager,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _sessionManager = sessionManager ?? Get.find<SessionManager>();

  final FirebaseAuth _firebaseAuth;
  final SessionManager _sessionManager;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final tokenService = _sessionManager.tokenRefreshService;
      final String? token = await tokenService?.getCurrentToken();

      if (token != null) {
        options.headers[ApiConstants.authorizationHeader] =
            '${ApiConstants.bearerTokenPrefix}$token';

        if (kDebugMode) {
          print('🔑 Auth token added to request: ${options.path}');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ No authenticated token available for ${options.path}');
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

    if (statusCode == ApiConstants.statusUnauthorized) {
      try {
        final Response? retryResponse =
            await _retryWithRefreshedToken(err.requestOptions);

        if (retryResponse != null) {
          handler.resolve(retryResponse);
          return;
        }

        await _sessionManager.endSession(
          signOut: true,
          redirectToLogin: true,
          message: 'Sua sessão expirou. Faça login novamente.',
        );
      } catch (retryError) {
        if (kDebugMode) {
          print('❌ Token refresh retry failed: $retryError');
        }
        await _sessionManager.endSession(
          signOut: true,
          redirectToLogin: true,
          message: 'Sua sessão expirou. Faça login novamente.',
        );
      }
    } else if (statusCode == ApiConstants.statusForbidden || statusCode == 409) {
      await _sessionManager.endSession(
        signOut: true,
        redirectToLogin: true,
        message: 'Seu acesso foi revogado. Faça login novamente.',
      );
    }

    final ApiException apiException = _mapDioExceptionToApiException(err);
    final DioException customException = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: apiException,
      message: apiException.message,
    );

    handler.next(customException);
  }

  Future<Response?> _retryWithRefreshedToken(RequestOptions failedRequest) async {
    try {
      final User? user = _firebaseAuth.currentUser;

      if (user == null) {
        if (kDebugMode) {
          print('❌ No authenticated user for token refresh');
        }
        return null;
      }

      final tokenService = _sessionManager.tokenRefreshService;
      final String? newToken = await tokenService?.refreshToken();

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

  String _getErrorMessageFromResponse(Response? response) {
    if (response?.data != null) {
      final dynamic data = response!.data;

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
}
