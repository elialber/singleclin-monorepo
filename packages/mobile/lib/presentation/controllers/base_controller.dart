import 'package:get/get.dart';
import 'package:singleclin_mobile/core/errors/failures.dart';
import 'package:singleclin_mobile/core/services/network_service.dart';
import 'package:singleclin_mobile/core/services/sync_service.dart';

/// Base controller that all controllers should extend
/// Provides common functionality for loading states, error handling, and offline-first operations
abstract class BaseController extends GetxController {
  // Loading state management
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  // Offline state management
  final RxBool _isOfflineMode = false.obs;
  final RxBool _hasCachedData = false.obs;
  final Rxn<DateTime> _lastSyncTime = Rxn<DateTime>();
  final RxBool _isSyncing = false.obs;

  // Error state management
  final Rxn<Failure> _error = Rxn<Failure>();
  Failure? get error => _error.value;

  // Success message management
  final RxnString _successMessage = RxnString();
  String? get successMessage => _successMessage.value;

  // Network and sync services (lazy-loaded)
  NetworkService? get _networkService => Get.find<NetworkService>();
  SyncService? get _syncService => Get.find<SyncService>();

  // Offline state getters
  bool get isOfflineMode => _isOfflineMode.value;
  bool get hasCachedData => _hasCachedData.value;
  bool get isOnline => _networkService?.isConnected ?? false;
  bool get hasGoodConnection => _networkService?.hasGoodConnection ?? false;
  DateTime? get lastSyncTime => _lastSyncTime.value;
  bool get isSyncing => _isSyncing.value;

  /// Sets loading state
  set loading(bool value) {
    _isLoading.value = value;
  }

  /// Sets error state
  void setError(Failure? failure) {
    _error.value = failure;
    if (failure != null) {
      // Show error snackbar
      showErrorSnackbar(failure.message);
    }
  }

  /// Clears error state
  void clearError() {
    _error.value = null;
  }

  /// Sets success message
  void setSuccessMessage(String? message) {
    _successMessage.value = message;
    if (message != null) {
      // Show success snackbar
      showSuccessSnackbar(message);
    }
  }

  /// Clears success message
  void clearSuccessMessage() {
    _successMessage.value = null;
  }

  /// Sets offline mode state
  void setOfflineMode(bool value) {
    _isOfflineMode.value = value;
    if (value) {
      showWarningSnackbar('Modo offline ativado - usando dados em cache');
    } else {
      showInfoSnackbar('Conexão restaurada - dados sendo atualizados');
    }
  }

  /// Sets cached data availability
  void setCachedData(bool available) {
    _hasCachedData.value = available;
  }

  /// Updates last sync time
  void updateLastSyncTime(DateTime? time) {
    _lastSyncTime.value = time;
  }

  /// Sets syncing state
  void setSyncing(bool syncing) {
    _isSyncing.value = syncing;
  }

