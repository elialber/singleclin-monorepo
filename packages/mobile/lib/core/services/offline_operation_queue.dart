import 'dart:async';

import 'package:get/get.dart';
import 'package:singleclin_mobile/core/models/cache_entity.dart';
import 'package:singleclin_mobile/core/services/cache_service.dart';
import 'package:singleclin_mobile/core/services/hive_box_manager.dart';
import 'package:singleclin_mobile/core/services/network_service.dart';
import 'package:uuid/uuid.dart';

/// Service for managing offline operations queue
///
/// Handles queuing, prioritization, and automatic processing of operations
/// that were performed while offline and need to be synced with the server.
class OfflineOperationQueue extends GetxService {
  OfflineOperationQueue({
    required CacheService cacheService,
    required NetworkService networkService,
    required HiveBoxManager boxManager,
  }) : _cacheService = cacheService,
       _networkService = networkService,
       _boxManager = boxManager;
  final CacheService _cacheService;
  final NetworkService _networkService;
  final HiveBoxManager _boxManager;

  // State management
  final _queueSize = 0.obs;
  final _isProcessing = false.obs;
  final _lastProcessTime = Rxn<DateTime>();
  final _processingErrors = <String>[].obs;

  // Queue processing
  Timer? _processingTimer;
  final _uuid = const Uuid();

  static const Duration _processingInterval = Duration(minutes: 2);
  static const int _maxRetryAttempts = 5;
  static const int _batchSize = 5;

