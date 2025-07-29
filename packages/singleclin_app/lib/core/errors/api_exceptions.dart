/// Base class for API exceptions
abstract class ApiException implements Exception {
  const ApiException(this.message, this.code);

  final String message;
  final String code;

  @override
  String toString() => 'ApiException: $message (code: $code)';
}

/// Exception thrown when API request times out
class ApiTimeoutException extends ApiException {
  const ApiTimeoutException(super.message, super.code);
}

/// Exception thrown when API returns 400 Bad Request
class ApiBadRequestException extends ApiException {
  const ApiBadRequestException(super.message, super.code);
}

/// Exception thrown when API returns 401 Unauthorized
class ApiUnauthorizedException extends ApiException {
  const ApiUnauthorizedException(super.message, super.code);
}

/// Exception thrown when API returns 403 Forbidden
class ApiForbiddenException extends ApiException {
  const ApiForbiddenException(super.message, super.code);
}

/// Exception thrown when API returns 404 Not Found
class ApiNotFoundException extends ApiException {
  const ApiNotFoundException(super.message, super.code);
}

/// Exception thrown when API returns 422 Validation Error
class ApiValidationException extends ApiException {
  const ApiValidationException(super.message, super.code);

  /// Extract validation errors from response data
  static Map<String, List<String>> extractValidationErrors(dynamic data) {
    final Map<String, List<String>> errors = {};
    
    if (data is Map<String, dynamic>) {
      // Laravel/Standard validation error format
      if (data.containsKey('errors') && data['errors'] is Map) {
        final Map<String, dynamic> errorMap = data['errors'];
        for (final entry in errorMap.entries) {
          if (entry.value is List) {
            errors[entry.key] = List<String>.from(entry.value);
          } else if (entry.value is String) {
            errors[entry.key] = [entry.value];
          }
        }
      }
      // Alternative validation error format
      else if (data.containsKey('details') && data['details'] is List) {
        final List<dynamic> details = data['details'];
        for (final detail in details) {
          if (detail is Map<String, dynamic> && 
              detail.containsKey('field') && 
              detail.containsKey('message')) {
            final String field = detail['field'];
            final String message = detail['message'];
            errors.putIfAbsent(field, () => []).add(message);
          }
        }
      }
    }
    
    return errors;
  }
}

/// Exception thrown when API returns 429 Too Many Requests
class ApiTooManyRequestsException extends ApiException {
  const ApiTooManyRequestsException(super.message, super.code);
}

/// Exception thrown when API returns 500 Internal Server Error
class ApiServerException extends ApiException {
  const ApiServerException(super.message, super.code);
}

/// Exception thrown when there's a connection error
class ApiConnectionException extends ApiException {
  const ApiConnectionException(super.message, super.code);
}

/// Utility class for creating localized error messages
class ApiExceptionLocalizer {
  /// Get localized error message for API exceptions
  static String getLocalizedMessage(ApiException exception) {
    switch (exception.runtimeType) {
      case ApiTimeoutException:
        return 'Tempo limite excedido. Verifique sua conexão com a internet.';
      
      case ApiBadRequestException:
        return 'Dados inválidos. Verifique as informações enviadas.';
      
      case ApiUnauthorizedException:
        return 'Não autorizado. Faça login novamente.';
      
      case ApiForbiddenException:
        return 'Acesso negado. Você não tem permissão para esta operação.';
      
      case ApiNotFoundException:
        return 'Recurso não encontrado.';
      
      case ApiValidationException:
        return 'Dados inválidos. Corrija os campos destacados.';
      
      case ApiTooManyRequestsException:
        return 'Muitas tentativas. Tente novamente em alguns minutos.';
      
      case ApiServerException:
        return 'Erro no servidor. Tente novamente mais tarde.';
      
      case ApiConnectionException:
        return 'Erro de conexão. Verifique sua internet.';
      
      default:
        return exception.message.isNotEmpty 
            ? exception.message 
            : 'Erro inesperado. Tente novamente.';
    }
  }

  /// Check if error should trigger user logout
  static bool shouldLogoutUser(ApiException exception) {
    return exception is ApiUnauthorizedException;
  }

  /// Check if error is retryable
  static bool isRetryable(ApiException exception) {
    return exception is ApiTimeoutException ||
           exception is ApiConnectionException ||
           exception is ApiServerException ||
           exception is ApiTooManyRequestsException;
  }

  /// Get retry delay for retryable errors
  static Duration getRetryDelay(ApiException exception) {
    switch (exception.runtimeType) {
      case ApiTimeoutException:
      case ApiConnectionException:
        return const Duration(seconds: 2);
      
      case ApiServerException:
        return const Duration(seconds: 5);
      
      case ApiTooManyRequestsException:
        return const Duration(minutes: 1);
      
      default:
        return const Duration(seconds: 1);
    }
  }
}