enum WalletTransactionType {
  credit,
  debit,
  transfer,
  refund,
  bonus,
  cashback,
  subscription,
  purchase,
}

enum WalletCurrency {
  sg, // SingleClin Credits
  brl, // Brazilian Real
  cashback, // Cashback points
  loyalty, // Loyalty points
}

class WalletBalance {
  WalletBalance({
    required this.id,
    required this.userId,
    required this.currency,
    required this.balance,
    required this.lifetimeEarned,
    required this.lifetimeSpent,
    required this.lastUpdated,
    this.lockedBalance = 0,
    this.metadata,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      currency: WalletCurrency.values.firstWhere(
        (e) => e.toString().split('.').last == json['currency'],
        orElse: () => WalletCurrency.sg,
      ),
      balance: (json['balance'] ?? 0.0).toDouble(),
      lockedBalance: (json['lockedBalance'] ?? 0.0).toDouble(),
      lifetimeEarned: (json['lifetimeEarned'] ?? 0.0).toDouble(),
      lifetimeSpent: (json['lifetimeSpent'] ?? 0.0).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      metadata: json['metadata'],
    );
  }
  final String id;
  final String userId;
  final WalletCurrency currency;
  final double balance;
  final double lockedBalance; // Reserved for pending transactions
  final double lifetimeEarned;
  final double lifetimeSpent;
  final DateTime lastUpdated;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'currency': currency.toString().split('.').last,
      'balance': balance,
      'lockedBalance': lockedBalance,
      'lifetimeEarned': lifetimeEarned,
      'lifetimeSpent': lifetimeSpent,
      'lastUpdated': lastUpdated.toIso8601String(),
      'metadata': metadata,
    };
  }

  double get availableBalance => balance - lockedBalance;

  String get balanceDisplay {
    switch (currency) {
      case WalletCurrency.sg:
        return '${balance.toInt()} SG';
      case WalletCurrency.brl:
        return 'R\$ ${balance.toStringAsFixed(2)}';
      case WalletCurrency.cashback:
        return '${balance.toInt()} pontos';
      case WalletCurrency.loyalty:
        return '${balance.toInt()} pontos';
    }
  }

  String get availableBalanceDisplay {
    switch (currency) {
      case WalletCurrency.sg:
        return '${availableBalance.toInt()} SG disponíveis';
      case WalletCurrency.brl:
        return 'R\$ ${availableBalance.toStringAsFixed(2)} disponíveis';
      case WalletCurrency.cashback:
        return '${availableBalance.toInt()} pontos disponíveis';
      case WalletCurrency.loyalty:
        return '${availableBalance.toInt()} pontos disponíveis';
    }
  }

  String get currencyDisplayName {
    switch (currency) {
      case WalletCurrency.sg:
        return 'Créditos SG';
      case WalletCurrency.brl:
        return 'Real Brasileiro';
      case WalletCurrency.cashback:
        return 'Cashback';
      case WalletCurrency.loyalty:
        return 'Fidelidade';
    }
  }

  String get currencySymbol {
    switch (currency) {
      case WalletCurrency.sg:
        return 'SG';
      case WalletCurrency.brl:
        return r'R$';
      case WalletCurrency.cashback:
        return 'CB';
      case WalletCurrency.loyalty:
        return 'LP';
    }
  }

  bool get isSG => currency == WalletCurrency.sg;
  bool get isBRL => currency == WalletCurrency.brl;
  bool get isCashback => currency == WalletCurrency.cashback;
  bool get isLoyalty => currency == WalletCurrency.loyalty;

  bool get hasLockedFunds => lockedBalance > 0;

  bool canSpend(double amount) => availableBalance >= amount;
}

