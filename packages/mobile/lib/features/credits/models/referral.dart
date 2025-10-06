enum ReferralStatus { pending, approved, rejected, expired }

class Referral {
  Referral({
    required this.id,
    required this.referralProgramId,
    required this.referredUserId,
    required this.creditsEarned,
    required this.status,
    required this.referredAt,
    this.referredUserName,
    this.referredUserEmail,
    this.rejectionReason,
    this.approvedAt,
    this.rejectedAt,
    this.expiresAt,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'] ?? '',
      referralProgramId: json['referralProgramId'] ?? '',
      referredUserId: json['referredUserId'] ?? '',
      referredUserName: json['referredUserName'],
      referredUserEmail: json['referredUserEmail'],
      creditsEarned: json['creditsEarned'] ?? 0,
      status: ReferralStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ReferralStatus.pending,
      ),
      rejectionReason: json['rejectionReason'],
      referredAt: DateTime.parse(json['referredAt']),
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.parse(json['rejectedAt'])
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
    );
  }
  final String id;
  final String referralProgramId;
  final String referredUserId;
  final String? referredUserName;
  final String? referredUserEmail;
  final int creditsEarned;
  final ReferralStatus status;
  final String? rejectionReason;
  final DateTime referredAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referralProgramId': referralProgramId,
      'referredUserId': referredUserId,
      'referredUserName': referredUserName,
      'referredUserEmail': referredUserEmail,
      'creditsEarned': creditsEarned,
      'status': status.toString().split('.').last,
      'rejectionReason': rejectionReason,
      'referredAt': referredAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  String get statusDisplayName {
    switch (status) {
      case ReferralStatus.pending:
        return 'Pendente';
      case ReferralStatus.approved:
        return 'Aprovada';
      case ReferralStatus.rejected:
        return 'Rejeitada';
      case ReferralStatus.expired:
        return 'Expirada';
    }
  }

  bool get isPending => status == ReferralStatus.pending;
  bool get isApproved => status == ReferralStatus.approved;
  bool get isRejected => status == ReferralStatus.rejected;
  bool get isExpired => status == ReferralStatus.expired;

  bool get isActive => isApproved && !isExpired;

  String get displayName => referredUserName ?? referredUserEmail ?? 'Usuário';

  String get creditsDisplay => '+$creditsEarned SG';
}

class ReferralProgram {
  ReferralProgram({
    required this.id,
    required this.userId,
    required this.referralCode,
    required this.qrCodeUrl,
    required this.bonusCredits,
    required this.totalReferrals,
    required this.approvedReferrals,
    required this.pendingReferrals,
    required this.totalCreditsEarned,
    required this.referrals,
    required this.monthlyStats,
    required this.currentRanking,
    required this.createdAt,
    required this.updatedAt,
    this.rankingTier,
  });

  factory ReferralProgram.fromJson(Map<String, dynamic> json) {
    return ReferralProgram(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      referralCode: json['referralCode'] ?? '',
      qrCodeUrl: json['qrCodeUrl'] ?? '',
      bonusCredits: json['bonusCredits'] ?? 10,
      totalReferrals: json['totalReferrals'] ?? 0,
      approvedReferrals: json['approvedReferrals'] ?? 0,
      pendingReferrals: json['pendingReferrals'] ?? 0,
      totalCreditsEarned: json['totalCreditsEarned'] ?? 0,
      referrals: json['referrals'] != null
          ? List<Referral>.from(
              json['referrals'].map((x) => Referral.fromJson(x)),
            )
          : [],
      monthlyStats: json['monthlyStats'] != null
          ? Map<String, int>.from(json['monthlyStats'])
          : {},
      currentRanking: json['currentRanking'] ?? 0,
      rankingTier: json['rankingTier'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
  final String id;
  final String userId;
  final String referralCode;
  final String qrCodeUrl;
  final int bonusCredits;
  final int totalReferrals;
  final int approvedReferrals;
  final int pendingReferrals;
  final int totalCreditsEarned;
  final List<Referral> referrals;
  final Map<String, int> monthlyStats; // month -> referrals count
  final int currentRanking;
  final String? rankingTier; // 'bronze', 'silver', 'gold', 'platinum'
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'referralCode': referralCode,
      'qrCodeUrl': qrCodeUrl,
      'bonusCredits': bonusCredits,
      'totalReferrals': totalReferrals,
      'approvedReferrals': approvedReferrals,
      'pendingReferrals': pendingReferrals,
      'totalCreditsEarned': totalCreditsEarned,
      'referrals': referrals.map((x) => x.toJson()).toList(),
      'monthlyStats': monthlyStats,
      'currentRanking': currentRanking,
      'rankingTier': rankingTier,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get shareMessage {
    return 'Conheça o SingleClin! Use meu código $referralCode e ganhe $bonusCredits créditos SG grátis para seus primeiros procedimentos. Baixe agora: https://singleclin.com/app';
  }

  String get shareUrl => 'https://singleclin.com/app?ref=$referralCode';

  double get conversionRate {
    if (totalReferrals <= 0) return 0;
    return (approvedReferrals / totalReferrals) * 100;
  }

  String get conversionRateDisplay => '${conversionRate.toStringAsFixed(1)}%';

  String get rankingTierDisplayName {
    switch (rankingTier?.toLowerCase()) {
      case 'bronze':
        return 'Bronze';
      case 'silver':
        return 'Prata';
      case 'gold':
        return 'Ouro';
      case 'platinum':
        return 'Platina';
      default:
        return 'Sem classificação';
    }
  }

  int get thisMonthReferrals {
    final currentMonth =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    return monthlyStats[currentMonth] ?? 0;
  }

  bool get isTopPerformer => currentRanking <= 10;

  List<Referral> get recentReferrals {
    final sorted = List<Referral>.from(referrals)
      ..sort((a, b) => b.referredAt.compareTo(a.referredAt));
    return sorted.take(5).toList();
  }

  // Next tier requirements
  Map<String, dynamic> get nextTierRequirements {
    switch (rankingTier?.toLowerCase()) {
      case null:
      case 'bronze':
        return {'tier': 'Prata', 'referralsNeeded': 5 - approvedReferrals};
      case 'silver':
        return {'tier': 'Ouro', 'referralsNeeded': 15 - approvedReferrals};
      case 'gold':
        return {'tier': 'Platina', 'referralsNeeded': 50 - approvedReferrals};
      default:
        return {'tier': 'Platina', 'referralsNeeded': 0};
    }
  }
}
