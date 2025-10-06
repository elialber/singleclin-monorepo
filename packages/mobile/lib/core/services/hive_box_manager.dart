import 'dart:io';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:singleclin_mobile/core/models/cache_entity.dart';

/// Centralized manager for Hive boxes organized by entity types
///
/// Manages box lifecycle, initialization, and provides organized access
/// to different data entity boxes with proper typing and serialization.
class HiveBoxManager extends GetxService {
  // Box instances organized by entity type
  final Map<BoxType, Box<dynamic>> _boxes = {};
  final Map<BoxType, bool> _boxInitialized = {};

  // Box configuration
  static const Map<BoxType, String> _boxNames = {
    BoxType.users: 'users_box',
    BoxType.clinics: 'clinics_box',
    BoxType.plans: 'plans_box',
    BoxType.userPlans: 'user_plans_box',
    BoxType.transactions: 'transactions_box',
    BoxType.qrCodes: 'qr_codes_box',
    BoxType.appointments: 'appointments_box',
    BoxType.creditHistory: 'credit_history_box',
    BoxType.favorites: 'favorites_box',
    BoxType.searchCache: 'search_cache_box',
    BoxType.metadata: 'cache_metadata_box',
    BoxType.operationQueue: 'operation_queue_box',
    BoxType.preferences: 'preferences_box',
  };

