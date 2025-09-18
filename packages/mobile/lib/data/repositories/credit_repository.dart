import 'package:dio/dio.dart';
import '../../core/repositories/base_repository.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/network_service.dart';
import '../../features/credits/models/credit_transaction_model.dart';
import '../../features/credits/models/wallet_balance.dart';

/// Repository for credit and wallet data with offline-first capabilities
///
/// Handles credit balance, transaction history, and wallet operations
/// with offline caching and sync capabilities.
class CreditRepository extends BaseRepository<CreditTransactionModel> {
  CreditRepository({
    required CacheService cacheService,
    required NetworkService networkService,
    required Dio dio,
  }) : super(
          cacheService: cacheService,
          networkService: networkService,
          dio: dio,
        );

  @override
  String get boxName => 'credit_transactions';

  @override
  int get cacheTtlMinutes => 15; // Credit data refreshed every 15 minutes

  @override
  bool get isOfflineCapable => true; // Credit balance should always be available

  @override
  Map<String, dynamic> toMap(CreditTransactionModel transaction) => transaction.toJson();

  @override
  CreditTransactionModel fromMap(Map<String, dynamic> map) => CreditTransactionModel.fromJson(map);

  @override
  Future<CreditTransactionModel?> fetchFromNetwork(String id) async {
    try {
      final response = await _dio.get('/api/credits/transactions/$id');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return CreditTransactionModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('❌ Failed to fetch transaction from network: $e');
      rethrow;
    }
  }

  @override
  Future<List<CreditTransactionModel>> fetchListFromNetwork({
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (filters != null) ...filters,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      };

      final response = await _dio.get('/api/credits/transactions', queryParameters: queryParams);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> transactions = response.data['data']['transactions'] ?? [];
        return transactions.map((json) => CreditTransactionModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Failed to fetch transactions from network: $e');
      rethrow;
    }
  }

