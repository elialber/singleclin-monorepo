import 'package:flutter/foundation.dart';

import 'package:mobile/domain/entities/plan_entity.dart';

/// User plan entity representing a user's subscription to a healthcare plan
@immutable
class UserPlanEntity {
  const UserPlanEntity({
    required this.id,
    required this.userId,
    required this.planId,
    required this.plan,
    required this.usedCredits,
    required this.remainingCredits,
    required this.startDate,
    required this.expirationDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  final int id;
  final int userId;
  final int planId;
  final PlanEntity plan;
  final int usedCredits;
  final int remainingCredits;
  final DateTime startDate;
  final DateTime expirationDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Get total credits from the plan
  int get totalCredits => plan.totalCredits;

  /// Get usage percentage (0.0 to 1.0)
  double get usagePercentage =>
      totalCredits > 0 ? usedCredits / totalCredits : 0.0;

  /// Check if plan is expired
  bool get isExpired => DateTime.now().isAfter(expirationDate);

  /// Check if plan is running low on credits (less than 20%)
  bool get isRunningLow => remainingCredits / totalCredits < 0.2;

  /// Get days until expiration
  int get daysUntilExpiration {
    final now = DateTime.now();
    if (now.isAfter(expirationDate)) {
      return 0;
    }
    return expirationDate.difference(now).inDays;
  }

  /// Get status color based on remaining credits
  String get statusColor {
    final percentage = remainingCredits / totalCredits;
    if (percentage > 0.6) {
      return 'green';
    }
    if (percentage > 0.3) {
      return 'yellow';
    }
    return 'red';
  }

  @override
  String toString() {
    return 'UserPlanEntity{id: $id, planName: ${plan.name}, usedCredits: $usedCredits, remainingCredits: $remainingCredits}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPlanEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
