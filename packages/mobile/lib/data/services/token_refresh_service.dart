import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:singleclin_mobile/core/services/storage_service.dart';
import 'package:singleclin_mobile/core/constants/api_constants.dart';
import 'package:singleclin_mobile/data/services/auth_service.dart';
import 'package:singleclin_mobile/domain/entities/user_entity.dart';

/// Service for managing automatic token refresh and session persistence.
class TokenRefreshService {
  TokenRefreshService({
    AuthService? authService,
    FirebaseAuth? firebaseAuth,
    StorageService? storageService,
  })  : _authService = authService ?? AuthService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _storageService = storageService ?? Get.find<StorageService>();
  final AuthService _authService;
  final FirebaseAuth _firebaseAuth;
  final StorageService _storageService;

  bool _isActive = false;
  Timer? _refreshTimer;
  StreamSubscription<UserEntity?>? _authStateSubscription;
  StreamSubscription<User?>? _idTokenSubscription;
  UserEntity? _currentUser;
  _TokenRefreshMetadata _metadata = const _TokenRefreshMetadata();
  String? _metadataKey;

  static const Duration _refreshInterval = Duration(minutes: 50);
  static const Duration _baseRetryDelay = Duration(seconds: 30);
  static const Duration _maxRetryDelay = Duration(minutes: 5);
  static const int _maxRetryAttempts = 3;
  static const String _metadataKeyPrefix = 'token_refresh_metadata_';

