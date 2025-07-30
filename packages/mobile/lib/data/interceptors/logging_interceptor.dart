import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// HTTP logging interceptor for development debugging
/// 
/// This interceptor logs HTTP requests and responses in a readable format
/// Only active in debug mode to avoid performance impact in production
class LoggingInterceptor extends Interceptor {
  final bool enabled;
  final bool logRequestBody;
  final bool logResponseBody;
  final int maxLogLength;

  LoggingInterceptor({
    this.enabled = kDebugMode,
    this.logRequestBody = true,
    this.logResponseBody = true,
    this.maxLogLength = 1000,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!enabled) {
      handler.next(options);
      return;
    }

    final String method = options.method.toUpperCase();
    final String url = options.uri.toString();
    
    print('\n🚀 REQUEST [$method] $url');
    print('Headers: ${_formatHeaders(options.headers)}');
    
    if (logRequestBody && options.data != null) {
      print('Body: ${_formatData(options.data)}');
    }
    
    if (options.queryParameters.isNotEmpty) {
      print('Query Parameters: ${options.queryParameters}');
    }
    
    print('─' * 50);
    
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!enabled) {
      handler.next(response);
      return;
    }

    final String method = response.requestOptions.method.toUpperCase();
    final String url = response.requestOptions.uri.toString();
    final int statusCode = response.statusCode ?? 0;
    final String statusMessage = response.statusMessage ?? 'Unknown';
    
    print('\n✅ RESPONSE [$method] $url');
    print('Status: $statusCode $statusMessage');
    print('Headers: ${_formatHeaders(response.headers.map)}');
    
    if (logResponseBody && response.data != null) {
      print('Body: ${_formatData(response.data)}');
    }
    
    print('─' * 50);
    
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!enabled) {
      handler.next(err);
      return;
    }

    final String method = err.requestOptions.method.toUpperCase();
    final String url = err.requestOptions.uri.toString();
    
    print('\n❌ ERROR [$method] $url');
    print('Type: ${err.type}');
    print('Message: ${err.message}');
    
    if (err.response != null) {
      final int statusCode = err.response!.statusCode ?? 0;
      final String statusMessage = err.response!.statusMessage ?? 'Unknown';
      
      print('Status: $statusCode $statusMessage');
      print('Response Headers: ${_formatHeaders(err.response!.headers.map)}');
      
      if (err.response!.data != null) {
        print('Response Body: ${_formatData(err.response!.data)}');
      }
    }
    
    if (err.stackTrace != null) {
      print('Stack Trace: ${err.stackTrace}');
    }
    
    print('─' * 50);
    
    handler.next(err);
  }

  /// Format headers for logging
  String _formatHeaders(Map<String, dynamic> headers) {
    if (headers.isEmpty) return '{}';
    
    final StringBuffer buffer = StringBuffer('{\n');
    headers.forEach((key, value) {
      // Don't log sensitive headers
      if (_isSensitiveHeader(key)) {
        buffer.writeln('  $key: [HIDDEN]');
      } else {
        buffer.writeln('  $key: $value');
      }
    });
    buffer.write('}');
    
    return buffer.toString();
  }

  /// Format request/response data for logging
  String _formatData(dynamic data) {
    if (data == null) return 'null';
    
    String dataString;
    
    if (data is Map || data is List) {
      dataString = data.toString();
    } else if (data is FormData) {
      dataString = 'FormData(${data.fields.length} fields, ${data.files.length} files)';
    } else {
      dataString = data.toString();
    }
    
    // Truncate long data
    if (dataString.length > maxLogLength) {
      dataString = '${dataString.substring(0, maxLogLength)}... [TRUNCATED]';
    }
    
    return dataString;
  }

  /// Check if header contains sensitive information
  bool _isSensitiveHeader(String key) {
    final String lowerKey = key.toLowerCase();
    return lowerKey.contains('authorization') ||
           lowerKey.contains('cookie') ||
           lowerKey.contains('token') ||
           lowerKey.contains('password') ||
           lowerKey.contains('secret');
  }
}