import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:singleclin_mobile/core/constants/api_constants.dart';
import 'package:singleclin_mobile/core/errors/api_exceptions.dart';
import 'package:singleclin_mobile/data/models/transaction_model.dart';
import 'package:singleclin_mobile/data/models/user_plan_model.dart';
import 'package:singleclin_mobile/data/services/api_client.dart';
import 'package:singleclin_mobile/domain/entities/transaction_entity.dart';
import 'package:singleclin_mobile/domain/entities/user_plan_entity.dart';
import 'package:singleclin_mobile/domain/repositories/plan_repository.dart';

/// Implementation of PlanRepository using REST API
class PlanRepositoryImpl implements PlanRepository {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<UserPlanEntity?> getCurrentPlan() async {
    try {
      if (kDebugMode) {
        print('🏥 PlanRepository: Fetching current plan...');
      }

      final Response response = await _apiClient.get(
        ApiConstants.profileEndpoint,
      );

      if (response.data == null) {
        if (kDebugMode) {
          print('⚠️ PlanRepository: No plan data received');
        }
        return null;
      }

      final Map<String, dynamic>? data =
          (response.data as Map<String, dynamic>?)?[ApiConstants.dataKey]
              as Map<String, dynamic>?;
      if (data == null || data['current_plan'] == null) {
        if (kDebugMode) {
          print('⚠️ PlanRepository: User has no active plan');
        }
        return null;
      }

      final userPlan = UserPlanModel.fromJson(
        data['current_plan'] as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print('✅ PlanRepository: Current plan loaded - ${userPlan.plan.name}');
      }

      return userPlan.toEntity();
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw GenericApiException(
        e.message ?? 'Failed to get current plan',
        'get_current_plan_error',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ PlanRepository: Unexpected error getting current plan: $e');
      }
      throw GenericApiException(
        'Failed to get current plan: ${e.toString()}',
        'get_current_plan_error',
      );
    }
  }

  @override
  Future<UserPlanEntity?> refreshPlanData() async {
    try {
      if (kDebugMode) {
        print('🔄 PlanRepository: Refreshing plan data...');
      }

      final Response response = await _apiClient.get(
        '${ApiConstants.profileEndpoint}/refresh',
      );

      if (response.data == null) {
        if (kDebugMode) {
          print('⚠️ PlanRepository: No refreshed plan data received');
        }
        return null;
      }

      final Map<String, dynamic>? data =
          (response.data as Map<String, dynamic>?)?[ApiConstants.dataKey]
              as Map<String, dynamic>?;
      if (data == null || data['current_plan'] == null) {
        if (kDebugMode) {
          print('⚠️ PlanRepository: User has no active plan after refresh');
        }
        return null;
      }

      final userPlan = UserPlanModel.fromJson(
        data['current_plan'] as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print('✅ PlanRepository: Plan data refreshed - ${userPlan.plan.name}');
      }

      return userPlan.toEntity();
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw GenericApiException(
        e.message ?? 'Failed to refresh plan data',
        'refresh_plan_data_error',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ PlanRepository: Unexpected error refreshing plan data: $e');
      }
      throw GenericApiException(
        'Failed to refresh plan data: ${e.toString()}',
        'refresh_plan_data_error',
      );
    }
  }

  @override
  Future<List<TransactionEntity>> getPlanHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      if (kDebugMode) {
        print(
          '📜 PlanRepository: Fetching plan history (page: $page, limit: $limit)...',
        );
      }

      final Response response = await _apiClient.get(
        ApiConstants.transactionsEndpoint,
        queryParameters: {
          ApiConstants.pageKey: page,
          ApiConstants.limitKey: limit,
        },
      );

      if (response.data == null ||
          (response.data as Map<String, dynamic>?)?[ApiConstants.dataKey] ==
              null) {
        if (kDebugMode) {
          print('⚠️ PlanRepository: No transaction history data received');
        }
        return [];
      }

      final List<dynamic> transactionsData =
          (response.data as Map<String, dynamic>)[ApiConstants.dataKey]
              as List<dynamic>;
      final transactions = transactionsData
          .map((json) => TransactionModel.fromJson(json).toEntity())
          .toList();

      if (kDebugMode) {
        print('✅ PlanRepository: Loaded ${transactions.length} transactions');
      }

      return transactions;
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw GenericApiException(
        e.message ?? 'Failed to get plan history',
        'get_plan_history_error',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ PlanRepository: Unexpected error getting plan history: $e');
      }
      throw GenericApiException(
        'Failed to get plan history: ${e.toString()}',
        'get_plan_history_error',
      );
    }
  }

  @override
  Future<List<TransactionEntity>> getRecentTransactions({int limit = 5}) async {
    try {
      if (kDebugMode) {
        print(
          '📝 PlanRepository: Fetching recent transactions (limit: $limit)...',
        );
      }

      final Response response = await _apiClient.get(
        '${ApiConstants.transactionsEndpoint}/recent',
        queryParameters: {ApiConstants.limitKey: limit},
      );

      if (response.data == null ||
          (response.data as Map<String, dynamic>?)?[ApiConstants.dataKey] ==
              null) {
        if (kDebugMode) {
          print('⚠️ PlanRepository: No recent transactions data received');
        }
        return [];
      }

      final List<dynamic> transactionsData =
          (response.data as Map<String, dynamic>)[ApiConstants.dataKey]
              as List<dynamic>;
      final transactions = transactionsData
          .map((json) => TransactionModel.fromJson(json).toEntity())
          .toList();

      if (kDebugMode) {
        print(
          '✅ PlanRepository: Loaded ${transactions.length} recent transactions',
        );
      }

      return transactions;
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw GenericApiException(
        e.message ?? 'Failed to get recent transactions',
        'get_recent_transactions_error',
      );
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ PlanRepository: Unexpected error getting recent transactions: $e',
        );
      }
      throw GenericApiException(
        'Failed to get recent transactions: ${e.toString()}',
        'get_recent_transactions_error',
      );
    }
  }

  @override
  Future<bool> hasActivePlan() async {
    try {
      final plan = await getCurrentPlan();
      return plan != null && plan.isActive && !plan.isExpired;
    } catch (e) {
      if (kDebugMode) {
        print('❌ PlanRepository: Error checking active plan: $e');
      }
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getPlanStatistics() async {
    try {
      if (kDebugMode) {
        print('📊 PlanRepository: Fetching plan statistics...');
      }

      final Response response = await _apiClient.get(
        '${ApiConstants.profileEndpoint}/statistics',
      );

      if (response.data == null ||
          (response.data as Map<String, dynamic>?)?[ApiConstants.dataKey] ==
              null) {
        if (kDebugMode) {
          print('⚠️ PlanRepository: No statistics data received');
        }
        return {};
      }

      final Map<String, dynamic> stats =
          (response.data as Map<String, dynamic>)[ApiConstants.dataKey]
              as Map<String, dynamic>;

      if (kDebugMode) {
        print('✅ PlanRepository: Plan statistics loaded');
      }

      return stats;
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw GenericApiException(
        e.message ?? 'Failed to get plan statistics',
        'get_plan_statistics_error',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ PlanRepository: Unexpected error getting plan statistics: $e');
      }
      throw GenericApiException(
        'Failed to get plan statistics: ${e.toString()}',
        'get_plan_statistics_error',
      );
    }
  }
}
