import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/data/models/transaction_model.dart';
import 'package:mobile/data/models/user_plan_model.dart';
import 'package:mobile/domain/entities/transaction_entity.dart';
import 'package:mobile/domain/entities/user_plan_entity.dart';

/// Local cache service for storing plan and transaction data
///
/// This service provides caching functionality to:
/// - Store user plan data locally for offline access
/// - Cache recent transactions
/// - Manage cache expiration and refresh
/// - Provide fallback data when API is unavailable
class CacheService {
  CacheService._();
  static const String _planCacheKey = 'cached_user_plan';
  static const String _planCacheTimeKey = 'cached_user_plan_time';
  static const String _transactionsCacheKey = 'cached_recent_transactions';
  static const String _transactionsCacheTimeKey =
      'cached_recent_transactions_time';

  // Cache expiration time in minutes
  static const int _planCacheExpirationMinutes = 30; // 30 minutes
  static const int _transactionsCacheExpirationMinutes = 15; // 15 minutes

  static CacheService? _instance;
  static CacheService get instance => _instance ??= CacheService._();

  SharedPreferences? _prefs;

  /// Initialize cache service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure preferences are initialized
  Future<SharedPreferences> get _preferences async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // Plan Data Caching

  /// Cache user plan data
  Future<void> cachePlan(UserPlanEntity plan) async {
    try {
      final prefs = await _preferences;
      final planModel = UserPlanModel.fromEntity(plan);
      final planJson = json.encode(planModel.toJson());
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString(_planCacheKey, planJson);
      await prefs.setInt(_planCacheTimeKey, currentTime);
    } catch (e) {
      // Silently fail cache operations to not affect app functionality
      print('🗂️ Cache: Failed to cache plan data: $e');
    }
  }

  /// Get cached user plan data
  Future<UserPlanEntity?> getCachedPlan() async {
    try {
      final prefs = await _preferences;
      final planJson = prefs.getString(_planCacheKey);
      final cacheTime = prefs.getInt(_planCacheTimeKey);

      if (planJson == null || cacheTime == null) {
        return null;
      }

      // Check if cache is expired
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final cacheAge = currentTime - cacheTime;
      const cacheExpirationTime = _planCacheExpirationMinutes * 60 * 1000;

      if (cacheAge > cacheExpirationTime) {
        // Cache expired, remove it
        await clearPlanCache();
        return null;
      }

      final planData = json.decode(planJson) as Map<String, dynamic>;
      final planModel = UserPlanModel.fromJson(planData);
      return planModel.toEntity();
    } catch (e) {
      print('🗂️ Cache: Failed to get cached plan data: $e');
      return null;
    }
  }

  /// Check if plan cache is valid (not expired)
  Future<bool> isPlanCacheValid() async {
    try {
      final prefs = await _preferences;
      final cacheTime = prefs.getInt(_planCacheTimeKey);

      if (cacheTime == null) {
        return false;
      }

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final cacheAge = currentTime - cacheTime;
      const cacheExpirationTime = _planCacheExpirationMinutes * 60 * 1000;

      return cacheAge <= cacheExpirationTime;
    } catch (e) {
      return false;
    }
  }

  /// Clear cached plan data
  Future<void> clearPlanCache() async {
    try {
      final prefs = await _preferences;
      await prefs.remove(_planCacheKey);
      await prefs.remove(_planCacheTimeKey);
    } catch (e) {
      print('🗂️ Cache: Failed to clear plan cache: $e');
    }
  }

  // Transaction Data Caching

  /// Cache recent transactions data
  Future<void> cacheRecentTransactions(
    List<TransactionEntity> transactions,
  ) async {
    try {
      final prefs = await _preferences;
      final transactionModels = transactions
          .map(TransactionModel.fromEntity)
          .toList();
      final transactionsJson = json.encode(
        transactionModels.map((model) => model.toJson()).toList(),
      );
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString(_transactionsCacheKey, transactionsJson);
      await prefs.setInt(_transactionsCacheTimeKey, currentTime);
    } catch (e) {
      print('🗂️ Cache: Failed to cache transactions data: $e');
    }
  }

  /// Get cached recent transactions
  Future<List<TransactionEntity>> getCachedRecentTransactions() async {
    try {
      final prefs = await _preferences;
      final transactionsJson = prefs.getString(_transactionsCacheKey);
      final cacheTime = prefs.getInt(_transactionsCacheTimeKey);

      if (transactionsJson == null || cacheTime == null) {
        return [];
      }

      // Check if cache is expired
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final cacheAge = currentTime - cacheTime;
      const cacheExpirationTime =
          _transactionsCacheExpirationMinutes * 60 * 1000;

      if (cacheAge > cacheExpirationTime) {
        // Cache expired, remove it
        await clearTransactionsCache();
        return [];
      }

      final transactionsData = json.decode(transactionsJson) as List<dynamic>;
      return transactionsData
          .map(
            (data) => TransactionModel.fromJson(
              data as Map<String, dynamic>,
            ).toEntity(),
          )
          .toList();
    } catch (e) {
      print('🗂️ Cache: Failed to get cached transactions data: $e');
      return [];
    }
  }

  /// Check if transactions cache is valid (not expired)
  Future<bool> isTransactionsCacheValid() async {
    try {
      final prefs = await _preferences;
      final cacheTime = prefs.getInt(_transactionsCacheTimeKey);

      if (cacheTime == null) {
        return false;
      }

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final cacheAge = currentTime - cacheTime;
      const cacheExpirationTime =
          _transactionsCacheExpirationMinutes * 60 * 1000;

      return cacheAge <= cacheExpirationTime;
    } catch (e) {
      return false;
    }
  }

  /// Clear cached transactions data
  Future<void> clearTransactionsCache() async {
    try {
      final prefs = await _preferences;
      await prefs.remove(_transactionsCacheKey);
      await prefs.remove(_transactionsCacheTimeKey);
    } catch (e) {
      print('🗂️ Cache: Failed to clear transactions cache: $e');
    }
  }

  // Cache Management

  /// Clear all cached data
  Future<void> clearAllCache() async {
    await clearPlanCache();
    await clearTransactionsCache();
  }

  /// Get cache information for debugging
  Future<Map<String, dynamic>> getCacheInfo() async {
    final prefs = await _preferences;
    final planCacheTime = prefs.getInt(_planCacheTimeKey);
    final transactionsCacheTime = prefs.getInt(_transactionsCacheTimeKey);

    return {
      'plan_cache_valid': await isPlanCacheValid(),
      'plan_cache_time': planCacheTime != null
          ? DateTime.fromMillisecondsSinceEpoch(planCacheTime).toIso8601String()
          : null,
      'transactions_cache_valid': await isTransactionsCacheValid(),
      'transactions_cache_time': transactionsCacheTime != null
          ? DateTime.fromMillisecondsSinceEpoch(
              transactionsCacheTime,
            ).toIso8601String()
          : null,
    };
  }

  /// Force cache refresh (clear all cache to force fresh data fetch)
  Future<void> forceCacheRefresh() async {
    await clearAllCache();
  }
}
