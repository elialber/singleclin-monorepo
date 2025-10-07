import 'dart:convert';

import 'package:dio/dio.dart';

/// Base repository providing offline-first functionality
///
/// This abstract class implements the Repository Pattern with transparent
/// caching, automatic sync, and offline support.
import 'package:meta/meta.dart';
import 'package:singleclin_mobile/core/services/cache_service.dart';
import 'package:singleclin_mobile/core/services/network_service.dart';

abstract class BaseRepository<T> {
  BaseRepository({
    required CacheService cacheService,
    required NetworkService networkService,
    required Dio dio,
  }) : cacheService = cacheService,
       networkService = networkService,
       dio = dio;
  @protected
  final CacheService cacheService;
  @protected
  final NetworkService networkService;
  @protected
  final Dio dio;

  /// Box name for Hive storage - must be implemented by subclasses
  String get boxName;

  /// Cache TTL in minutes - can be overridden by subclasses
  int get cacheTtlMinutes => 60;

  /// Whether this data should be available offline - can be overridden
  bool get isOfflineCapable => true;

  /// Serialize object to Map for storage
  Map<String, dynamic> toMap(T object);

  /// Deserialize Map back to object
  T fromMap(Map<String, dynamic> map);

  /// Generate cache key for specific item
  String getCacheKey(String identifier) => '${boxName}_$identifier';

  /// Get data with offline-first strategy
  Future<T?> get(
    String id, {
    bool forceRefresh = false,
    bool offlineOnly = false,
  }) async {
    final cacheKey = getCacheKey(id);

    if (offlineOnly || !networkService.isConnected) {
      final cached = await _getCachedData(cacheKey);
      if (cached != null) return cached;

      if (!isOfflineCapable) {
        throw NetworkException(
          'No internet connection and data not available offline',
        );
      }
      return null;
    }

    // Online strategy: cache first, then network if needed
    if (!forceRefresh) {
      final cached = await _getCachedData(cacheKey);
      if (cached != null && !_isCacheExpired(cacheKey)) {
        // Return cached data but try to refresh in background
        _refreshInBackground(id, cacheKey);
        return cached;
      }
    }

    // Fetch from network
    try {
      final data = await fetchFromNetwork(id);
      if (data != null) {
        await _cacheData(cacheKey, data);
        return data;
      }
    } catch (e) {
      // Network failed, fallback to cache if available
      final cached = await _getCachedData(cacheKey);
      if (cached != null) return cached;
      rethrow;
    }

    return null;
  }

