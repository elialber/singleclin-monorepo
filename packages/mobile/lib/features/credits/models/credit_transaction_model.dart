enum TransactionType { earned, spent, refunded, bonus, subscription, purchase }

enum TransactionSource {
  monthlySubscription,
  referral,
  purchase,
  appointmentBooking,
  appointmentCancel,
  bonus,
  refund,
}

class CreditTransactionModel {
  CreditTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.balanceAfter,
    required this.type,
    required this.source,
    required this.description,
    required this.createdAt,
    this.relatedEntityId,
    this.relatedEntityType,
    this.metadata,
  });

  factory CreditTransactionModel.fromJson(Map<String, dynamic> json) {
    return CreditTransactionModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      amount: json['amount'] ?? 0,
      balanceAfter: json['balanceAfter'] ?? 0,
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TransactionType.earned,
      ),
      source: TransactionSource.values.firstWhere(
        (e) => e.toString().split('.').last == json['source'],
        orElse: () => TransactionSource.monthlySubscription,
      ),
      description: json['description'] ?? '',
      relatedEntityId: json['relatedEntityId'],
      relatedEntityType: json['relatedEntityType'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
  final String id;
  final String userId;
  final int amount;
  final int balanceAfter;
  final TransactionType type;
  final TransactionSource source;
  final String description;
  final String? relatedEntityId; // ID do agendamento, referral, etc.
  final String? relatedEntityType; // 'appointment', 'referral', etc.
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'type': type.toString().split('.').last,
      'source': source.toString().split('.').last,
      'description': description,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get typeDisplayName {
    switch (type) {
      case TransactionType.earned:
        return 'Recebido';
      case TransactionType.spent:
        return 'Gasto';
      case TransactionType.refunded:
        return 'Reembolsado';
      case TransactionType.bonus:
        return 'Bônus';
      case TransactionType.subscription:
        return 'Assinatura';
      case TransactionType.purchase:
        return 'Compra';
    }
  }

  String get sourceDisplayName {
    switch (source) {
      case TransactionSource.monthlySubscription:
        return 'Assinatura Mensal';
      case TransactionSource.referral:
        return 'Indicação';
      case TransactionSource.purchase:
        return 'Compra';
      case TransactionSource.appointmentBooking:
        return 'Agendamento';
      case TransactionSource.appointmentCancel:
        return 'Cancelamento';
      case TransactionSource.bonus:
        return 'Bônus';
      case TransactionSource.refund:
        return 'Reembolso';
    }
  }

  bool get isPositive {
    return type == TransactionType.earned ||
        type == TransactionType.refunded ||
        type == TransactionType.bonus ||
        type == TransactionType.subscription ||
        type == TransactionType.purchase;
  }

  String get amountDisplay {
    final String prefix = isPositive ? '+' : '-';
    return '$prefix$amount SG';
  }
}

class SubscriptionPlan {
  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyCredits,
    required this.monthlyPrice,
    required this.features,
    required this.isPopular,
    required this.isActive,
    required this.sortOrder,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      monthlyCredits: json['monthlyCredits'] ?? 0,
      monthlyPrice: (json['monthlyPrice'] ?? 0.0).toDouble(),
      features: json['features'] != null
          ? List<String>.from(json['features'])
          : [],
      isPopular: json['isPopular'] ?? false,
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
  final String id;
  final String name;
  final String description;
  final int monthlyCredits;
  final double monthlyPrice;
  final List<String> features;
  final bool isPopular;
  final bool isActive;
  final int sortOrder;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'monthlyCredits': monthlyCredits,
      'monthlyPrice': monthlyPrice,
      'features': features,
      'isPopular': isPopular,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }

  String get priceDisplay {
    return 'R\$ ${monthlyPrice.toStringAsFixed(2)}/mês';
  }

  double get creditValue {
    return monthlyPrice / monthlyCredits;
  }
}

class CreditPurchaseOption {
  CreditPurchaseOption({
    required this.id,
    required this.name,
    required this.credits,
    required this.price,
    required this.discount,
    required this.isPopular,
    required this.isActive,
  });

  factory CreditPurchaseOption.fromJson(Map<String, dynamic> json) {
    return CreditPurchaseOption(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      credits: json['credits'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      discount: (json['discount'] ?? 0.0).toDouble(),
      isPopular: json['isPopular'] ?? false,
      isActive: json['isActive'] ?? true,
    );
  }
  final String id;
  final String name;
  final int credits;
  final double price;
  final double discount;
  final bool isPopular;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'credits': credits,
      'price': price,
      'discount': discount,
      'isPopular': isPopular,
      'isActive': isActive,
    };
  }

  String get priceDisplay {
    return 'R\$ ${price.toStringAsFixed(2)}';
  }

  double get originalPrice {
    return price / (1 - (discount / 100));
  }

  String get originalPriceDisplay {
    return 'R\$ ${originalPrice.toStringAsFixed(2)}';
  }

  String get discountDisplay {
    return '${discount.toInt()}% OFF';
  }

  double get creditValue {
    return price / credits;
  }
}

class ReferralProgram {
  ReferralProgram({
    required this.id,
    required this.userId,
    required this.referralCode,
    required this.bonusCredits,
    required this.totalReferrals,
    required this.totalCreditsEarned,
    required this.referrals,
    required this.createdAt,
  });

  factory ReferralProgram.fromJson(Map<String, dynamic> json) {
    return ReferralProgram(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      referralCode: json['referralCode'] ?? '',
      bonusCredits: json['bonusCredits'] ?? 10,
      totalReferrals: json['totalReferrals'] ?? 0,
      totalCreditsEarned: json['totalCreditsEarned'] ?? 0,
      referrals: json['referrals'] != null
          ? List<ReferralRecord>.from(
              json['referrals'].map((x) => ReferralRecord.fromJson(x)),
            )
          : [],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
  final String id;
  final String userId;
  final String referralCode;
  final int bonusCredits;
  final int totalReferrals;
  final int totalCreditsEarned;
  final List<ReferralRecord> referrals;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'referralCode': referralCode,
      'bonusCredits': bonusCredits,
      'totalReferrals': totalReferrals,
      'totalCreditsEarned': totalCreditsEarned,
      'referrals': referrals.map((x) => x.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get shareMessage {
    return 'Conheça o SingleClin! Use meu código $referralCode e ganhe $bonusCredits créditos SG grátis para seus primeiros procedimentos. Baixe agora: https://singleclin.com/app';
  }
}

class ReferralRecord {
  ReferralRecord({
    required this.id,
    required this.referralProgramId,
    required this.referredUserId,
    required this.creditsEarned,
    required this.isActive,
    required this.referredAt,
    this.referredUserName,
  });

  factory ReferralRecord.fromJson(Map<String, dynamic> json) {
    return ReferralRecord(
      id: json['id'] ?? '',
      referralProgramId: json['referralProgramId'] ?? '',
      referredUserId: json['referredUserId'] ?? '',
      referredUserName: json['referredUserName'],
      creditsEarned: json['creditsEarned'] ?? 0,
      isActive: json['isActive'] ?? true,
      referredAt: DateTime.parse(json['referredAt']),
    );
  }
  final String id;
  final String referralProgramId;
  final String referredUserId;
  final String? referredUserName;
  final int creditsEarned;
  final bool isActive;
  final DateTime referredAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referralProgramId': referralProgramId,
      'referredUserId': referredUserId,
      'referredUserName': referredUserName,
      'creditsEarned': creditsEarned,
      'isActive': isActive,
      'referredAt': referredAt.toIso8601String(),
    };
  }
}