  final Dio _sessionCheckClient = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: {
        ApiConstants.acceptHeader: ApiConstants.jsonContentType,
        ApiConstants.contentTypeHeader: ApiConstants.jsonContentType,
      },
    ),
  );

  final StreamController<String> _hardFailureController =
      StreamController<String>.broadcast();

  /// Stream that notifies listeners when the service exhausts all retries.
  Stream<String> get onHardFailure => _hardFailureController.stream;

  /// Initialize the token refresh service.
  Future<void> initialize() async {
    if (_isActive) {
      return;
    }

    _isActive = true;

    if (kDebugMode) {
      print('🔄 TokenRefreshService: Initializing...');
    }

    _authStateSubscription =
        _authService.authStateChanges.listen(_handleAuthStateChange);

    final currentUser = await _authService.getCurrentUser();
    await _handleAuthStateChange(currentUser);
  }

  Future<void> _handleAuthStateChange(UserEntity? user) async {
    _cancelScheduledRefresh();

    if (!_isActive) {
      _stopFirebaseTokenListener();
      return;
    }

    _currentUser = user;

    if (user == null) {
      final previousKey = _metadataKey;
      _metadataKey = null;
      _metadata = const _TokenRefreshMetadata();
      if (previousKey != null) {
        await _storageService.remove(previousKey);
      }
      _stopFirebaseTokenListener();
      return;
    }

    _metadataKey = _metadataKeyFor(user.id);
    await _loadMetadata();

    if (!_isActive || _currentUser == null || _currentUser!.id != user.id) {
      return;
    }

    _startFirebaseTokenListener();
    await _scheduleRefresh();

    if (kDebugMode) {
      print('🔄 TokenRefreshService: User authenticated, scheduling refresh');
    }
  }

  Future<void> _loadMetadata() async {
    if (_metadataKey == null) {
      _metadata = const _TokenRefreshMetadata();
      return;
    }

    final data = await _storageService.getJson(_metadataKey!);
    if (data == null) {
      _metadata = const _TokenRefreshMetadata();
      return;
    }

    _metadata = _TokenRefreshMetadata.fromJson(data);
  }

  Future<void> _saveMetadata() async {
    if (_metadataKey == null) {
      return;
    }
    await _storageService.setJson(_metadataKey!, _metadata.toJson());
  }

  Future<void> _scheduleRefresh({Duration? delay}) async {
    if (!_isActive || _currentUser == null) {
      return;
    }

    final now = DateTime.now();
    Duration computedDelay;

    if (delay != null) {
      computedDelay = delay;
      _metadata = _metadata.copyWith(
        nextAttemptAt: now.add(delay),
        retryCount: _metadata.retryCount,
      );
      await _saveMetadata();
    } else if (_metadata.nextAttemptAt != null) {
      computedDelay = _metadata.nextAttemptAt!.difference(now);
      if (computedDelay.isNegative) {
        computedDelay = Duration.zero;
      }
    } else {
      computedDelay = _refreshInterval;
      _metadata = _metadata.copyWith(
        nextAttemptAt: now.add(_refreshInterval),
        retryCount: _metadata.retryCount,
      );
      await _saveMetadata();
    }

    _cancelScheduledRefresh();

    _refreshTimer = Timer(computedDelay, () async {
      await _executeRefreshAttempt();
    });

    if (kDebugMode) {
      print(
        '🔄 TokenRefreshService: Próxima tentativa em ${computedDelay.inSeconds}s',
      );
    }
  }

  void _cancelScheduledRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<_RefreshOutcome> _executeRefreshAttempt() async {
    if (!_isActive || _currentUser == null) {
      return _RefreshOutcome.skipped;
    }

    _cancelScheduledRefresh();

    final outcome = await _refreshTokenInternal();

    if (outcome.success) {
      final now = DateTime.now();
      _metadata = _TokenRefreshMetadata(
        lastSuccessAt: now,
        retryCount: 0,
        nextAttemptAt: now.add(_refreshInterval),
      );
      await _saveMetadata();
      if (_isActive && _currentUser != null) {
        await _scheduleRefresh();
      }
      return outcome;
    }

    if (outcome.retryable) {
      final attempts = _metadata.retryCount + 1;
      if (attempts > _maxRetryAttempts) {
        await _handleHardFailure(outcome.message);
        return outcome;
      }

      final backoff = _calculateBackoffDelay(attempts);
      _metadata = _TokenRefreshMetadata(
        lastSuccessAt: _metadata.lastSuccessAt,
        retryCount: attempts,
        nextAttemptAt: DateTime.now().add(backoff),
      );
      await _saveMetadata();

      if (_isActive && _currentUser != null) {
        await _scheduleRefresh(delay: backoff);
      }

      if (kDebugMode) {
        print(
          '⚠️ TokenRefreshService: Retry attempt $attempts scheduled in ${backoff.inSeconds}s',
        );
      }

      return outcome;
    }

    await _handleHardFailure(outcome.message);
    return outcome;
  }

  Future<_RefreshOutcome> _refreshTokenInternal() async {
    if (_currentUser == null) {
      return _RefreshOutcome.skipped;
    }

    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      if (kDebugMode) {
        print('⚠️ TokenRefreshService: Firebase currentUser is null');
      }
      return const _RefreshOutcome.failure('Sessão expirada. Faça login novamente.');
    }

    try {
      final token = await firebaseUser.getIdToken(true);

      if (kDebugMode) {
        print('✅ TokenRefreshService: Token refreshed com sucesso');
      }

      final validation = await _validateSessionWithBackend(token);
      if (validation.success) {
        return _RefreshOutcome.success(token);
      }

      if (validation.retryable) {
        return _RefreshOutcome.retryable(
          validation.message ?? 'Falha na validação da sessão. Tentando novamente...',
        );
      }

      return _RefreshOutcome.failure(
        validation.message ?? 'Sua sessão foi invalidada. Faça login novamente.',
      );
    } on PlatformException catch (e) {
      if (e.code == 'network_error') {
        if (kDebugMode) {
          print('🌐 TokenRefreshService: Falha de rede ao renovar token');
        }
        return const _RefreshOutcome.retryable('Erro de rede ao renovar token');
      }
      return _RefreshOutcome.failure(e.message ?? 'Falha ao renovar token.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        return const _RefreshOutcome.retryable('Erro de rede ao renovar token');
      }
      return _RefreshOutcome.failure(e.message ?? 'Sessão expirada.');
    } catch (e) {
      if (kDebugMode) {
        print('❌ TokenRefreshService: Erro inesperado ao renovar token: $e');
      }
      return const _RefreshOutcome.retryable('Erro ao renovar token. Tentando novamente...');
    }
  }

  Future<_SessionValidationResult> _validateSessionWithBackend(String token) async {
    try {
      final response = await _sessionCheckClient.get(
        ApiConstants.profileEndpoint,
        options: Options(
          headers: {
            ApiConstants.authorizationHeader:
                '${ApiConstants.bearerTokenPrefix}$token',
          },
        ),
      );

      final status = response.statusCode ?? 0;

      if (status == ApiConstants.statusOk) {
        final dynamic data = response.data;
        bool isActive = true;
        if (data is Map<String, dynamic>) {
          final payload = data[ApiConstants.dataKey];
          if (payload is Map<String, dynamic>) {
            isActive = payload['isActive'] != false;
          }
        }

        if (!isActive) {
          return const _SessionValidationResult.failure(
            'Seu acesso foi desativado. Faça login novamente.',
          );
        }

        return const _SessionValidationResult.success();
      }

      if (status == ApiConstants.statusUnauthorized ||
          status == ApiConstants.statusForbidden ||
          status == 409) {
        return const _SessionValidationResult.failure(
          'Sua sessão foi invalidada pelo servidor.',
        );
      }

      if (status >= ApiConstants.statusInternalServerError) {
        return const _SessionValidationResult.retryable(
          'Servidor indisponível para validar sessão.',
        );
      }

      return const _SessionValidationResult.retryable(
        'Não foi possível validar a sessão com o servidor.',
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return const _SessionValidationResult.retryable(
          'Erro de rede ao validar sessão com o servidor.',
        );
      }

      final status = e.response?.statusCode ?? 0;
      if (status == ApiConstants.statusUnauthorized ||
          status == ApiConstants.statusForbidden ||
          status == 409) {
        return const _SessionValidationResult.failure(
          'Sua sessão foi invalidada pelo servidor.',
        );
      }

      return const _SessionValidationResult.retryable(
        'Não foi possível validar a sessão com o servidor.',
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ TokenRefreshService: Erro validando sessão: $e');
      }
      return const _SessionValidationResult.retryable(
        'Erro inesperado ao validar sessão.',
      );
    }
  }

  Duration _calculateBackoffDelay(int attempt) {
    final seconds = _baseRetryDelay.inSeconds * math.pow(2, attempt - 1);
    final capped = math.min(seconds, _maxRetryDelay.inSeconds.toDouble());
    return Duration(seconds: capped.round());
  }

  Future<void> _handleHardFailure(String? message) async {
    final failureMessage =
        message ?? 'Sua sessão expirou. Faça login novamente.';

    if (kDebugMode) {
      print('⛔ TokenRefreshService: Hard failure -> $failureMessage');
    }

    _hardFailureController.add(failureMessage);
    await _clearCurrentMetadata();
    _cancelScheduledRefresh();
  }

  Future<void> _clearCurrentMetadata() async {
    if (_metadataKey != null) {
      await _storageService.remove(_metadataKey!);
    }
    _metadata = const _TokenRefreshMetadata();
  }

  /// Manually refresh the current user's token.
  Future<String?> refreshToken() async {
    final outcome = await _executeRefreshAttempt();
    return outcome.token;
  }

  /// Pause the token refresh timers.
  void pause() {
    if (!_isActive) {
      return;
    }
    _cancelScheduledRefresh();
    _stopFirebaseTokenListener();
    if (kDebugMode) {
      print('⏸️ TokenRefreshService: Pausado (app em background)');
    }
  }

  /// Resume the token refresh timers.
  Future<void> resume({bool forceRefresh = false}) async {
    if (!_isActive || _currentUser == null) {
      return;
    }
    _startFirebaseTokenListener();

    if (forceRefresh) {
      final outcome = await _executeRefreshAttempt();
      if (kDebugMode) {
        print('▶️ TokenRefreshService: Retomado com refresh imediato (success=${outcome.success}, retryable=${outcome.retryable})');
      }
      if (!outcome.success && !outcome.retryable) {
        return;
      }
      return;
    }

    await _scheduleRefresh();
    if (kDebugMode) {
      print('▶️ TokenRefreshService: Retomado (agendamento restaurado)');
    }
  }

  Future<bool> isTokenExpiringSoon() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return true;
      }

      final IdTokenResult tokenResult = await user.getIdTokenResult();
      final DateTime? expirationTime = tokenResult.expirationTime;

      if (expirationTime == null) {
        return true;
      }

      final Duration timeUntilExpiration =
          expirationTime.difference(DateTime.now());
      return timeUntilExpiration.inMinutes < 10;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ TokenRefreshService: Error checking token expiration: $e');
      }
      return true;
    }
  }

  Future<String?> getCurrentToken() async {
    try {
      final bool needsRefresh = await isTokenExpiringSoon();

      if (needsRefresh) {
        if (kDebugMode) {
          print('🔄 TokenRefreshService: Token expiring soon, refreshing...');
        }
        return await refreshToken();
      }

      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return null;
      }

      return await user.getIdToken();
    } catch (e) {
      if (kDebugMode) {
        print('❌ TokenRefreshService: Error getting current token: $e');
      }
      return null;
    }
  }

  void dispose() {
    _isActive = false;
    _cancelScheduledRefresh();
    _stopFirebaseTokenListener();
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
    _currentUser = null;
    if (_metadataKey != null) {
      unawaited(_storageService.remove(_metadataKey!));
    }
    _metadata = const _TokenRefreshMetadata();
    _metadataKey = null;

    if (kDebugMode) {
      print('🔄 TokenRefreshService: Disposed');
    }
  }

  Map<String, dynamic> getStatus() {
    return {
      'isActive': _isActive,
      'hasUser': _currentUser != null,
      'hasTimer': _refreshTimer != null,
      'retryCount': _metadata.retryCount,
      'nextAttempt': _metadata.nextAttemptAt?.toIso8601String(),
      'lastSuccess': _metadata.lastSuccessAt?.toIso8601String(),
    };
  }

  String _metadataKeyFor(String userId) => '$_metadataKeyPrefix$userId';

  void _startFirebaseTokenListener() {
    if (_idTokenSubscription != null || !_isActive) {
      return;
    }

    _idTokenSubscription = _firebaseAuth.idTokenChanges().listen(
      (User? firebaseUser) async {
        if (!_isActive || firebaseUser == null) {
          return;
        }

        if (kDebugMode) {
          print('🔁 TokenRefreshService: Firebase idTokenChanges recebido');
        }

        try {
          final token = await firebaseUser.getIdToken();
          final validation = await _validateSessionWithBackend(token);

          if (validation.success) {
            final now = DateTime.now();
            _metadata = _metadata.copyWith(
              lastSuccessAt: now,
              retryCount: 0,
              nextAttemptAt: now.add(_refreshInterval),
            );
            await _saveMetadata();
            await _scheduleRefresh();
            return;
          }

          if (validation.retryable) {
            if (kDebugMode) {
              print('⚠️ TokenRefreshService: Validação via idTokenChanges pediu retry');
            }
            await _scheduleRefresh();
            return;
          }

          await _handleHardFailure(validation.message);
        } catch (error, stackTrace) {
          if (kDebugMode) {
            print('⚠️ TokenRefreshService: Erro ao tratar idTokenChanges -> $error');
            debugPrintStack(stackTrace: stackTrace);
          }
        }
      },
      onError: (Object error) {
        if (kDebugMode) {
          print('⚠️ TokenRefreshService: Stream idTokenChanges erro -> $error');
        }
      },
      cancelOnError: false,
    );
  }

  void _stopFirebaseTokenListener() {
    _idTokenSubscription?.cancel();
    _idTokenSubscription = null;
  }
}