  /// Get multiple items with offline-first strategy
  Future<List<T>> getMany({
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
    bool forceRefresh = false,
    bool offlineOnly = false,
  }) async {
    final cacheKey = _buildListCacheKey(filters, limit, offset);

    // Offline strategy
    if (offlineOnly || !networkService.isConnected) {
      final cached = await _getCachedList(cacheKey);
      if (cached.isNotEmpty) return cached;

      if (!isOfflineCapable) {
        throw NetworkException(
          'No internet connection and data not available offline',
        );
      }
      return [];
    }

    // Online strategy
    if (!forceRefresh) {
      final cached = await _getCachedList(cacheKey);
      if (cached.isNotEmpty && !_isCacheExpired(cacheKey)) {
        // Return cached but refresh in background
        _refreshListInBackground(filters, limit, offset, cacheKey);
        return cached;
      }
    }

    // Fetch from network
    try {
      final data = await fetchListFromNetwork(
        filters: filters,
        limit: limit,
        offset: offset,
      );
      await _cacheList(cacheKey, data);
      return data;
    } catch (e) {
      // Network failed, fallback to cache
      final cached = await _getCachedList(cacheKey);
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  /// Create/Update with offline queue support
  Future<T?> save(T object, String? id) async {
    if (!networkService.isConnected) {
      // Queue for later sync
      await _queueOperation('save', object, id);
      // Return optimistic result and cache locally
      if (id != null) {
        await _cacheData(getCacheKey(id), object);
      }
      return object;
    }

    try {
      final result = await saveToNetwork(object, id);
      if (result != null && id != null) {
        await _cacheData(getCacheKey(id), result);
      }
      return result;
    } catch (e) {
      // Queue for retry and return optimistic result
      await _queueOperation('save', object, id);
      return object;
    }
  }

  /// Delete with offline queue support
  Future<bool> delete(String id) async {
    if (!networkService.isConnected) {
      // Queue for later sync and remove from cache
      await _queueOperation('delete', null, id);
      await _removeCachedData(getCacheKey(id));
      return true;
    }

    try {
      final success = await deleteFromNetwork(id);
      if (success) {
        await _removeCachedData(getCacheKey(id));
      }
      return success;
    } catch (e) {
      // Queue for retry but don't remove from cache yet
      await _queueOperation('delete', null, id);
      rethrow;
    }
  }

  /// Force sync all cached data with server
  Future<void> syncAll() async {
    if (!networkService.isConnected) return;

    try {
      await _processPendingOperations();
      await _syncCachedData();
    } catch (e) {
      print('Sync failed: $e');
      rethrow;
    }
  }

  /// Clear all cached data for this repository
  Future<void> clearCache() async {
    await cacheService.clearBox(boxName);
  }

  /// Get cache health information for this repository
  Future<Map<String, dynamic>> getCacheInfo() async {
    final stats = await cacheService.getCacheStats(boxName);
    final lastAccessed = stats['lastAccessed'] != null
        ? DateTime.parse(stats['lastAccessed'])
        : null;
    final freshness = lastAccessed != null
        ? 1.0 -
              (DateTime.now().difference(lastAccessed).inHours / 24).clamp(
                0.0,
                1.0,
              )
        : 0.0;

    return {
      'size': stats['sizeBytes'],
      'itemCount': stats['itemCount'],
      'hitRate': 0.9, // Placeholder - implement proper tracking if needed
      'freshness': freshness,
    };
  }

  // Abstract methods to be implemented by subclasses
  Future<T?> fetchFromNetwork(String id);
  Future<List<T>> fetchListFromNetwork({
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  });
  Future<T?> saveToNetwork(T object, String? id);
  Future<bool> deleteFromNetwork(String id);

  // Private helper methods
  Future<T?> _getCachedData(String cacheKey) async {
    final data = await cacheService.get(boxName, cacheKey);
    return data != null ? fromMap(data) : null;
  }

  Future<List<T>> _getCachedList(String cacheKey) async {
    final data = await cacheService.getList(boxName, cacheKey);
    return data.map(fromMap).toList();
  }

  Future<void> _cacheData(String cacheKey, T data) async {
    await cacheService.put(boxName, cacheKey, toMap(data));
  }

  Future<void> _cacheList(String cacheKey, List<T> data) async {
    final mapped = data.map(toMap).toList();
    await cacheService.putList(boxName, cacheKey, mapped);
  }

  Future<void> _removeCachedData(String cacheKey) async {
    await cacheService.delete(boxName, cacheKey);
  }

  bool _isCacheExpired(String cacheKey) {
    final timestamp = cacheService.getTimestamp(boxName, cacheKey);
    if (timestamp == null) return true;

    final age = DateTime.now().difference(timestamp).inMinutes;
    return age > cacheTtlMinutes;
  }

  String _buildListCacheKey(
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  ) {
    final filtersStr = filters != null ? jsonEncode(filters) : '';
    return 'list_${filtersStr}_${limit ?? 'all'}_${offset ?? 0}';
  }

  void _refreshInBackground(String id, String cacheKey) {
    Future.microtask(() async {
      try {
        final data = await fetchFromNetwork(id);
        if (data != null) {
          await _cacheData(cacheKey, data);
        }
      } catch (e) {
        // Silent failure for background refresh
        print('Background refresh failed: $e');
      }
    });
  }

  void _refreshListInBackground(
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
    String cacheKey,
  ) {
    Future.microtask(() async {
      try {
        final data = await fetchListFromNetwork(
          filters: filters,
          limit: limit,
          offset: offset,
        );
        await _cacheList(cacheKey, data);
      } catch (e) {
        print('Background list refresh failed: $e');
      }
    });
  }

  Future<void> _queueOperation(String operation, T? data, String? id) async {
    final operationData = {
      'operation': operation,
      'boxName': boxName,
      'data': data != null ? toMap(data) : null,
      'id': id,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await cacheService.putToQueue('pending_operations', operationData);
  }

  Future<void> _processPendingOperations() async {
    final operations = await cacheService.getQueue('pending_operations');

    for (final operation in operations) {
      if (operation['boxName'] != boxName) continue;

      try {
        switch (operation['operation']) {
          case 'save':
            final data = fromMap(operation['data']);
            await saveToNetwork(data, operation['id']);
            break;
          case 'delete':
            await deleteFromNetwork(operation['id']);
            break;
        }

        // Remove from queue after successful processing
        await cacheService.removeFromQueue('pending_operations', operation);
      } catch (e) {
        print('Failed to process pending operation: $e');
        // Keep in queue for next sync attempt
      }
    }
  }

  Future<void> _syncCachedData() async {
    // This method can be overridden by subclasses for custom sync logic
    // Default implementation does nothing
  }
}

/// Exception thrown when network operations fail
class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when cache operations fail
class CacheException implements Exception {
  CacheException(this.message);
  final String message;

  @override
  String toString() => 'CacheException: $message';
}
