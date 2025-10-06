import 'package:flutter/foundation.dart';

/// Dashboard statistics model for SingleClin mobile app
class DashboardStats {
  const DashboardStats({
    required this.sgBalance,
    required this.totalAppointments,
    required this.completedAppointments,
    required this.upcomingAppointments,
    required this.cancelledAppointments,
    required this.lastUpdated,
    required this.hasActiveSubscription,
    this.renewalDate,
    this.subscriptionPlan,
    this.categoryUsage = const {},
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      sgBalance: 0.0,
      totalAppointments: 0,
      completedAppointments: 0,
      upcomingAppointments: 0,
      cancelledAppointments: 0,
      lastUpdated: DateTime.now(),
      hasActiveSubscription: false,
    );
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      sgBalance: (json['sgBalance'] ?? 0.0).toDouble(),
      renewalDate: json['renewalDate'] != null
          ? DateTime.tryParse(json['renewalDate'])
          : null,
      totalAppointments: json['totalAppointments'] ?? 0,
      completedAppointments: json['completedAppointments'] ?? 0,
      upcomingAppointments: json['upcomingAppointments'] ?? 0,
      cancelledAppointments: json['cancelledAppointments'] ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated']) ?? DateTime.now()
          : DateTime.now(),
      hasActiveSubscription: json['hasActiveSubscription'] ?? false,
      subscriptionPlan: json['subscriptionPlan'],
      categoryUsage: json['categoryUsage'] != null
          ? Map<String, int>.from(json['categoryUsage'])
          : const {},
    );
  }
  final double sgBalance;
  final DateTime? renewalDate;
  final int totalAppointments;
  final int completedAppointments;
  final int upcomingAppointments;
  final int cancelledAppointments;
  final DateTime lastUpdated;
  final bool hasActiveSubscription;
  final String? subscriptionPlan;
  final Map<String, int> categoryUsage;

  Map<String, dynamic> toJson() {
    return {
      'sgBalance': sgBalance,
      'renewalDate': renewalDate?.toIso8601String(),
      'totalAppointments': totalAppointments,
      'completedAppointments': completedAppointments,
      'upcomingAppointments': upcomingAppointments,
      'cancelledAppointments': cancelledAppointments,
      'lastUpdated': lastUpdated.toIso8601String(),
      'hasActiveSubscription': hasActiveSubscription,
      'subscriptionPlan': subscriptionPlan,
      'categoryUsage': categoryUsage,
    };
  }

  DashboardStats copyWith({
    double? sgBalance,
    DateTime? renewalDate,
    int? totalAppointments,
    int? completedAppointments,
    int? upcomingAppointments,
    int? cancelledAppointments,
    DateTime? lastUpdated,
    bool? hasActiveSubscription,
    String? subscriptionPlan,
    Map<String, int>? categoryUsage,
  }) {
    return DashboardStats(
      sgBalance: sgBalance ?? this.sgBalance,
      renewalDate: renewalDate ?? this.renewalDate,
      totalAppointments: totalAppointments ?? this.totalAppointments,
      completedAppointments:
          completedAppointments ?? this.completedAppointments,
      upcomingAppointments: upcomingAppointments ?? this.upcomingAppointments,
      cancelledAppointments:
          cancelledAppointments ?? this.cancelledAppointments,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasActiveSubscription:
          hasActiveSubscription ?? this.hasActiveSubscription,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      categoryUsage: categoryUsage ?? this.categoryUsage,
    );
  }

  /// Get completion rate as percentage
  double get completionRate {
    if (totalAppointments == 0) return 0.0;
    return (completedAppointments / totalAppointments) * 100;
  }

  /// Get cancellation rate as percentage
  double get cancellationRate {
    if (totalAppointments == 0) return 0.0;
    return (cancelledAppointments / totalAppointments) * 100;
  }

  /// Check if SG balance is low (less than 50 credits)
  bool get isBalanceLow => sgBalance < 50;

  /// Check if renewal is due soon (within 7 days)
  bool get isRenewalDue {
    if (renewalDate == null) return false;
    final now = DateTime.now();
    final difference = renewalDate!.difference(now).inDays;
    return difference <= 7;
  }

  /// Get days until renewal
  int get daysUntilRenewal {
    if (renewalDate == null) return -1;
    return renewalDate!.difference(DateTime.now()).inDays;
  }

  /// Get formatted SG balance
  String get formattedBalance {
    if (sgBalance >= 1000000) {
      return '${(sgBalance / 1000000).toStringAsFixed(1)}M';
    } else if (sgBalance >= 1000) {
      return '${(sgBalance / 1000).toStringAsFixed(1)}K';
    }
    return sgBalance.toStringAsFixed(0);
  }

  /// Get most used category
  String get mostUsedCategory {
    if (categoryUsage.isEmpty) return '';

    String topCategory = '';
    int maxUsage = 0;

    categoryUsage.forEach((category, usage) {
      if (usage > maxUsage) {
        maxUsage = usage;
        topCategory = category;
      }
    });

    return topCategory;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardStats &&
        other.sgBalance == sgBalance &&
        other.renewalDate == renewalDate &&
        other.totalAppointments == totalAppointments &&
        other.completedAppointments == completedAppointments &&
        other.upcomingAppointments == upcomingAppointments &&
        other.cancelledAppointments == cancelledAppointments &&
        other.hasActiveSubscription == hasActiveSubscription &&
        other.subscriptionPlan == subscriptionPlan &&
        mapEquals(other.categoryUsage, categoryUsage);
  }

  @override
  int get hashCode {
    return Object.hash(
      sgBalance,
      renewalDate,
      totalAppointments,
      completedAppointments,
      upcomingAppointments,
      cancelledAppointments,
      hasActiveSubscription,
      subscriptionPlan,
      categoryUsage,
    );
  }

  @override
  String toString() {
    return 'DashboardStats(sgBalance: $sgBalance, totalAppointments: $totalAppointments, hasActiveSubscription: $hasActiveSubscription)';
  }
}