  @override
  Future<CreditTransactionModel?> saveToNetwork(CreditTransactionModel transaction, String? id) async {
    try {
      final data = transaction.toJson();
      Response response;

      if (id != null) {
        // Update existing transaction (rare)
        response = await _dio.put('/api/credits/transactions/$id', data: data);
      } else {
        // Create new transaction
        response = await _dio.post('/api/credits/transactions', data: data);
      }

      if (response.statusCode == 200 && response.data['success'] == true) {
        return CreditTransactionModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('❌ Failed to save transaction to network: $e');
      rethrow;
    }
  }

  @override
  Future<bool> deleteFromNetwork(String id) async {
    try {
      final response = await _dio.delete('/api/credits/transactions/$id');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('❌ Failed to delete transaction from network: $e');
      rethrow;
    }
  }

  // Credit-specific methods

  /// Get current wallet balance with offline fallback
  Future<WalletBalance?> getWalletBalance({bool forceRefresh = false}) async {
    try {
      const balanceKey = 'current_balance';

      // Check cache first unless forced refresh
      if (!forceRefresh) {
        final cachedBalance = await _cacheService.get('wallet_balance', balanceKey);
        if (cachedBalance != null && !_isBalanceCacheExpired(balanceKey)) {
          return WalletBalance.fromJson(cachedBalance);
        }
      }

      // Try to fetch from network
      if (await _networkService.isConnected) {
        final response = await _dio.get('/api/credits/balance');

        if (response.statusCode == 200 && response.data['success'] == true) {
          final balance = WalletBalance.fromJson(response.data['data']);

          // Cache the balance
          await _cacheService.put('wallet_balance', balanceKey, balance.toJson());
          await _setBalanceCacheTimestamp(balanceKey);

          return balance;
        }
      }

      // Fallback to cached data if available
      final cachedBalance = await _cacheService.get('wallet_balance', balanceKey);
      if (cachedBalance != null) {
        return WalletBalance.fromJson(cachedBalance);
      }

      return null;
    } catch (e) {
      print('❌ Failed to get wallet balance: $e');
      // Try to return cached data as last resort
      final cachedBalance = await _cacheService.get('wallet_balance', 'current_balance');
      return cachedBalance != null ? WalletBalance.fromJson(cachedBalance) : null;
    }
  }

  /// Get transaction history with pagination and offline support
  Future<List<CreditTransactionModel>> getTransactionHistory({
    int page = 1,
    int limit = 20,
    String? type, // 'credit', 'debit', 'transfer'
    DateTime? startDate,
    DateTime? endDate,
    bool offlineOnly = false,
  }) async {
    final filters = <String, dynamic>{
      'page': page,
      if (type != null) 'type': type,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    final transactions = await getMany(
      filters: filters,
      limit: limit,
      offlineOnly: offlineOnly,
    );

    // Sort by date (newest first)
    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return transactions;
  }

  /// Get recent transactions (last 10)
  Future<List<CreditTransactionModel>> getRecentTransactions({bool offlineOnly = false}) async {
    return await getTransactionHistory(
      limit: 10,
      offlineOnly: offlineOnly,
    );
  }

  /// Get transactions by type
  Future<List<CreditTransactionModel>> getTransactionsByType({
    required String type,
    int limit = 50,
    bool offlineOnly = false,
  }) async {
    return await getTransactionHistory(
      type: type,
      limit: limit,
      offlineOnly: offlineOnly,
    );
  }

  /// Get spending summary for a period
  Future<Map<String, double>> getSpendingSummary({
    DateTime? startDate,
    DateTime? endDate,
    bool offlineOnly = false,
  }) async {
    try {
      final transactions = await getTransactionHistory(
        startDate: startDate,
        endDate: endDate,
        limit: 1000, // Get more transactions for summary
        offlineOnly: offlineOnly,
      );

      double totalSpent = 0;
      double totalEarned = 0;
      int transactionCount = 0;

      for (final transaction in transactions) {
        if (transaction.type.toLowerCase() == 'debit') {
          totalSpent += transaction.amount;
        } else if (transaction.type.toLowerCase() == 'credit') {
          totalEarned += transaction.amount;
        }
        transactionCount++;
      }

      return {
        'totalSpent': totalSpent,
        'totalEarned': totalEarned,
        'netChange': totalEarned - totalSpent,
        'transactionCount': transactionCount.toDouble(),
        'averageTransaction': transactionCount > 0 ? (totalSpent + totalEarned) / transactionCount : 0,
      };
    } catch (e) {
      print('❌ Failed to get spending summary: $e');
      return {
        'totalSpent': 0,
        'totalEarned': 0,
        'netChange': 0,
        'transactionCount': 0,
        'averageTransaction': 0,
      };
    }
  }

  /// Purchase credits (requires network)
  Future<Map<String, dynamic>?> purchaseCredits({
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      if (!await _networkService.isConnected) {
        throw NetworkException('Internet connection required for credit purchase');
      }

      final response = await _dio.post('/api/credits/purchase', data: {
        'amount': amount,
        'paymentMethod': paymentMethod,
        'paymentDetails': paymentDetails,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final result = response.data['data'];

        // Refresh balance after successful purchase
        await getWalletBalance(forceRefresh: true);

        // Add transaction to local cache optimistically
        if (result['transaction'] != null) {
          final transaction = CreditTransactionModel.fromJson(result['transaction']);
          await _cacheTransactionOptimistically(transaction);
        }

        return result;
      }

      return null;
    } catch (e) {
      print('❌ Failed to purchase credits: $e');
      rethrow;
    }
  }

  /// Use credits for service (requires network for security)
  Future<Map<String, dynamic>?> useCredits({
    required String serviceId,
    required double amount,
    required String clinicId,
    String? qrCodeToken,
  }) async {
    try {
      if (!await _networkService.isConnected) {
        throw NetworkException('Internet connection required for credit usage');
      }

      final response = await _dio.post('/api/credits/use', data: {
        'serviceId': serviceId,
        'amount': amount,
        'clinicId': clinicId,
        'qrCodeToken': qrCodeToken,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final result = response.data['data'];

        // Refresh balance after successful use
        await getWalletBalance(forceRefresh: true);

        // Add transaction to local cache
        if (result['transaction'] != null) {
          final transaction = CreditTransactionModel.fromJson(result['transaction']);
          await _cacheTransactionOptimistically(transaction);
        }

        return result;
      }

      return null;
    } catch (e) {
      print('❌ Failed to use credits: $e');
      rethrow;
    }
  }

  /// Transfer credits to another user (requires network)
  Future<Map<String, dynamic>?> transferCredits({
    required String recipientUserId,
    required double amount,
    String? note,
  }) async {
    try {
      if (!await _networkService.isConnected) {
        throw NetworkException('Internet connection required for credit transfer');
      }

      final response = await _dio.post('/api/credits/transfer', data: {
        'recipientUserId': recipientUserId,
        'amount': amount,
        'note': note,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final result = response.data['data'];

        // Refresh balance after successful transfer
        await getWalletBalance(forceRefresh: true);

        return result;
      }

      return null;
    } catch (e) {
      print('❌ Failed to transfer credits: $e');
      rethrow;
    }
  }

  /// Get credit packages available for purchase
  Future<List<Map<String, dynamic>>> getAvailableCreditPackages() async {
    try {
      // Check cache first
      final cached = await _cacheService.getList('credit_packages', 'available_packages');
      if (cached.isNotEmpty && !_isPackagesCacheExpired()) {
        return cached;
      }

      // Fetch from network
      if (await _networkService.isConnected) {
        final response = await _dio.get('/api/credits/packages');

        if (response.statusCode == 200 && response.data['success'] == true) {
          final packages = List<Map<String, dynamic>>.from(response.data['data']);

          // Cache packages
          await _cacheService.putList('credit_packages', 'available_packages', packages);
          await _setPackagesCacheTimestamp();

          return packages;
        }
      }

      // Return cached packages if network failed
      return cached;
    } catch (e) {
      print('❌ Failed to get credit packages: $e');
      return [];
    }
  }

  /// Preload critical credit data for offline usage
  Future<void> preloadCriticalData() async {
    try {
      if (!await _networkService.isConnected) return;

      print('📥 Preloading critical credit data...');

      // Load current balance
      await getWalletBalance(forceRefresh: true);

      // Load recent transaction history
      await getTransactionHistory(limit: 50);

      // Load available credit packages
      await getAvailableCreditPackages();

      print('✅ Critical credit data preloaded');
    } catch (e) {
      print('❌ Failed to preload credit data: $e');
    }
  }

  /// Sync pending credit operations when back online
  Future<void> syncPendingOperations() async {
    try {
      if (!await _networkService.isConnected) return;

      await syncAll(); // Use base repository sync

      // Refresh balance after sync
      await getWalletBalance(forceRefresh: true);

    } catch (e) {
      print('❌ Failed to sync pending credit operations: $e');
    }
  }

  // Private helper methods

  bool _isBalanceCacheExpired(String key) {
    final timestamp = _cacheService.getTimestamp('wallet_balance', key);
    if (timestamp == null) return true;

    // Balance cache expires after 10 minutes
    return DateTime.now().difference(timestamp).inMinutes > 10;
  }

  Future<void> _setBalanceCacheTimestamp(String key) async {
    await _cacheService.put('wallet_balance', '${key}_timestamp', {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  bool _isPackagesCacheExpired() {
    final timestamp = _cacheService.getTimestamp('credit_packages', 'available_packages');
    if (timestamp == null) return true;

    // Packages cache expires after 4 hours
    return DateTime.now().difference(timestamp).inHours > 4;
  }

  Future<void> _setPackagesCacheTimestamp() async {
    await _cacheService.put('credit_packages', 'packages_timestamp', {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _cacheTransactionOptimistically(CreditTransactionModel transaction) async {
    try {
      // Add to transaction cache
      await _cacheData(getCacheKey(transaction.id), transaction);

      // Update transaction list cache by prepending new transaction
      final cachedList = await _getCachedList('list__all_0');
      cachedList.insert(0, transaction);

      // Keep only last 100 transactions in cache
      if (cachedList.length > 100) {
        cachedList.removeRange(100, cachedList.length);
      }

      await _cacheList('list__all_0', cachedList);

    } catch (e) {
      print('⚠️ Failed to cache transaction optimistically: $e');
    }
  }
}

/// Exception thrown when network is required for credit operations
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}