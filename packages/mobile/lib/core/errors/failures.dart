import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  const Failure({
    required this.message,
    this.code,
    this.details,
  });

  final String message;
  final String? code;
  final dynamic details;

  @override
  List<Object?> get props => [message, code, details];

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

/// Server failures from API responses
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Network failures (no internet, timeout, etc.)
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Sem conexão com a internet',
    super.code = 'NETWORK_ERROR',
    super.details,
  });
}

/// Cache failures when reading/writing to local storage
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Erro ao acessar dados locais',
    super.code = 'CACHE_ERROR',
    super.details,
  });
}

/// Authentication failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    super.message = 'Erro de autenticação',
    super.code = 'AUTH_ERROR',
    super.details,
  });
}

/// Authorization failures
class AuthorizationFailure extends Failure {
  const AuthorizationFailure({
    super.message = 'Acesso não autorizado',
    super.code = 'UNAUTHORIZED',
    super.details,
  });
}

/// Validation failures for input data
class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'Dados inválidos',
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
    super.details,
  });
  
  final Map<String, List<String>>? fieldErrors;

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'Recurso não encontrado',
    super.code = 'NOT_FOUND',
    super.details,
  });
}

/// Timeout failures
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'Tempo de resposta excedido',
    super.code = 'TIMEOUT',
    super.details,
  });
}

/// Unknown failures for unexpected errors
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Erro desconhecido',
    super.code = 'UNKNOWN_ERROR',
    super.details,
  });
}

/// Business logic failures
class BusinessFailure extends Failure {
  const BusinessFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// QR Code related failures
class QrCodeFailure extends Failure {
  const QrCodeFailure({
    required super.message,
    super.code = 'QR_CODE_ERROR',
    super.details,
  });
}

/// Plan related failures
class PlanFailure extends Failure {
  const PlanFailure({
    required super.message,
    super.code = 'PLAN_ERROR',
    super.details,
  });
}

/// Credit related failures
class CreditFailure extends Failure {
  const CreditFailure({
    required super.message,
    super.code = 'CREDIT_ERROR',
    super.details,
  });
}