class WalletTransaction {
  WalletTransaction({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.type,
    required this.currency,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    required this.createdAt,
    this.referenceId,
    this.referenceType,
    this.metadata,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? '',
      walletId: json['walletId'] ?? '',
      userId: json['userId'] ?? '',
      type: WalletTransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => WalletTransactionType.credit,
      ),
      currency: WalletCurrency.values.firstWhere(
        (e) => e.toString().split('.').last == json['currency'],
        orElse: () => WalletCurrency.sg,
      ),
      amount: (json['amount'] ?? 0.0).toDouble(),
      balanceAfter: (json['balanceAfter'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      referenceId: json['referenceId'],
      referenceType: json['referenceType'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
  final String id;
  final String walletId;
  final String userId;
  final WalletTransactionType type;
  final WalletCurrency currency;
  final double amount;
  final double balanceAfter;
  final String description;
  final String? referenceId; // ID of related entity (booking, purchase, etc.)
  final String? referenceType; // Type of related entity
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'userId': userId,
      'type': type.toString().split('.').last,
      'currency': currency.toString().split('.').last,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'description': description,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get typeDisplayName {
    switch (type) {
      case WalletTransactionType.credit:
        return 'Crédito';
      case WalletTransactionType.debit:
        return 'Débito';
      case WalletTransactionType.transfer:
        return 'Transferência';
      case WalletTransactionType.refund:
        return 'Reembolso';
      case WalletTransactionType.bonus:
        return 'Bônus';
      case WalletTransactionType.cashback:
        return 'Cashback';
      case WalletTransactionType.subscription:
        return 'Assinatura';
      case WalletTransactionType.purchase:
        return 'Compra';
    }
  }

  bool get isCredit =>
      type == WalletTransactionType.credit ||
      type == WalletTransactionType.refund ||
      type == WalletTransactionType.bonus ||
      type == WalletTransactionType.cashback ||
      type == WalletTransactionType.subscription;

  bool get isDebit =>
      type == WalletTransactionType.debit ||
      type == WalletTransactionType.transfer ||
      type == WalletTransactionType.purchase;

  String get amountDisplay {
    final String prefix = isCredit ? '+' : '-';
    String value = '';

    switch (currency) {
      case WalletCurrency.sg:
        value = '${amount.toInt()} SG';
        break;
      case WalletCurrency.brl:
        value = 'R\$ ${amount.toStringAsFixed(2)}';
        break;
      case WalletCurrency.cashback:
        value = '${amount.toInt()} pts';
        break;
      case WalletCurrency.loyalty:
        value = '${amount.toInt()} pts';
        break;
    }

    return '$prefix$value';
  }

  String get balanceAfterDisplay {
    switch (currency) {
      case WalletCurrency.sg:
        return '${balanceAfter.toInt()} SG';
      case WalletCurrency.brl:
        return 'R\$ ${balanceAfter.toStringAsFixed(2)}';
      case WalletCurrency.cashback:
        return '${balanceAfter.toInt()} pts';
      case WalletCurrency.loyalty:
        return '${balanceAfter.toInt()} pts';
    }
  }
}

class WalletSummary {
  WalletSummary({
    required this.userId,
    required this.balances,
    required this.recentTransactions,
    required this.totalSgCredits,
    required this.totalCashback,
    required this.totalLoyaltyPoints,
    required this.monthlySgSpending,
    required this.monthlyCashbackEarned,
    required this.lastUpdated,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      userId: json['userId'] ?? '',
      balances: json['balances'] != null
          ? List<WalletBalance>.from(
              json['balances'].map((x) => WalletBalance.fromJson(x)),
            )
          : [],
      recentTransactions: json['recentTransactions'] != null
          ? List<WalletTransaction>.from(
              json['recentTransactions'].map(
                (x) => WalletTransaction.fromJson(x),
              ),
            )
          : [],
      totalSgCredits: (json['totalSgCredits'] ?? 0.0).toDouble(),
      totalCashback: (json['totalCashback'] ?? 0.0).toDouble(),
      totalLoyaltyPoints: (json['totalLoyaltyPoints'] ?? 0.0).toDouble(),
      monthlySgSpending: (json['monthlySgSpending'] ?? 0.0).toDouble(),
      monthlyCashbackEarned: (json['monthlyCashbackEarned'] ?? 0.0).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
  final String userId;
  final List<WalletBalance> balances;
  final List<WalletTransaction> recentTransactions;
  final double totalSgCredits;
  final double totalCashback;
  final double totalLoyaltyPoints;
  final double monthlySgSpending;
  final double monthlyCashbackEarned;
  final DateTime lastUpdated;

  WalletBalance? getBalance(WalletCurrency currency) {
    return balances.firstWhere(
      (balance) => balance.currency == currency,
      orElse: () => WalletBalance(
        id: '',
        userId: userId,
        currency: currency,
        balance: 0,
        lifetimeEarned: 0,
        lifetimeSpent: 0,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  WalletBalance? get sgBalance => getBalance(WalletCurrency.sg);
  WalletBalance? get brlBalance => getBalance(WalletCurrency.brl);
  WalletBalance? get cashbackBalance => getBalance(WalletCurrency.cashback);
  WalletBalance? get loyaltyBalance => getBalance(WalletCurrency.loyalty);

  double get totalWalletValue {
    // Convert all balances to BRL equivalent for display
    // This would need proper exchange rates in a real implementation
    return totalSgCredits * 0.5 + // Assume 1 SG = R$ 0.50
        (brlBalance?.balance ?? 0) +
        totalCashback * 0.01 + // Assume 1 cashback point = R$ 0.01
        totalLoyaltyPoints * 0.005; // Assume 1 loyalty point = R$ 0.005
  }

  String get totalWalletValueDisplay =>
      'R\$ ${totalWalletValue.toStringAsFixed(2)}';

  bool get hasAnyBalance =>
      totalSgCredits > 0 ||
      totalCashback > 0 ||
      totalLoyaltyPoints > 0 ||
      (brlBalance?.balance ?? 0) > 0;
}
