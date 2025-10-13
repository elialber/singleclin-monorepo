import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getx;
import 'package:singleclin_mobile/core/constants/app_constants.dart';
import 'package:singleclin_mobile/core/services/storage_service.dart';
import 'package:singleclin_mobile/features/auth/controllers/auth_controller.dart';

class ApiService extends getx.GetxService {
  late Dio _dio;
  final StorageService _storageService = getx.Get.find<StorageService>();

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeDio();
  }

  Future<void> _initializeDio() async {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.timeoutDuration,
        receiveTimeout: AppConstants.timeoutDuration,
        sendTimeout: AppConstants.timeoutDuration,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Configure SSL certificate handling for development
    if (kDebugMode) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final HttpClient client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }

    // Interceptor para adicionar token de autenticação
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // First try to get JWT token directly from storage (fastest path)
          String? token = await _storageService.getString(
            AppConstants.tokenKey,
          );

          if (kDebugMode) {
            print(
              '🔑 DEBUG: Direct JWT token check: ${token != null ? "Found (${token.length} chars)" : "Not found"}',
            );
          }

          // If no JWT token, try AuthController (Firebase tokens)
          if (token == null || token.isEmpty) {
            try {
              final authController = getx.Get.find<AuthController>();
              token = await authController.getCurrentToken();

              if (kDebugMode) {
                print(
                  '🔑 DEBUG: Firebase token from AuthController: ${token != null ? "Found" : "Not found"}',
                );
              }
            } catch (e) {
              if (kDebugMode) {
                print(
                  '⚠️ DEBUG: AuthController not found, trying storage fallback: $e',
                );
              }
            }
          }

          // Final fallback check
          if (kDebugMode && (token == null || token.isEmpty)) {
            print(
              '❌ DEBUG: No token available for request to: ${options.path}',
            );
          }

          if (token != null && token.isNotEmpty) {
            // Envia tanto o Authorization padrão quanto o X-Firebase-Token para o backend gerar JWT interno com claims completas
            options.headers['Authorization'] = 'Bearer $token';
            options.headers['X-Firebase-Token'] = token;
            if (kDebugMode) {
              print('✅ DEBUG: Authorization header added to request');
            }
          } else {
            if (kDebugMode) {
              print(
                '❌ DEBUG: No token available for request to: ${options.path}',
              );
            }
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Check if this is an endpoint where we want to handle 401 gracefully
            final requestPath = error.requestOptions.path;
            final isCreditsEndpoint = requestPath.contains(
              '/Appointments/my-credits',
            );
            final isScheduleEndpoint = requestPath.contains(
              '/Appointments/schedule',
            );
            final isConfirmEndpoint = requestPath.contains(
              '/Appointments/confirm',
            );

            if (!isCreditsEndpoint &&
                !isScheduleEndpoint &&
                !isConfirmEndpoint) {
              // Token expirado - fazer logout apenas se não for um endpoint de agendamento
              await _handleUnauthorized();
            }
          }
          handler.next(error);
        },
      ),
    );

    // Interceptor para logs (apenas em debug)
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
      ),
    );
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Upload de arquivo
  Future<Response> uploadFile(
    String path,
    String filePath, {
    String? fileName,
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        ...?data,
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Download de arquivo
  Future<Response> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Manipular erros do Dio
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(AppConstants.timeoutError);

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;

        // Safely extract message from response data (can be String or Map)
        String message = AppConstants.genericError;
        try {
          final responseData = error.response?.data;
          if (responseData is Map<String, dynamic>) {
            message =
                responseData['message'] ??
                error.response?.statusMessage ??
                AppConstants.genericError;
          } else if (responseData is String) {
            message = responseData.isNotEmpty
                ? responseData
                : (error.response?.statusMessage ?? AppConstants.genericError);
          } else {
            message =
                error.response?.statusMessage ?? AppConstants.genericError;
          }
        } catch (e) {
          message = error.response?.statusMessage ?? AppConstants.genericError;
        }

        switch (statusCode) {
          case 401:
            print('🚫 401 Unauthorized: $message');
            print('🔍 Response data type: ${error.response?.data.runtimeType}');

            // Don't throw exception for appointments endpoint - let it use fallback data
            if (error.requestOptions.path.contains(
              '/Appointments/my-appointments',
            )) {
              print(
                '⚠️ 401 on appointments endpoint - returning error without throwing',
              );
              return Exception(
                'Appointments endpoint auth issue - using fallback data',
              );
            }

            return Exception(AppConstants.unauthorizedError);
          case 404:
            return Exception('Recurso não encontrado');
          case 500:
            return Exception('Erro interno do servidor');
          default:
            return Exception(message);
        }

      case DioExceptionType.cancel:
        return Exception('Requisição cancelada');

      case DioExceptionType.connectionError:
        return Exception(AppConstants.networkError);

      default:
        return Exception(AppConstants.genericError);
    }
  }

  /// Manipular usuário não autorizado
  Future<void> _handleUnauthorized() async {
    await _storageService.remove(AppConstants.tokenKey);
    await _storageService.remove(AppConstants.userKey);

    getx.Get.offAllNamed('/login');

    getx.Get.snackbar(
      'Sessão Expirada',
      'Faça login novamente',
      snackPosition: getx.SnackPosition.BOTTOM,
    );
  }

  /// Atualizar token de autenticação
  Future<void> updateAuthToken(String token) async {
    await _storageService.setString(AppConstants.tokenKey, token);
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Remover token de autenticação
  Future<void> removeAuthToken() async {
    await _storageService.remove(AppConstants.tokenKey);
    _dio.options.headers.remove('Authorization');
  }

  /// Verificar se há conexão com internet
  bool get hasInternetConnection {
    // Implementar verificação de conectividade
    return true;
  }
}