  // Box size limits (in KB)
  static const Map<BoxType, int> _boxSizeLimits = {
    BoxType.users: 5000, // 5MB
    BoxType.clinics: 10000, // 10MB
    BoxType.plans: 2000, // 2MB
    BoxType.userPlans: 3000, // 3MB
    BoxType.transactions: 8000, // 8MB
    BoxType.qrCodes: 1000, // 1MB
    BoxType.appointments: 5000, // 5MB
    BoxType.creditHistory: 8000, // 8MB
    BoxType.favorites: 1000, // 1MB
    BoxType.searchCache: 5000, // 5MB
    BoxType.metadata: 1000, // 1MB
    BoxType.operationQueue: 2000, // 2MB
    BoxType.preferences: 500, // 500KB
  };

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeHive();
  }

  Future<void> _initializeHive() async {
    try {
      // Initialize Hive if not already done
      if (!Hive.isInitialized) {
        await Hive.initFlutter();
      }

      // Initialize essential boxes first
      await _initializeBox(BoxType.metadata);
      await _initializeBox(BoxType.operationQueue);
      await _initializeBox(BoxType.preferences);

      // Initialize user-related boxes
      await _initializeBox(BoxType.users);
      await _initializeBox(BoxType.userPlans);

      // Initialize core data boxes
      await _initializeBox(BoxType.clinics);
      await _initializeBox(BoxType.plans);
      await _initializeBox(BoxType.transactions);

      // Initialize secondary boxes (can be lazy-loaded)
      await _initializeBox(BoxType.favorites);
      await _initializeBox(BoxType.searchCache);

      print('✅ HiveBoxManager initialized with ${_boxes.length} boxes');
      await _performMaintenanceTasks();
    } catch (e) {
      print('❌ HiveBoxManager initialization failed: $e');
      rethrow;
    }
  }

  Future<void> _initializeBox(BoxType boxType) async {
    try {
      final boxName = _boxNames[boxType]!;

      // Check if already initialized
      if (_boxInitialized[boxType] ?? false) {
        return;
      }

      Box<dynamic> box;

      // Try to open existing box, create if doesn't exist
      try {
        box = await Hive.openBox(boxName);
      } catch (e) {
        // Box might be corrupted, delete and recreate
        print('⚠️ Box $boxName corrupted, recreating: $e');
        await _deleteCorruptedBox(boxName);
        box = await Hive.openBox(boxName);
      }

      _boxes[boxType] = box;
      _boxInitialized[boxType] = true;

      // Perform box-specific initialization
      await _initializeBoxData(boxType, box);

      print('📦 Initialized box: $boxName (${box.length} items)');
    } catch (e) {
      print('❌ Failed to initialize box ${boxType.name}: $e');
      _boxInitialized[boxType] = false;
      rethrow;
    }
  }

  Future<void> _initializeBoxData(BoxType boxType, Box box) async {
    switch (boxType) {
      case BoxType.metadata:
        // Ensure metadata structure exists
        if (!box.containsKey('cache_version')) {
          await box.put('cache_version', '1.0.0');
        }
        if (!box.containsKey('last_cleanup')) {
          await box.put('last_cleanup', DateTime.now().toIso8601String());
        }
        break;

      case BoxType.preferences:
        // Initialize default preferences if not exist
        if (!box.containsKey('default_preferences')) {
          await box.put('default_preferences', {
            'offline_mode': false,
            'auto_sync': true,
            'wifi_only_sync': true,
          });
        }
        break;

      default:
        // No special initialization needed for other boxes
        break;
    }
  }

  /// Get a box instance by type
  Box<dynamic>? getBox(BoxType boxType) {
    if (!_boxInitialized.containsKey(boxType) ||
        _boxInitialized[boxType] != true) {
      print('⚠️ Box ${boxType.name} not initialized, lazy loading...');
      // Trigger lazy initialization
      Future.microtask(() => _initializeBox(boxType));
      return null;
    }
    return _boxes[boxType];
  }

  /// Ensure a box is initialized (lazy loading)
  Future<Box<dynamic>> ensureBox(BoxType boxType) async {
    if (!_boxInitialized.containsKey(boxType) ||
        _boxInitialized[boxType] != true) {
      await _initializeBox(boxType);
    }
    return _boxes[boxType]!;
  }

  /// Check if a box is initialized
  bool isBoxInitialized(BoxType boxType) {
    return _boxInitialized[boxType] ?? false;
  }

  /// Get box statistics
  Future<Map<String, dynamic>> getBoxStats(BoxType boxType) async {
    final box = await ensureBox(boxType);
    final sizeLimit = _boxSizeLimits[boxType] ?? 1000;

    // Calculate approximate size
    int approximateSize = 0;
    for (final value in box.values) {
      approximateSize += value.toString().length;
    }

    final sizeKB = (approximateSize / 1024).round();
    final usagePercent = ((sizeKB / sizeLimit) * 100).round();

    return {
      'boxName': _boxNames[boxType],
      'itemCount': box.length,
      'sizeKB': sizeKB,
      'sizeLimitKB': sizeLimit,
      'usagePercent': usagePercent,
      'isNearLimit': usagePercent > 80,
      'lastModified': _getBoxLastModified(boxType),
    };
  }

  /// Get statistics for all boxes
  Future<Map<BoxType, Map<String, dynamic>>> getAllBoxStats() async {
    final stats = <BoxType, Map<String, dynamic>>{};

    for (final boxType in BoxType.values) {
      if (isBoxInitialized(boxType)) {
        stats[boxType] = await getBoxStats(boxType);
      }
    }

    return stats;
  }

  /// Clear a specific box
  Future<void> clearBox(BoxType boxType) async {
    final box = await ensureBox(boxType);
    await box.clear();
    print('🧹 Cleared box: ${_boxNames[boxType]}');
  }

  /// Clear all boxes
  Future<void> clearAllBoxes() async {
    for (final boxType in BoxType.values) {
      if (isBoxInitialized(boxType)) {
        await clearBox(boxType);
      }
    }
    print('🧹 Cleared all boxes');
  }

  /// Compact a box (remove deleted entries)
  Future<void> compactBox(BoxType boxType) async {
    final box = await ensureBox(boxType);
    await box.compact();
    print('📦 Compacted box: ${_boxNames[boxType]}');
  }

  /// Compact all boxes
  Future<void> compactAllBoxes() async {
    for (final boxType in BoxType.values) {
      if (isBoxInitialized(boxType)) {
        await compactBox(boxType);
      }
    }
    print('📦 Compacted all boxes');
  }

  /// Perform maintenance tasks
  Future<void> performMaintenance() async {
    await _performMaintenanceTasks();
  }

  Future<void> _performMaintenanceTasks() async {
    try {
      // Check if maintenance is needed
      final metadataBox = getBox(BoxType.metadata);
      if (metadataBox == null) return;

      final lastCleanup = metadataBox.get('last_cleanup');
      final lastCleanupDate = lastCleanup != null
          ? DateTime.parse(lastCleanup)
          : DateTime(2000);

      // Perform maintenance every 24 hours
      if (DateTime.now().difference(lastCleanupDate).inHours >= 24) {
        print('🔧 Performing Hive maintenance...');

        // Clean up oversized boxes
        await _cleanupOversizedBoxes();

        // Compact boxes if needed
        await _compactBoxesIfNeeded();

        // Update last cleanup timestamp
        await metadataBox.put('last_cleanup', DateTime.now().toIso8601String());

        print('✅ Hive maintenance completed');
      }
    } catch (e) {
      print('❌ Hive maintenance failed: $e');
    }
  }

  Future<void> _cleanupOversizedBoxes() async {
    for (final boxType in BoxType.values) {
      if (!isBoxInitialized(boxType)) continue;

      final stats = await getBoxStats(boxType);
      if (stats['usagePercent'] > 80) {
        print(
          '⚠️ Box ${stats['boxName']} is ${stats['usagePercent']}% full, cleaning up...',
        );
        await _cleanupBoxByAge(boxType);
      }
    }
  }

  Future<void> _cleanupBoxByAge(BoxType boxType) async {
    final box = await ensureBox(boxType);
    final metadataBox = await ensureBox(BoxType.metadata);

    // Get all items with timestamps
    final itemsWithAge = <String, DateTime>{};
    for (final key in box.keys) {
      final timestamp = metadataBox.get(
        '${_boxNames[boxType]}_${key}_timestamp',
      );
      if (timestamp != null) {
        itemsWithAge[key.toString()] = DateTime.parse(timestamp);
      }
    }

    // Sort by age (oldest first)
    final sortedItems = itemsWithAge.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Remove oldest 25% of items
    final itemsToRemove = sortedItems.take((sortedItems.length * 0.25).round());

    for (final item in itemsToRemove) {
      await box.delete(item.key);
      // Clean up metadata
      await metadataBox.delete('${_boxNames[boxType]}_${item.key}_timestamp');
    }

    print(
      '🧹 Cleaned up ${itemsToRemove.length} old items from ${_boxNames[boxType]}',
    );
  }

  Future<void> _compactBoxesIfNeeded() async {
    for (final boxType in BoxType.values) {
      if (!isBoxInitialized(boxType)) continue;

      final box = getBox(boxType)!;
      // Compact if box has many deleted entries (heuristic: more than 20% deleted)
      if (box.keys.length < box.length * 0.8) {
        await compactBox(boxType);
      }
    }
  }

  Future<void> _deleteCorruptedBox(String boxName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final boxFile = File('${directory.path}/$boxName.hive');
      if (await boxFile.exists()) {
        await boxFile.delete();
      }
    } catch (e) {
      print('⚠️ Could not delete corrupted box file: $e');
    }
  }

  String? _getBoxLastModified(BoxType boxType) {
    final metadataBox = getBox(BoxType.metadata);
    if (metadataBox == null) return null;

    return metadataBox.get('${_boxNames[boxType]}_last_modified');
  }

  /// Export box data for backup
  Future<Map<String, dynamic>> exportBoxData(BoxType boxType) async {
    final box = await ensureBox(boxType);
    final data = <String, dynamic>{};

    for (final key in box.keys) {
      data[key.toString()] = box.get(key);
    }

    return {
      'boxType': boxType.name,
      'boxName': _boxNames[boxType],
      'exportedAt': DateTime.now().toIso8601String(),
      'itemCount': data.length,
      'data': data,
    };
  }

  /// Import box data from backup
  Future<void> importBoxData(
    BoxType boxType,
    Map<String, dynamic> backupData,
  ) async {
    final box = await ensureBox(boxType);

    if (backupData['boxType'] != boxType.name) {
      throw ArgumentError(
        'Backup data is for ${backupData['boxType']}, not ${boxType.name}',
      );
    }

    final data = backupData['data'] as Map<String, dynamic>;
    for (final entry in data.entries) {
      await box.put(entry.key, entry.value);
    }

    print('📥 Imported ${data.length} items to ${_boxNames[boxType]}');
  }

  @override
  void onClose() {
    // Close all boxes
    for (final box in _boxes.values) {
      box.close();
    }
    _boxes.clear();
    _boxInitialized.clear();
    super.onClose();
  }
}
