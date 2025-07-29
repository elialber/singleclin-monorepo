import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/errors/api_exceptions.dart';

/// HTTP interceptor for automatic JWT token authentication
/// 
/// This interceptor automatically adds the Firebase Auth ID token
/// to all HTTP requests and handles token refresh when expired.
class AuthInterceptor extends Interceptor {
  final FirebaseAuth _firebaseAuth;
  
  AuthInterceptor({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      // Get current user
      final User? user = _firebaseAuth.currentUser;
      
      if (user != null) {
        // Get ID token (automatically refreshes if expired)
        final String? token = await user.getIdToken();
        
        // Add Authorization header
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        if (kDebugMode) {
          print('🔑 Auth token added to request: ${options.path}');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ No authenticated user - request sent without token: ${options.path}');
        }
      }
      
      // Continue with the request
      handler.next(options);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding auth token: $e');
      }
      
      // Continue without token on error (let the server handle it)
      handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized - token might be expired
    if (err.response?.statusCode == 401) {
      try {
        if (kDebugMode) {
          print('🔄 401 Unauthorized - attempting token refresh and retry');
        }
        
        // Try to refresh token and retry the request
        final bool retrySuccessful = await _retryWithRefreshedToken(err);
        
        if (retrySuccessful) {
          // If retry was successful, don't propagate the original error
          return;
        }
      } catch (retryError) {
        if (kDebugMode) {
          print('❌ Token refresh failed: $retryError');
        }
      }
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
  Future<bool> _retryWithRefreshedToken(DioException err) async {
    try {
      final User? user = _firebaseAuth.currentUser;
      
      if (user == null) {
        if (kDebugMode) {
          print('❌ No authenticated user for token refresh');
        }
        return false;
      }
      
      // Force refresh the token
      final String? newToken = await user.getIdToken(true);
      
      if (newToken == null) {
        if (kDebugMode) {
          print('❌ Failed to refresh token - token is null');
        }
        return false;
      }
      
      if (kDebugMode) {
        print('✅ Token refreshed successfully');
      }
      
      // Update the Authorization header with the new token
      err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
      
      // Create a new Dio instance to avoid circular interceptor calls
      final Dio retryDio = Dio();
      
      // Copy timeout configuration from original request
      retryDio.options.connectTimeout = err.requestOptions.connectTimeout;
      retryDio.options.sendTimeout = err.requestOptions.sendTimeout;
      retryDio.options.receiveTimeout = err.requestOptions.receiveTimeout;
      
      // Retry the request
      final Response response = await retryDio.request(
        err.requestOptions.path,
        data: err.requestOptions.data,
        queryParameters: err.requestOptions.queryParameters,
        options: Options(
          method: err.requestOptions.method,
          headers: err.requestOptions.headers,
          contentType: err.requestOptions.contentType,
          responseType: err.requestOptions.responseType,
          extra: err.requestOptions.extra,
        ),
      );
      
      if (kDebugMode) {
        print('✅ Request retry successful: ${err.requestOptions.path}');
      }
      
      // Resolve the original request with the retry response
      err.requestOptions.extra['retryResponse'] = response;
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Request retry failed: $e');
      }
      return false;
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
        return ApiConnectionException('Request was cancelled', 'request_cancelled');
        
      case DioExceptionType.connectionError:
        return ApiConnectionException(
          'Connection error. Please check your internet connection.',
          'connection_error',
        );
        
      case DioExceptionType.badCertificate:
        return ApiConnectionException('SSL certificate error', 'ssl_error');
        
      case DioExceptionType.unknown:
      default:
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
}