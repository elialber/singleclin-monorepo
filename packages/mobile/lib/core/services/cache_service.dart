import 'dart:convert';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service for managing offline cache using Hive
///
/// Provides organized storage with TTL, timestamps, and queue management
/// for offline-first functionality.
class CacheService extends GetxService {
  static const String _metadataBoxName = 'cache_metadata';
  static const String _queueBoxName = 'operation_queue';

  final Map<String, Box<dynamic>> _boxes = {};
  late Box<dynamic> _metadataBox;
  late Box<dynamic> _queueBox;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeHive();
  }

  Future<void> _initializeHive() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Open metadata box for timestamps and cache info
    _metadataBox = await Hive.openBox(_metadataBoxName);

    // Open queue box for pending operations
    _queueBox = await Hive.openBox(_queueBoxName);

    print('✅ CacheService initialized successfully');
  }

  /// Get or create a box for specific entity type
  Future<Box<dynamic>> _getBox(String boxName) async {
    if (_boxes.containsKey(boxName)) {
      return _boxes[boxName]!;
    }

    final box = await Hive.openBox(boxName);
    _boxes[boxName] = box;
    return box;
  }

  /// Store single item in cache
  Future<void> put(
    String boxName,
    String key,
    Map<String, dynamic> data,
  ) async {
    try {
      final box = await _getBox(boxName);

      // Store data
      await box.put(key, data);

      // Store metadata (timestamp, size, etc.)
      await _storeMetadata(boxName, key, data);
    } catch (e) {
      print('❌ Cache put failed for $boxName:$key - $e');
      throw CacheException('Failed to cache data: $e');
    }
  }

  /// Get single item from cache
  Future<Map<String, dynamic>?> get(String boxName, String key) async {
    try {
      final box = await _getBox(boxName);
      final data = box.get(key);

      if (data == null) return null;

      // Update last accessed timestamp
      await _updateLastAccessed(boxName, key);

      return Map<String, dynamic>.from(data);
    } catch (e) {
      print('❌ Cache get failed for $boxName:$key - $e');
      return null;
    }
  }

  /// Store list of items in cache
  Future<void> putList(
    String boxName,
    String key,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      final box = await _getBox(boxName);

      // Store as JSON string to maintain structure
      final jsonString = jsonEncode(data);
      await box.put(key, jsonString);

      // Store metadata
      await _storeListMetadata(boxName, key, data.length);
    } catch (e) {
      print('❌ Cache putList failed for $boxName:$key - $e');
      throw CacheException('Failed to cache list: $e');
    }
  }

  /// Get list of items from cache
  Future<List<Map<String, dynamic>>> getList(String boxName, String key) async {
    try {
      final box = await _getBox(boxName);
      final data = box.get(key);

      if (data == null) return [];

      // Parse JSON string back to list
      final List<dynamic> parsed = jsonDecode(data as String);

      // Update last accessed timestamp
      await _updateLastAccessed(boxName, key);

      return parsed.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('❌ Cache getList failed for $boxName:$key - $e');
      return [];
    }
  }

  /// Delete specific item from cache
  Future<void> delete(String boxName, String key) async {
    try {
      final box = await _getBox(boxName);
      await box.delete(key);

      // Clean up metadata
      await _deleteMetadata(boxName, key);
    } catch (e) {
      print('❌ Cache delete failed for $boxName:$key - $e');
    }
  }

  /// Clear entire box (all items of a type)
  Future<void> clearBox(String boxName) async {
    try {
      final box = await _getBox(boxName);
      await box.clear();

      // Clear related metadata
      await _clearBoxMetadata(boxName);

      print('🧹 Cleared cache box: $boxName');
    } catch (e) {
      print('❌ Cache clearBox failed for $boxName - $e');
    }
  }

  /// Get timestamp when item was cached
  DateTime? getTimestamp(String boxName, String key) {
    final metadataKey = '${boxName}_${key}_timestamp';
    final timestamp = _metadataBox.get(metadataKey);

    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  /// Check if cache key exists
  Future<bool> containsKey(String boxName, String key) async {
    final box = await _getBox(boxName);
    return box.containsKey(key);
  }

  /// Get all keys in a box
  Future<List<String>> getKeys(String boxName) async {
    final box = await _getBox(boxName);
    return box.keys.cast<String>().toList();
  }

  /// Get cache size in bytes (approximate)
  Future<int> getCacheSize(String boxName) async {
    try {
      final box = await _getBox(boxName);
      int totalSize = 0;

      for (final value in box.values) {
        // Approximate size calculation
        final size = jsonEncode(value).length;
        totalSize += size;
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats(String boxName) async {
    final box = await _getBox(boxName);
    final size = await getCacheSize(boxName);

    return {
      'boxName': boxName,
      'itemCount': box.length,
      'sizeBytes': size,
      'sizeMB': (size / 1024 / 1024).toStringAsFixed(2),
      'lastAccessed': _getLastAccessed(boxName),
    };
  }

  /// Clean up expired cache items
  Future<void> cleanupExpired({int maxAgeMinutes = 1440}) async {
    // Default 24 hours
    try {
      final cutoffTime = DateTime.now().subtract(
        Duration(minutes: maxAgeMinutes),
      );
      final keysToDelete = <String>[];

      // Check all metadata entries for expired items
      for (final key in _metadataBox.keys) {
        if (key.toString().endsWith('_timestamp')) {
          final timestamp = DateTime.parse(_metadataBox.get(key));
          if (timestamp.isBefore(cutoffTime)) {
            // Extract original key
            final originalKey = key.toString().replaceAll('_timestamp', '');
            keysToDelete.add(originalKey);
          }
        }
      }

      // Delete expired items from their respective boxes
      for (final keyPath in keysToDelete) {
        final parts = keyPath.split('_');
        if (parts.length >= 2) {
          final boxName = parts[0];
          final itemKey = parts.sublist(1).join('_');
          await delete(boxName, itemKey);
        }
      }

      if (keysToDelete.isNotEmpty) {
        print('🧹 Cleaned up ${keysToDelete.length} expired cache items');
      }
    } catch (e) {
      print('❌ Cache cleanup failed: $e');
    }
  }

  /// Queue operations for offline sync
  Future<void> putToQueue(
    String queueName,
    Map<String, dynamic> operation,
  ) async {
    try {
      final queueKey = '${queueName}_${DateTime.now().millisecondsSinceEpoch}';
      await _queueBox.put(queueKey, operation);
    } catch (e) {
      print('❌ Failed to queue operation: $e');
    }
  }

  /// Get all operations from queue
  Future<List<Map<String, dynamic>>> getQueue(String queueName) async {
    try {
      final operations = <Map<String, dynamic>>[];

      for (final key in _queueBox.keys) {
        if (key.toString().startsWith(queueName)) {
          final data = _queueBox.get(key);
          if (data != null) {
            operations.add({
              ...Map<String, dynamic>.from(data),
              '_queueKey': key,
            });
          }
        }
      }

      return operations;
    } catch (e) {
      print('❌ Failed to get queue: $e');
      return [];
    }
  }

  /// Remove specific operation from queue
  Future<void> removeFromQueue(
    String queueName,
    Map<String, dynamic> operation,
  ) async {
    try {
      final queueKey = operation['_queueKey'];
      if (queueKey != null) {
        await _queueBox.delete(queueKey);
      }
    } catch (e) {
      print('❌ Failed to remove from queue: $e');
    }
  }

  /// Clear entire queue
  Future<void> clearQueue(String queueName) async {
    try {
      final keysToDelete = <dynamic>[];

      for (final key in _queueBox.keys) {
        if (key.toString().startsWith(queueName)) {
          keysToDelete.add(key);
        }
      }

      for (final key in keysToDelete) {
        await _queueBox.delete(key);
      }

      print('🧹 Cleared queue: $queueName');
    } catch (e) {
      print('❌ Failed to clear queue: $e');
    }
  }

  // Private helper methods
  Future<void> _storeMetadata(
    String boxName,
    String key,
    Map<String, dynamic> data,
  ) async {
    final now = DateTime.now();
    final metadataKey = '${boxName}_$key';

    await _metadataBox.put('${metadataKey}_timestamp', now.toIso8601String());
    await _metadataBox.put('${metadataKey}_size', jsonEncode(data).length);
    await _metadataBox.put('${metadataKey}_accessed', now.toIso8601String());
  }

  Future<void> _storeListMetadata(
    String boxName,
    String key,
    int itemCount,
  ) async {
    final now = DateTime.now();
    final metadataKey = '${boxName}_$key';

    await _metadataBox.put('${metadataKey}_timestamp', now.toIso8601String());
    await _metadataBox.put('${metadataKey}_count', itemCount);
    await _metadataBox.put('${metadataKey}_accessed', now.toIso8601String());
  }

  Future<void> _updateLastAccessed(String boxName, String key) async {
    final metadataKey = '${boxName}_${key}_accessed';
    await _metadataBox.put(metadataKey, DateTime.now().toIso8601String());
  }

  Future<void> _deleteMetadata(String boxName, String key) async {
    final metadataKey = '${boxName}_$key';
    await _metadataBox.delete('${metadataKey}_timestamp');
    await _metadataBox.delete('${metadataKey}_size');
    await _metadataBox.delete('${metadataKey}_count');
    await _metadataBox.delete('${metadataKey}_accessed');
  }

  Future<void> _clearBoxMetadata(String boxName) async {
    final keysToDelete = <dynamic>[];

    for (final key in _metadataBox.keys) {
      if (key.toString().startsWith(boxName)) {
        keysToDelete.add(key);
      }
    }

    for (final key in keysToDelete) {
      await _metadataBox.delete(key);
    }
  }

  String? _getLastAccessed(String boxName) {
    // Get the most recent access timestamp for any item in the box
    DateTime? latest;

    for (final key in _metadataBox.keys) {
      if (key.toString().startsWith(boxName) &&
          key.toString().endsWith('_accessed')) {
        final timestamp = DateTime.parse(_metadataBox.get(key));
        if (latest == null || timestamp.isAfter(latest)) {
          latest = timestamp;
        }
      }
    }

    return latest?.toIso8601String();
  }

  @override
  void onClose() {
    // Close all open boxes
    for (final box in _boxes.values) {
      box.close();
    }
    _metadataBox.close();
    _queueBox.close();
    super.onClose();
  }
}

/// Exception thrown when cache operations fail
class CacheException implements Exception {
  CacheException(this.message);
  final String message;

  @override
  String toString() => 'CacheException: $message';
}
