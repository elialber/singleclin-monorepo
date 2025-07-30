import 'package:mobile/domain/entities/transaction_entity.dart';
import 'package:mobile/domain/entities/user_plan_entity.dart';

/// Repository interface for plan-related operations
abstract class PlanRepository {
  /// Get current active plan for the authenticated user
  Future<UserPlanEntity?> getCurrentPlan();

  /// Refresh plan data from the server
  Future<UserPlanEntity?> refreshPlanData();

  /// Get transaction history for the authenticated user
  Future<List<TransactionEntity>> getPlanHistory({
    int page = 1,
    int limit = 20,
  });

  /// Get recent transactions (last 3-5 transactions)
  Future<List<TransactionEntity>> getRecentTransactions({int limit = 5});

  /// Check if user has an active plan
  Future<bool> hasActivePlan();

  /// Get plan statistics (total spent, credits used, etc.)
  Future<Map<String, dynamic>> getPlanStatistics();
}
