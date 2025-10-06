import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/core/models/cache_entity.dart';
import 'package:singleclin_mobile/core/services/cache_service.dart';
import 'package:singleclin_mobile/core/services/hive_box_manager.dart';
import 'package:singleclin_mobile/core/services/network_service.dart';

/// Central synchronization service for offline-first architecture
///
/// Coordinates data synchronization between local cache and backend APIs.
/// Handles conflict resolution, retry logic, and background sync operations.
class SyncService extends GetxService {
  SyncService({
    required CacheService cacheService,
    required NetworkService networkService,
    required HiveBoxManager boxManager,
    required Dio dio,
  }) : _cacheService = cacheService,
       _networkService = networkService,
       _boxManager = boxManager,
       _dio = dio;
  final CacheService _cacheService;
  final NetworkService _networkService;
  final HiveBoxManager _boxManager;
  final Dio _dio;

  // Sync state management
  final _syncInProgress = false.obs;
  final _lastSyncTime = Rxn<DateTime>();
  final _syncErrors = <String>[].obs;
  final _pendingOperationsCount = 0.obs;

  // Background sync timer
  Timer? _backgroundSyncTimer;
  Timer? _retryTimer;

  // Sync configuration
  static const Duration _backgroundSyncInterval = Duration(minutes: 15);
  static const Duration _retryInterval = Duration(minutes: 5);
  static const int _maxRetryAttempts = 3;
  static const int _batchSize = 10;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeSyncService();
  }

  Future<void> _initializeSyncService() async {
    try {
      // Load last sync timestamp
      await _loadSyncMetadata();

      // Process any pending operations from previous session
      await _processPendingOperations();

      // Setup automatic sync when network becomes available
      _networkService.isConnected.listen((isConnected) {
        if (isConnected && !_syncInProgress.value) {
          _scheduleSync(immediate: true);
        }
      });

      // Setup background sync timer
      _setupBackgroundSync();

      print('✅ SyncService initialized');
    } catch (e) {
      print('❌ SyncService initialization failed: $e');
      rethrow;
    }
  }

  // Public API

  /// Manually trigger full synchronization
  Future<SyncResult> syncAll({bool force = false}) async {
    if (_syncInProgress.value && !force) {
      return SyncResult.alreadyInProgress();
    }

    if (!_networkService.isConnected && !force) {
      return SyncResult.noConnection();
    }

    return _performFullSync();
  }

  /// Sync specific data type
  Future<SyncResult> syncDataType(BoxType boxType, {bool force = false}) async {
    if (!_networkService.isConnected && !force) {
      return SyncResult.noConnection();
    }

    return _syncBoxType(boxType);
  }

  /// Add operation to pending queue
  Future<void> addPendingOperation(PendingOperation operation) async {
    try {
      final queueBox = await _boxManager.ensureBox(BoxType.operationQueue);
      await queueBox.put(operation.id, operation.toJson());
      _pendingOperationsCount.value = queueBox.length;

      print(
        '➕ Added pending operation: ${operation.operation.name} for ${operation.entityKey}',
      );

      // Try to process immediately if online
      if (_networkService.isConnected) {
        _scheduleSync(immediate: true);
      }
    } catch (e) {
      print('❌ Failed to add pending operation: $e');
    }
  }

  /// Get pending operations count
  int get pendingOperationsCount => _pendingOperationsCount.value;

  /// Check if sync is in progress
  bool get isSyncing => _syncInProgress.value;

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime.value;

  /// Get sync errors
  List<String> get syncErrors => _syncErrors.toList();

  /// Clear sync errors
  void clearSyncErrors() {
    _syncErrors.clear();
  }

  // Private implementation

  Future<SyncResult> _performFullSync() async {
    _syncInProgress.value = true;
    _syncErrors.clear();

    final stopwatch = Stopwatch()..start();
    int syncedItems = 0;
    int errors = 0;

    try {
      print('🔄 Starting full synchronization...');

      // Step 1: Process pending operations first
      final pendingResult = await _processPendingOperations();
      syncedItems += pendingResult.syncedCount;
      errors += pendingResult.errorCount;

      // Step 2: Sync each data type
      for (final boxType in _getDataBoxTypes()) {
        try {
          final result = await _syncBoxType(boxType);
          syncedItems += result.syncedCount;
          errors += result.errorCount;
        } catch (e) {
          print('❌ Failed to sync ${boxType.name}: $e');
          _syncErrors.add('${boxType.name}: $e');
          errors++;
        }
      }

      // Step 3: Update sync metadata
      await _updateSyncMetadata();

      stopwatch.stop();
      print(
        '✅ Full sync completed in ${stopwatch.elapsed.inSeconds}s: $syncedItems items, $errors errors',
      );

      return SyncResult.success(
        syncedCount: syncedItems,
        errorCount: errors,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      print('❌ Full sync failed: $e');
      _syncErrors.add('Full sync: $e');
      return SyncResult.error(e.toString());
    } finally {
      _syncInProgress.value = false;
    }
  }

  Future<SyncResult> _syncBoxType(BoxType boxType) async {
    try {
      final box = await _boxManager.ensureBox(boxType);
      int syncedCount = 0;

      // For now, basic sync - in production this would be more sophisticated
      // with delta sync, conflict resolution, etc.

      print('🔄 Syncing ${boxType.name}...');

      switch (boxType) {
        case BoxType.users:
          // Sync user profiles that need updates
          syncedCount += await _syncUserData();
          break;
        case BoxType.clinics:
          // Sync clinic information
          syncedCount += await _syncClinicData();
          break;
        case BoxType.transactions:
          // Sync financial transactions
          syncedCount += await _syncTransactionData();
          break;
        case BoxType.favorites:
          // Sync user favorites
          syncedCount += await _syncFavoritesData();
          break;
        default:
          // Skip system boxes
          break;
      }

      return SyncResult.success(syncedCount: syncedCount);
    } catch (e) {
      print('❌ Failed to sync ${boxType.name}: $e');
      return SyncResult.error('${boxType.name}: $e');
    }
  }

  Future<SyncResult> _processPendingOperations() async {
    try {
      final queueBox = await _boxManager.ensureBox(BoxType.operationQueue);
      final operations = <PendingOperation>[];

      // Load all pending operations
      for (final key in queueBox.keys) {
        final data = queueBox.get(key);
        if (data != null) {
          operations.add(PendingOperation.fromJson(data));
        }
      }

      if (operations.isEmpty) {
        return SyncResult.success();
      }

      print('🔄 Processing ${operations.length} pending operations...');

      int processed = 0;
      int errors = 0;

      // Process operations in batches
      for (int i = 0; i < operations.length; i += _batchSize) {
        final batch = operations.skip(i).take(_batchSize).toList();

        for (final operation in batch) {
          if (!operation.shouldRetry) {
            continue;
          }

          try {
            await _processOperation(operation);
            await queueBox.delete(operation.id);
            processed++;
          } catch (e) {
            print('❌ Failed to process operation ${operation.id}: $e');

            final updatedOperation = operation.withRetry(e.toString());
            if (updatedOperation.shouldRetry) {
              await queueBox.put(operation.id, updatedOperation.toJson());
            } else {
              // Max retries reached, remove from queue
              await queueBox.delete(operation.id);
              print(
                '⚠️ Operation ${operation.id} exceeded max retries, removing from queue',
              );
            }
            errors++;
          }
        }
      }

      _pendingOperationsCount.value = queueBox.length;

      return SyncResult.success(syncedCount: processed, errorCount: errors);
    } catch (e) {
      print('❌ Failed to process pending operations: $e');
      return SyncResult.error(e.toString());
    }
  }

  Future<void> _processOperation(PendingOperation operation) async {
    switch (operation.operation) {
      case CacheOperation.create:
        await _processCreateOperation(operation);
        break;
      case CacheOperation.update:
        await _processUpdateOperation(operation);
        break;
      case CacheOperation.delete:
        await _processDeleteOperation(operation);
        break;
      case CacheOperation.sync:
        await _processSyncOperation(operation);
        break;
    }
  }

  Future<void> _processCreateOperation(PendingOperation operation) async {
    final endpoint = _getEndpointForBoxType(operation.boxType);
    final response = await _dio.post(endpoint, data: operation.data);

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('✅ Created ${operation.entityKey} on server');
    } else {
      throw Exception('Server returned ${response.statusCode}');
    }
  }

  Future<void> _processUpdateOperation(PendingOperation operation) async {
    final endpoint = _getEndpointForBoxType(operation.boxType);
    final response = await _dio.put(
      '$endpoint/${operation.entityKey}',
      data: operation.data,
    );

    if (response.statusCode == 200) {
      print('✅ Updated ${operation.entityKey} on server');
    } else {
      throw Exception('Server returned ${response.statusCode}');
    }
  }

  Future<void> _processDeleteOperation(PendingOperation operation) async {
    final endpoint = _getEndpointForBoxType(operation.boxType);
    final response = await _dio.delete('$endpoint/${operation.entityKey}');

    if (response.statusCode == 200 || response.statusCode == 204) {
      print('✅ Deleted ${operation.entityKey} on server');
    } else {
      throw Exception('Server returned ${response.statusCode}');
    }
  }

  Future<void> _processSyncOperation(PendingOperation operation) async {
    // Custom sync operation - implementation depends on specific requirements
    print('🔄 Processing custom sync for ${operation.entityKey}');
  }

  // Data-specific sync methods

  Future<int> _syncUserData() async {
    // Implementation would fetch updated user data from server
    // and update local cache with conflict resolution
    return 0; // Placeholder
  }

  Future<int> _syncClinicData() async {
    // Implementation would fetch updated clinic data from server
    return 0; // Placeholder
  }

  Future<int> _syncTransactionData() async {
    // Implementation would fetch new transactions and update balances
    return 0; // Placeholder
  }

  Future<int> _syncFavoritesData() async {
    // Implementation would sync user favorites with server
    return 0; // Placeholder
  }

  // Helper methods

  List<BoxType> _getDataBoxTypes() {
    return [
      BoxType.users,
      BoxType.clinics,
      BoxType.plans,
      BoxType.userPlans,
      BoxType.transactions,
      BoxType.appointments,
      BoxType.favorites,
    ];
  }

  String _getEndpointForBoxType(BoxType boxType) {
    switch (boxType) {
      case BoxType.users:
        return '/api/users';
      case BoxType.clinics:
        return '/api/clinics';
      case BoxType.plans:
        return '/api/plans';
      case BoxType.userPlans:
        return '/api/user-plans';
      case BoxType.transactions:
        return '/api/transactions';
      case BoxType.appointments:
        return '/api/appointments';
      default:
        throw ArgumentError('No endpoint defined for ${boxType.name}');
    }
  }

  void _setupBackgroundSync() {
    _backgroundSyncTimer = Timer.periodic(_backgroundSyncInterval, (timer) {
      if (Get.find<NetworkService>().isConnected.value &&
          !_syncInProgress.value) {
        _scheduleSync(background: true);
      }
    });
  }

  void _scheduleSync({bool immediate = false, bool background = false}) {
    if (immediate) {
      Future.microtask(syncAll);
    } else {
      // Schedule for next available slot
      Future.delayed(Duration(seconds: background ? 30 : 5), () {
        if (!_syncInProgress.value) {
          syncAll();
        }
      });
    }
  }

  Future<void> _loadSyncMetadata() async {
    try {
      final metadataBox = await _boxManager.ensureBox(BoxType.metadata);
      final lastSyncString = metadataBox.get('last_sync_time');

      if (lastSyncString != null) {
        _lastSyncTime.value = DateTime.parse(lastSyncString);
      }
    } catch (e) {
      print('⚠️ Failed to load sync metadata: $e');
    }
  }

  Future<void> _updateSyncMetadata() async {
    try {
      final metadataBox = await _boxManager.ensureBox(BoxType.metadata);
      final now = DateTime.now();

      await metadataBox.put('last_sync_time', now.toIso8601String());
      _lastSyncTime.value = now;
    } catch (e) {
      print('⚠️ Failed to update sync metadata: $e');
    }
  }

  @override
  void onClose() {
    _backgroundSyncTimer?.cancel();
    _retryTimer?.cancel();
    super.onClose();
  }
}

/// Result of a synchronization operation
class SyncResult {
  SyncResult({
    required this.success,
    this.syncedCount = 0,
    this.errorCount = 0,
    this.errorMessage,
    this.duration,
  });

  factory SyncResult.success({
    int syncedCount = 0,
    int errorCount = 0,
    Duration? duration,
  }) {
    return SyncResult(
      success: true,
      syncedCount: syncedCount,
      errorCount: errorCount,
      duration: duration,
    );
  }

  factory SyncResult.error(String message) {
    return SyncResult(success: false, errorMessage: message, errorCount: 1);
  }

  factory SyncResult.noConnection() {
    return SyncResult(
      success: false,
      errorMessage: 'No network connection available',
    );
  }

  factory SyncResult.alreadyInProgress() {
    return SyncResult(success: false, errorMessage: 'Sync already in progress');
  }
  final bool success;
  final int syncedCount;
  final int errorCount;
  final String? errorMessage;
  final Duration? duration;

  @override
  String toString() {
    if (success) {
      return 'SyncResult(success: $syncedCount synced, $errorCount errors${duration != null ? ', ${duration!.inSeconds}s' : ''})';
    } else {
      return 'SyncResult(error: $errorMessage)';
    }
  }
}