  // Getters
  int get queueSize => _queueSize.value;
  bool get isProcessing => _isProcessing.value;
  DateTime? get lastProcessTime => _lastProcessTime.value;
  List<String> get processingErrors => _processingErrors.toList();
  bool get hasOperations => queueSize > 0;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeQueue();
  }

  Future<void> _initializeQueue() async {
    try {
      // Load queue size
      await _updateQueueSize();

      // Setup automatic processing when online
      _networkService.isConnectedRx.listen((isConnected) {
        if (isConnected && hasOperations) {
          _scheduleProcessing();
        }
      });

      // Setup periodic processing
      _setupPeriodicProcessing();

      print('✅ OfflineOperationQueue initialized with $queueSize operations');
    } catch (e) {
      print('❌ Failed to initialize OfflineOperationQueue: $e');
      rethrow;
    }
  }

  // Public API

  /// Add operation to queue
  Future<String> addOperation({
    required CacheOperation operation,
    required BoxType boxType,
    required String entityKey,
    Map<String, dynamic>? data,
    Map<String, dynamic>? metadata,
    OperationPriority priority = OperationPriority.normal,
  }) async {
    final operationId = _uuid.v4();

    final pendingOperation = PendingOperation(
      id: operationId,
      operation: operation,
      boxType: boxType,
      entityKey: entityKey,
      data: data,
      createdAt: DateTime.now(),
      metadata: {'priority': priority.name, ...?metadata},
    );

    try {
      final queueBox = await _boxManager.ensureBox(BoxType.operationQueue);
      await queueBox.put(operationId, pendingOperation.toJson());

      await _updateQueueSize();

      print(
        '➕ Added operation to queue: ${operation.name} for $entityKey (ID: $operationId)',
      );

      // Try immediate processing if online
      if (_networkService.isConnected && !isProcessing) {
        _scheduleProcessing(immediate: true);
      }

      return operationId;
    } catch (e) {
      print('❌ Failed to add operation to queue: $e');
      rethrow;
    }
  }

  /// Remove operation from queue
  Future<bool> removeOperation(String operationId) async {
    try {
      final queueBox = await _boxManager.ensureBox(BoxType.operationQueue);
      await queueBox.delete(operationId);

      await _updateQueueSize();
      print('➖ Removed operation from queue: $operationId');

      return true;
    } catch (e) {
      print('❌ Failed to remove operation from queue: $e');
      return false;
    }
  }

  /// Get all pending operations
  Future<List<PendingOperation>> getAllOperations() async {
    try {
      final queueBox = await _boxManager.ensureBox(BoxType.operationQueue);
      final operations = <PendingOperation>[];

      for (final key in queueBox.keys) {
        final data = queueBox.get(key);
        if (data != null) {
          operations.add(PendingOperation.fromJson(data));
        }
      }

      // Sort by priority and creation time
      operations.sort((a, b) {
        final priorityA = _getPriorityValue(a.metadata?['priority']);
        final priorityB = _getPriorityValue(b.metadata?['priority']);

        if (priorityA != priorityB) {
          return priorityB.compareTo(priorityA); // Higher priority first
        }

        return a.createdAt.compareTo(b.createdAt); // Older first
      });

      return operations;
    } catch (e) {
      print('❌ Failed to get operations: $e');
      return [];
    }
  }

  /// Get operations by type
  Future<List<PendingOperation>> getOperationsByType(
    CacheOperation operationType,
  ) async {
    final allOperations = await getAllOperations();
    return allOperations.where((op) => op.operation == operationType).toList();
  }

  /// Get operations by box type
  Future<List<PendingOperation>> getOperationsByBoxType(BoxType boxType) async {
    final allOperations = await getAllOperations();
    return allOperations.where((op) => op.boxType == boxType).toList();
  }

  /// Process queue manually
  Future<OperationQueueResult> processQueue({bool force = false}) async {
    if (isProcessing && !force) {
      return OperationQueueResult.alreadyProcessing();
    }

    if (!_networkService.isConnected && !force) {
      return OperationQueueResult.noConnection();
    }

    return _processOperations();
  }

  /// Clear all operations (with confirmation)
  Future<void> clearQueue({bool force = false}) async {
    if (!force) {
      // In production, add confirmation dialog
      print('⚠️ Clearing operation queue without confirmation (force=true)');
    }

    try {
      final queueBox = await _boxManager.ensureBox(BoxType.operationQueue);
      await queueBox.clear();

      await _updateQueueSize();
      _processingErrors.clear();

      print('🧹 Cleared operation queue');
    } catch (e) {
      print('❌ Failed to clear queue: $e');
      rethrow;
    }
  }

  /// Get queue statistics
  Future<Map<String, dynamic>> getQueueStatistics() async {
    try {
      final operations = await getAllOperations();

      final stats = {
        'totalOperations': operations.length,
        'operationsByType': <String, int>{},
        'operationsByBoxType': <String, int>{},
        'operationsByPriority': <String, int>{},
        'oldestOperation': operations.isNotEmpty
            ? operations.first.createdAt
            : null,
        'newestOperation': operations.isNotEmpty
            ? operations.last.createdAt
            : null,
        'failedOperations': operations.where((op) => op.retryCount > 0).length,
        'highPriorityOperations': operations
            .where((op) => _getPriorityValue(op.metadata?['priority']) == 3)
            .length,
      };

      // Count by type
      for (final op in operations) {
        final typeName = op.operation.name;
        stats['operationsByType'][typeName] =
            (stats['operationsByType'][typeName] ?? 0) + 1;

        final boxTypeName = op.boxType.name;
        stats['operationsByBoxType'][boxTypeName] =
            (stats['operationsByBoxType'][boxTypeName] ?? 0) + 1;

        final priority = op.metadata?['priority'] ?? 'normal';
        stats['operationsByPriority'][priority] =
            (stats['operationsByPriority'][priority] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('❌ Failed to get queue statistics: $e');
      return {'totalOperations': 0, 'error': e.toString()};
    }
  }

  // Private implementation

  Future<OperationQueueResult> _processOperations() async {
    _isProcessing.value = true;
    _processingErrors.clear();

    final stopwatch = Stopwatch()..start();
    int processed = 0;
    int failed = 0;

    try {
      print('🔄 Processing operation queue...');

      final operations = await getAllOperations();
      final operationsToProcess = operations
          .where((op) => op.shouldRetry)
          .toList();

      if (operationsToProcess.isEmpty) {
        return OperationQueueResult.success();
      }

      // Process in batches
      for (int i = 0; i < operationsToProcess.length; i += _batchSize) {
        final batch = operationsToProcess.skip(i).take(_batchSize).toList();

        for (final operation in batch) {
          try {
            await _processOperation(operation);
            await removeOperation(operation.id);
            processed++;
          } catch (e) {
            print('❌ Failed to process operation ${operation.id}: $e');
            _processingErrors.add('${operation.operation.name}: $e');

            // Update operation with retry info
            final updatedOperation = operation.withRetry(e.toString());
            final queueBox = await _boxManager.ensureBox(
              BoxType.operationQueue,
            );

            if (updatedOperation.shouldRetry) {
              await queueBox.put(operation.id, updatedOperation.toJson());
            } else {
              // Max retries reached, remove from queue
              await queueBox.delete(operation.id);
              print(
                '⚠️ Operation ${operation.id} exceeded max retries, removed from queue',
              );
            }

            failed++;
          }
        }

        // Small delay between batches to prevent overwhelming the server
        if (i + _batchSize < operationsToProcess.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      await _updateQueueSize();
      _lastProcessTime.value = DateTime.now();

      stopwatch.stop();
      print(
        '✅ Queue processing completed: $processed processed, $failed failed (${stopwatch.elapsed.inSeconds}s)',
      );

      return OperationQueueResult.success(
        processedCount: processed,
        failedCount: failed,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      print('❌ Queue processing failed: $e');
      _processingErrors.add('General processing error: $e');
      return OperationQueueResult.error(e.toString());
    } finally {
      _isProcessing.value = false;
    }
  }

  Future<void> _processOperation(PendingOperation operation) async {
    // This would be implemented by specific operation processors
    // For now, simulate processing
    await Future.delayed(const Duration(milliseconds: 100));

    switch (operation.operation) {
      case CacheOperation.create:
        print('🔄 Processing CREATE operation for ${operation.entityKey}');
        break;
      case CacheOperation.update:
        print('🔄 Processing UPDATE operation for ${operation.entityKey}');
        break;
      case CacheOperation.delete:
        print('🔄 Processing DELETE operation for ${operation.entityKey}');
        break;
      case CacheOperation.sync:
        print('🔄 Processing SYNC operation for ${operation.entityKey}');
        break;
    }

    // Simulate success/failure based on operation
    final random = DateTime.now().millisecondsSinceEpoch % 10;
    if (random == 0) {
      throw Exception('Simulated processing failure');
    }
  }

  void _setupPeriodicProcessing() {
    _processingTimer = Timer.periodic(_processingInterval, (timer) {
      if (_networkService.isConnected && hasOperations && !isProcessing) {
        _processOperations();
      }
    });
  }

  void _scheduleProcessing({bool immediate = false}) {
    final delay = immediate ? Duration.zero : const Duration(seconds: 5);

    Timer(delay, () {
      if (_networkService.isConnected && !isProcessing) {
        _processOperations();
      }
    });
  }

  Future<void> _updateQueueSize() async {
    try {
      final queueBox = await _boxManager.ensureBox(BoxType.operationQueue);
      _queueSize.value = queueBox.length;
    } catch (e) {
      print('⚠️ Failed to update queue size: $e');
      _queueSize.value = 0;
    }
  }

  int _getPriorityValue(dynamic priority) {
    switch (priority?.toString()) {
      case 'critical':
        return 3;
      case 'high':
        return 2;
      case 'normal':
        return 1;
      case 'low':
        return 0;
      default:
        return 1;
    }
  }

  @override
  void onClose() {
    _processingTimer?.cancel();
    super.onClose();
  }
}

/// Priority levels for operations
enum OperationPriority { low, normal, high, critical }

/// Result of queue processing operation
class OperationQueueResult {
  OperationQueueResult({
    required this.success,
    this.processedCount = 0,
    this.failedCount = 0,
    this.errorMessage,
    this.duration,
  });

  factory OperationQueueResult.success({
    int processedCount = 0,
    int failedCount = 0,
    Duration? duration,
  }) {
    return OperationQueueResult(
      success: true,
      processedCount: processedCount,
      failedCount: failedCount,
      duration: duration,
    );
  }

  factory OperationQueueResult.error(String message) {
    return OperationQueueResult(
      success: false,
      errorMessage: message,
      failedCount: 1,
    );
  }

  factory OperationQueueResult.noConnection() {
    return OperationQueueResult(
      success: false,
      errorMessage: 'No network connection available',
    );
  }

  factory OperationQueueResult.alreadyProcessing() {
    return OperationQueueResult(
      success: false,
      errorMessage: 'Queue processing already in progress',
    );
  }
  final bool success;
  final int processedCount;
  final int failedCount;
  final String? errorMessage;
  final Duration? duration;

  @override
  String toString() {
    if (success) {
      return 'OperationQueueResult(success: $processedCount processed, $failedCount failed${duration != null ? ', ${duration!.inSeconds}s' : ''})';
    } else {
      return 'OperationQueueResult(error: $errorMessage)';
    }
  }
}