class _TokenRefreshMetadata {
  const _TokenRefreshMetadata({
    this.lastSuccessAt,
    this.retryCount = 0,
    this.nextAttemptAt,
  });

  final DateTime? lastSuccessAt;
  final int retryCount;
  final DateTime? nextAttemptAt;

  _TokenRefreshMetadata copyWith({
    DateTime? lastSuccessAt,
    int? retryCount,
    DateTime? nextAttemptAt,
  }) {
    return _TokenRefreshMetadata(
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      retryCount: retryCount ?? this.retryCount,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastSuccessAt': lastSuccessAt?.toIso8601String(),
      'retryCount': retryCount,
      'nextAttemptAt': nextAttemptAt?.toIso8601String(),
    };
  }

  factory _TokenRefreshMetadata.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? value) {
      if (value == null) return null;
      return DateTime.tryParse(value);
    }

    return _TokenRefreshMetadata(
      lastSuccessAt: parseDate(json['lastSuccessAt'] as String?),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      nextAttemptAt: parseDate(json['nextAttemptAt'] as String?),
    );
  }
}

class _SessionValidationResult {
  const _SessionValidationResult._({
    required this.success,
    required this.retryable,
    this.message,
  });

  final bool success;
  final bool retryable;
  final String? message;

  const _SessionValidationResult.success()
      : this._(success: true, retryable: false);

  const _SessionValidationResult.retryable(String message)
      : this._(success: false, retryable: true, message: message);

  const _SessionValidationResult.failure(String message)
      : this._(success: false, retryable: false, message: message);
}

class _RefreshOutcome {
  const _RefreshOutcome._({
    required this.success,
    required this.retryable,
    this.token,
    this.message,
  });

  final bool success;
  final bool retryable;
  final String? token;
  final String? message;

  static const _RefreshOutcome skipped =
      _RefreshOutcome._(success: false, retryable: false);

  const _RefreshOutcome.success(String token)
      : this._(success: true, retryable: false, token: token);

  const _RefreshOutcome.retryable(String message)
      : this._(success: false, retryable: true, message: message);

  const _RefreshOutcome.failure(String message)
      : this._(success: false, retryable: false, message: message);
}
