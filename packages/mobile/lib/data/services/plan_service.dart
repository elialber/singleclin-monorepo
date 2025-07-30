import '../../domain/entities/user_plan_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/plan_repository.dart';
import '../repositories/plan_repository_impl.dart';
import 'cache_service.dart';

/// Service class to wrap PlanRepository for dependency injection
/// 
/// This service acts as a single source of truth for plan-related
/// operations across the app, providing a clean interface for
/// the presentation layer to interact with plan data.
class PlanService {
  final PlanRepository _planRepository;
  final CacheService _cacheService = CacheService.instance;

  PlanService({PlanRepository? planRepository})
      : _planRepository = planRepository ?? PlanRepositoryImpl();

  /// Get current active plan for the authenticated user
  /// Uses cached data if available and valid, otherwise fetches from API
  Future<UserPlanEntity?> getCurrentPlan() async {
    // Check if we have valid cached data
    if (await _cacheService.isPlanCacheValid()) {
      final cachedPlan = await _cacheService.getCachedPlan();
      if (cachedPlan != null) {
        return cachedPlan;
      }
    }

    // Fetch from API and cache the result
    try {
      final plan = await _planRepository.getCurrentPlan();
      if (plan != null) {
        await _cacheService.cachePlan(plan);
      }
      return plan;
    } catch (e) {
      // If API fails, try to return cached data even if expired
      final cachedPlan = await _cacheService.getCachedPlan();
      if (cachedPlan != null) {
        return cachedPlan;
      }
      rethrow;
    }
  }

  /// Refresh plan data from the server
  /// Clears cache and fetches fresh data from API
  Future<UserPlanEntity?> refreshPlanData() async {
    // Clear cache to force fresh data
    await _cacheService.clearPlanCache();
    
    try {
      final plan = await _planRepository.refreshPlanData();
      if (plan != null) {
        await _cacheService.cachePlan(plan);
      }
      return plan;
    } catch (e) {
      rethrow;
    }
  }

  /// Get transaction history for the authenticated user
  Future<List<TransactionEntity>> getPlanHistory({
    int page = 1,
    int limit = 20,
  }) async {
    return await _planRepository.getPlanHistory(
      page: page,
      limit: limit,
    );
  }

  /// Get recent transactions (last 3-5 transactions)
  /// Uses cached data if available and valid, otherwise fetches from API
  Future<List<TransactionEntity>> getRecentTransactions({
    int limit = 5,
  }) async {
    // Check if we have valid cached data
    if (await _cacheService.isTransactionsCacheValid()) {
      final cachedTransactions = await _cacheService.getCachedRecentTransactions();
      if (cachedTransactions.isNotEmpty) {
        return cachedTransactions.take(limit).toList();
      }
    }

    // Fetch from API and cache the result
    try {
      final transactions = await _planRepository.getRecentTransactions(limit: limit);
      if (transactions.isNotEmpty) {
        await _cacheService.cacheRecentTransactions(transactions);
      }
      return transactions;
    } catch (e) {
      // If API fails, try to return cached data even if expired
      final cachedTransactions = await _cacheService.getCachedRecentTransactions();
      if (cachedTransactions.isNotEmpty) {
        return cachedTransactions.take(limit).toList();
      }
      rethrow;
    }
  }

  /// Check if user has an active plan
  Future<bool> hasActivePlan() async {
    return await _planRepository.hasActivePlan();
  }

  /// Get plan statistics (total spent, credits used, etc.)
  Future<Map<String, dynamic>> getPlanStatistics() async {
    return await _planRepository.getPlanStatistics();
  }

  // Cache Management Methods

  /// Clear all cached data
  Future<void> clearCache() async {
    await _cacheService.clearAllCache();
  }

  /// Force refresh all data (clear cache and fetch fresh data)
  Future<void> forceRefresh() async {
    await _cacheService.forceCacheRefresh();
  }

  /// Check if plan data is cached and valid
  Future<bool> hasCachedPlanData() async {
    return await _cacheService.isPlanCacheValid();
  }

  /// Check if transactions data is cached and valid
  Future<bool> hasCachedTransactionsData() async {
    return await _cacheService.isTransactionsCacheValid();
  }

  /// Get cache information for debugging
  Future<Map<String, dynamic>> getCacheInfo() async {
    return await _cacheService.getCacheInfo();
  }
}