enum SubscriptionStatus { active, expiring, expired, paused, cancelled }

enum SubscriptionBillingCycle { monthly, quarterly, annual }

class SubscriptionPlan {
  // 'basic', 'premium', 'vip'

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyCredits,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.features,
    required this.isPopular, required this.isActive, required this.sortOrder, required this.category, this.restrictions = const [],
    this.hasFreeTrial = false,
    this.freeTrialDays = 0,
    this.maxClinics = 999,
    this.maxAppointmentsPerDay = 999,
    this.discountPercentage = 0,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      monthlyCredits: json['monthlyCredits'] ?? 0,
      monthlyPrice: (json['monthlyPrice'] ?? 0.0).toDouble(),
      annualPrice: (json['annualPrice'] ?? 0.0).toDouble(),
      features: json['features'] != null
          ? List<String>.from(json['features'])
          : [],
      restrictions: json['restrictions'] != null
          ? List<String>.from(json['restrictions'])
          : [],
      isPopular: json['isPopular'] ?? false,
      isActive: json['isActive'] ?? true,
      hasFreeTrial: json['hasFreeTrial'] ?? false,
      freeTrialDays: json['freeTrialDays'] ?? 0,
      maxClinics: json['maxClinics'] ?? 999,
      maxAppointmentsPerDay: json['maxAppointmentsPerDay'] ?? 999,
      discountPercentage: (json['discountPercentage'] ?? 0.0).toDouble(),
      sortOrder: json['sortOrder'] ?? 0,
      category: json['category'] ?? 'basic',
    );
  }
  final String id;
  final String name;
  final String description;
  final int monthlyCredits;
  final double monthlyPrice;
  final double annualPrice;
  final List<String> features;
  final List<String> restrictions;
  final bool isPopular;
  final bool isActive;
  final bool hasFreeTrial;
  final int freeTrialDays;
  final int maxClinics;
  final int maxAppointmentsPerDay;
  final double discountPercentage;
  final int sortOrder;
  final String category;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'monthlyCredits': monthlyCredits,
      'monthlyPrice': monthlyPrice,
      'annualPrice': annualPrice,
      'features': features,
      'restrictions': restrictions,
      'isPopular': isPopular,
      'isActive': isActive,
      'hasFreeTrial': hasFreeTrial,
      'freeTrialDays': freeTrialDays,
      'maxClinics': maxClinics,
      'maxAppointmentsPerDay': maxAppointmentsPerDay,
      'discountPercentage': discountPercentage,
      'sortOrder': sortOrder,
      'category': category,
    };
  }

  String get monthlyPriceDisplay {
    return 'R\$ ${monthlyPrice.toStringAsFixed(2)}/mês';
  }

  String get annualPriceDisplay {
    return 'R\$ ${annualPrice.toStringAsFixed(2)}/ano';
  }

  double get monthlyAnnualPrice {
    return annualPrice / 12;
  }

  double get annualSavings {
    return (monthlyPrice * 12) - annualPrice;
  }

  String get annualSavingsDisplay {
    return 'R\$ ${annualSavings.toStringAsFixed(2)}';
  }

  double get annualSavingsPercentage {
    if (monthlyPrice <= 0) return 0;
    return (annualSavings / (monthlyPrice * 12)) * 100;
  }

  String get annualSavingsPercentageDisplay {
    return '${annualSavingsPercentage.toInt()}% OFF';
  }

  double get creditValue {
    return monthlyPrice / monthlyCredits;
  }

  String get creditValueDisplay {
    return 'R\$ ${creditValue.toStringAsFixed(2)}/crédito';
  }

  bool get isBasic => category.toLowerCase() == 'basic';
  bool get isPremium => category.toLowerCase() == 'premium';
  bool get isVip => category.toLowerCase() == 'vip';
}

