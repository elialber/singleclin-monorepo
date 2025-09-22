import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:get/get.dart' as getx;
import 'package:flutter/foundation.dart';
import 'package:singleclin_mobile/core/constants/app_constants.dart';
import 'package:singleclin_mobile/core/services/storage_service.dart';
import 'dart:io';

class ApiService extends getx.GetxService {
  late Dio _dio;
  final StorageService _storageService = getx.Get.find<StorageService>();

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeDio();
  }

  Future<void> _initializeDio() async {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.timeoutDuration,
      receiveTimeout: AppConstants.timeoutDuration,
      sendTimeout: AppConstants.timeoutDuration,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Configure SSL certificate handling for development
    if (kDebugMode) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final HttpClient client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }

    // Interceptor para adicionar token de autenticação
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storageService.getString(AppConstants.tokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Check if this is an endpoint where we want to handle 401 gracefully
          final requestPath = error.requestOptions.path;
          final isCreditsEndpoint = requestPath.contains('/appointments/my-credits');
          final isScheduleEndpoint = requestPath.contains('/appointments/schedule');
          final isConfirmEndpoint = requestPath.contains('/appointments/confirm');

          if (!isCreditsEndpoint && !isScheduleEndpoint && !isConfirmEndpoint) {
            // Token expirado - fazer logout apenas se não for um endpoint de agendamento
            await _handleUnauthorized();
          }
        }
        handler.next(error);
      },
    ));

    // Interceptor para logs (apenas em debug)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      requestHeader: false,
      responseHeader: false,
    ));
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
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        ...?data,
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
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
        final message = error.response?.data?['message'] ?? 
                       error.response?.statusMessage ?? 
                       AppConstants.genericError;
        
        switch (statusCode) {
          case 401:
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