  /// Execute an async operation with loading and error handling
  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    bool showLoading = true,
    bool showError = true,
    void Function(T result)? onSuccess,
    void Function(Failure failure)? onError,
  }) async {
    try {
      if (showLoading) {
        loading = true;
      }
      clearError();

      final result = await operation();

      if (onSuccess != null) {
        onSuccess(result);
      }

      return result;
    } on Exception catch (e) {
      final failure = _mapExceptionToFailure(e);

      if (showError) {
        setError(failure);
      }

      if (onError != null) {
        onError(failure);
      }

      return null;
    } finally {
      if (showLoading) {
        loading = false;
      }
    }
  }

  /// Maps exceptions to failures
  Failure _mapExceptionToFailure(Exception e) {
    // Handle specific exception types
    if (e.toString().contains('SocketException')) {
      return const NetworkFailure();
    } else if (e.toString().contains('TimeoutException')) {
      return const TimeoutFailure();
    } else if (e.toString().contains('FormatException')) {
      return ValidationFailure(
        message: 'Formato de dados inválido',
        details: e,
      );
    } else if (e.toString().contains('unauthorized') ||
        e.toString().contains('401')) {
      return const AuthorizationFailure();
    } else if (e.toString().contains('forbidden') ||
        e.toString().contains('403')) {
      return const AuthorizationFailure(message: 'Acesso negado');
    } else if (e.toString().contains('not found') ||
        e.toString().contains('404')) {
      return const NotFoundFailure();
    }

    return UnknownFailure(message: e.toString(), details: e);
  }

  /// Shows error snackbar
  void showErrorSnackbar(String message) {
    Get.snackbar('Erro', message, snackPosition: SnackPosition.BOTTOM);
  }

  /// Shows success snackbar
  void showSuccessSnackbar(String message) {
    Get.snackbar('Sucesso', message, snackPosition: SnackPosition.BOTTOM);
  }

  /// Shows info snackbar
  void showInfoSnackbar(String message) {
    Get.snackbar('Informação', message, snackPosition: SnackPosition.BOTTOM);
  }

  /// Shows warning snackbar
  void showWarningSnackbar(String message) {
    Get.snackbar('Atenção', message, snackPosition: SnackPosition.BOTTOM);
  }

  // Offline-first data loading methods

  /// Execute an offline-first async operation
  /// Tries cache first, then network if available
  Future<T?> executeOfflineFirst<T>(
    Future<T> Function() networkOperation,
    Future<T?> Function() cacheOperation, {
    bool showLoading = true,
    bool showError = true,
    bool forceRefresh = false,
    void Function(T result)? onSuccess,
    void Function(Failure failure)? onError,
    void Function()? onOfflineMode,
  }) async {
    try {
      if (showLoading) {
        loading = true;
      }
      clearError();

      T? result;

      // Check network availability
      final hasConnection = _networkService?.isConnected ?? false;

      if (!forceRefresh && !hasConnection) {
        // Offline mode - use cache only
        setOfflineMode(true);
        result = await cacheOperation();

        if (result != null) {
          setCachedData(true);
          if (onOfflineMode != null) {
            onOfflineMode();
          }
        } else {
          setCachedData(false);
          throw Exception('Dados não disponíveis offline');
        }
      } else if (forceRefresh || hasConnection) {
        // Online mode - try network first, fallback to cache
        try {
          result = await networkOperation();
          setOfflineMode(false);

          if (result != null) {
            updateLastSyncTime(DateTime.now());
          }
        } catch (e) {
          print('⚠️ Network operation failed, trying cache: $e');

          // Fallback to cache
          result = await cacheOperation();

          if (result != null) {
            setOfflineMode(true);
            setCachedData(true);
            showWarningSnackbar('Usando dados em cache - conexão indisponível');

            if (onOfflineMode != null) {
              onOfflineMode();
            }
          } else {
            rethrow; // No cache available, propagate error
          }
        }
      }

      if (onSuccess != null && result != null) {
        onSuccess(result);
      }

      return result;
    } on Exception catch (e) {
      final failure = _mapExceptionToFailure(e);

      if (showError) {
        setError(failure);
      }

      if (onError != null) {
        onError(failure);
      }

      return null;
    } finally {
      if (showLoading) {
        loading = false;
      }
    }
  }

  /// Execute cache-only operation (for guaranteed offline access)
  Future<T?> executeCacheOnly<T>(
    Future<T?> Function() cacheOperation, {
    bool showLoading = true,
    bool showError = true,
    void Function(T result)? onSuccess,
    void Function(Failure failure)? onError,
  }) async {
    try {
      if (showLoading) {
        loading = true;
      }
      clearError();

      final result = await cacheOperation();

      if (result != null) {
        setCachedData(true);
        setOfflineMode(true);

        if (onSuccess != null) {
          onSuccess(result);
        }
      } else {
        setCachedData(false);
        throw Exception('Dados não encontrados no cache');
      }

      return result;
    } on Exception catch (e) {
      final failure = _mapExceptionToFailure(e);

      if (showError) {
        setError(failure);
      }

      if (onError != null) {
        onError(failure);
      }

      return null;
    } finally {
      if (showLoading) {
        loading = false;
      }
    }
  }

  /// Execute network-only operation with offline awareness
  Future<T?> executeNetworkOnly<T>(
    Future<T> Function() networkOperation, {
    bool showLoading = true,
    bool showError = true,
    bool requireGoodConnection = false,
    void Function(T result)? onSuccess,
    void Function(Failure failure)? onError,
    void Function()? onNoConnection,
  }) async {
    // Check connection requirements
    final hasConnection = _networkService?.isConnected ?? false;
    final hasGoodConnection = _networkService?.hasGoodConnection ?? false;

    if (!hasConnection || (requireGoodConnection && !hasGoodConnection)) {
      if (onNoConnection != null) {
        onNoConnection();
      } else {
        setError(
          const NetworkFailure(message: 'Operação requer conexão com internet'),
        );
      }
      return null;
    }

    return executeAsync(
      networkOperation,
      showLoading: showLoading,
      showError: showError,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Trigger sync for this controller's data
  Future<void> syncData({bool force = false}) async {
    if (_syncService == null) {
      print('⚠️ SyncService not available');
      return;
    }

    setSyncing(true);

    try {
      final result = await _syncService!.syncAll(force: force);

      if (result.success) {
        updateLastSyncTime(DateTime.now());
        if (result.syncedCount > 0) {
          showSuccessSnackbar('${result.syncedCount} itens sincronizados');
        }
      } else {
        showWarningSnackbar(
          'Sincronização parcial: ${result.errorMessage ?? "erros encontrados"}',
        );
      }
    } catch (e) {
      showErrorSnackbar('Erro na sincronização: $e');
    } finally {
      setSyncing(false);
    }
  }

  /// Initialize offline-first controller
  @override
  void onInit() {
    super.onInit();
    _setupNetworkListener();
    _loadOfflineState();
  }

  /// Setup network status listener
  void _setupNetworkListener() {
    _networkService?.isConnectedRx.listen((connected) {
      setOfflineMode(!connected);

      // Trigger auto-sync when connection is restored
      if (connected && hasCachedData) {
        Future.delayed(const Duration(seconds: 2), syncData);
      }
    });
  }

  /// Load offline state (override in child controllers)
  void _loadOfflineState() {
    // Child controllers should override this to load their specific offline state
  }

  /// Get data freshness indicator
  String getDataFreshnessIndicator() {
    if (isSyncing) {
      return 'Sincronizando...';
    } else if (isOfflineMode && hasCachedData) {
      final lastSync = lastSyncTime;
      if (lastSync != null) {
        final diff = DateTime.now().difference(lastSync);
        if (diff.inMinutes < 60) {
          return 'Cache (${diff.inMinutes}min atrás)';
        } else if (diff.inHours < 24) {
          return 'Cache (${diff.inHours}h atrás)';
        } else {
          return 'Cache (${diff.inDays}d atrás)';
        }
      } else {
        return 'Cache (tempo desconhecido)';
      }
    } else if (isOnline) {
      return 'Dados atualizados';
    } else {
      return 'Sem dados offline';
    }
  }
}