class UserSubscription {
  UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status, required this.billingCycle, required this.startDate, required this.nextBillingDate, required this.creditsBalance, required this.creditsUsedThisMonth, required this.creditsTotal, required this.amountPaid, required this.createdAt, required this.updatedAt, this.plan,
    this.endDate,
    this.cancelDate,
    this.pauseDate,
    this.paymentMethodId,
    this.metadata,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      planId: json['planId'] ?? '',
      plan: json['plan'] != null
          ? SubscriptionPlan.fromJson(json['plan'])
          : null,
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => SubscriptionStatus.active,
      ),
      billingCycle: SubscriptionBillingCycle.values.firstWhere(
        (e) => e.toString().split('.').last == json['billingCycle'],
        orElse: () => SubscriptionBillingCycle.monthly,
      ),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      nextBillingDate: DateTime.parse(json['nextBillingDate']),
      cancelDate: json['cancelDate'] != null
          ? DateTime.parse(json['cancelDate'])
          : null,
      pauseDate: json['pauseDate'] != null
          ? DateTime.parse(json['pauseDate'])
          : null,
      creditsBalance: json['creditsBalance'] ?? 0,
      creditsUsedThisMonth: json['creditsUsedThisMonth'] ?? 0,
      creditsTotal: json['creditsTotal'] ?? 0,
      amountPaid: (json['amountPaid'] ?? 0.0).toDouble(),
      paymentMethodId: json['paymentMethodId'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
  final String id;
  final String userId;
  final String planId;
  final SubscriptionPlan? plan;
  final SubscriptionStatus status;
  final SubscriptionBillingCycle billingCycle;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextBillingDate;
  final DateTime? cancelDate;
  final DateTime? pauseDate;
  final int creditsBalance;
  final int creditsUsedThisMonth;
  final int creditsTotal;
  final double amountPaid;
  final String? paymentMethodId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
      'plan': plan?.toJson(),
      'status': status.toString().split('.').last,
      'billingCycle': billingCycle.toString().split('.').last,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'nextBillingDate': nextBillingDate.toIso8601String(),
      'cancelDate': cancelDate?.toIso8601String(),
      'pauseDate': pauseDate?.toIso8601String(),
      'creditsBalance': creditsBalance,
      'creditsUsedThisMonth': creditsUsedThisMonth,
      'creditsTotal': creditsTotal,
      'amountPaid': amountPaid,
      'paymentMethodId': paymentMethodId,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get statusDisplayName {
    switch (status) {
      case SubscriptionStatus.active:
        return 'Ativa';
      case SubscriptionStatus.expiring:
        return 'Vencendo';
      case SubscriptionStatus.expired:
        return 'Expirada';
      case SubscriptionStatus.paused:
        return 'Pausada';
      case SubscriptionStatus.cancelled:
        return 'Cancelada';
    }
  }

  String get billingCycleDisplayName {
    switch (billingCycle) {
      case SubscriptionBillingCycle.monthly:
        return 'Mensal';
      case SubscriptionBillingCycle.quarterly:
        return 'Trimestral';
      case SubscriptionBillingCycle.annual:
        return 'Anual';
    }
  }

  bool get isActive => status == SubscriptionStatus.active;
  bool get isExpiring => status == SubscriptionStatus.expiring;
  bool get isExpired => status == SubscriptionStatus.expired;
  bool get isPaused => status == SubscriptionStatus.paused;
  bool get isCancelled => status == SubscriptionStatus.cancelled;

  int get daysUntilBilling {
    return nextBillingDate.difference(DateTime.now()).inDays;
  }

  bool get isNearRenewal => daysUntilBilling <= 7;

  double get creditUsagePercentage {
    if (creditsTotal <= 0) return 0;
    return (creditsUsedThisMonth / creditsTotal) * 100;
  }

  String get nextBillingDisplayDate {
    return 'Próxima cobrança: ${nextBillingDate.day}/${nextBillingDate.month}/${nextBillingDate.year}';
  }
}
