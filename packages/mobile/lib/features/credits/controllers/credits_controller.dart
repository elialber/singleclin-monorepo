import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/credit_transaction_model.dart';
import '../models/subscription_plan.dart';
import '../models/wallet_balance.dart';
import '../../../core/constants/app_colors.dart';

class CreditsController extends GetxController {
  // Reactive variables
  final _isLoading = false.obs;
  final _sgBalance = 0.obs;
  final _lockedBalance = 0.obs;
  final _monthlyCreditsUsed = 0.obs;
  final _monthlyCreditsTotal = 0.obs;
  final _subscription = Rx<UserSubscription?>(null);
  final _recentTransactions = <CreditTransactionModel>[].obs;
  final _walletSummary = Rx<WalletSummary?>(null);

  // Getters
  bool get isLoading => _isLoading.value;
  int get sgBalance => _sgBalance.value;
  int get lockedBalance => _lockedBalance.value;
  int get availableBalance => sgBalance - lockedBalance;
  int get monthlyCreditsUsed => _monthlyCreditsUsed.value;
  int get monthlyCreditsTotal => _monthlyCreditsTotal.value;
  UserSubscription? get subscription => _subscription.value;
  List<CreditTransactionModel> get recentTransactions => _recentTransactions;
  WalletSummary? get walletSummary => _walletSummary.value;

  // Computed properties
  double get creditUsagePercentage {
    if (monthlyCreditsTotal <= 0) return 0;
    return (monthlyCreditsUsed / monthlyCreditsTotal) * 100;
  }

  bool get isLowBalance => availableBalance < 10;
  bool get isNearRenewal => subscription?.isNearRenewal ?? false;
  bool get hasActiveSubscription => subscription?.isActive ?? false;

  String get balanceDisplay => '$availableBalance SG';
  String get totalBalanceDisplay => '$sgBalance SG';
  String get lockedBalanceDisplay => '$lockedBalance SG bloqueados';

  String get usageDisplay => 
      '$monthlyCreditsUsed de $monthlyCreditsTotal créditos usados este mês';

  String get subscriptionStatusDisplay {
    if (subscription == null) return 'Sem assinatura';
    return subscription!.statusDisplayName;
  }

  String get nextRenewalDisplay {
    if (subscription == null) return '';
    return subscription!.nextBillingDisplayDate;
  }

  @override
  void onInit() {
    super.onInit();
    loadCreditsOverview();
    loadRecentTransactions();
    loadWalletSummary();
  }

  @override
  void onReady() {
    super.onReady();
    // Set up periodic refresh every 5 minutes
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    // Refresh data every 5 minutes when app is active
    ever(_isLoading, (loading) {
      if (!loading) {
        Future.delayed(const Duration(minutes: 5), () {
          if (!Get.isRegistered<CreditsController>()) return;
          refreshCreditsData();
        });
      }
    });
  }

  Future<void> loadCreditsOverview() async {
    try {
      _isLoading.value = true;
      
      // Mock API call - replace with actual API service
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data
      _sgBalance.value = 245;
      _lockedBalance.value = 15;
      _monthlyCreditsUsed.value = 68;
      _monthlyCreditsTotal.value = 200;
      
      // Mock subscription
      _subscription.value = UserSubscription(
        id: '1',
        userId: 'user123',
        planId: 'premium',
        status: SubscriptionStatus.active,
        billingCycle: SubscriptionBillingCycle.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        nextBillingDate: DateTime.now().add(const Duration(days: 15)),
        creditsBalance: _sgBalance.value,
        creditsUsedThisMonth: _monthlyCreditsUsed.value,
        creditsTotal: _monthlyCreditsTotal.value,
        amountPaid: 29.90,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
        plan: SubscriptionPlan(
          id: 'premium',
          name: 'Premium',
          description: 'Plano intermediário com mais créditos',
          monthlyCredits: 200,
          monthlyPrice: 29.90,
          annualPrice: 299.00,
          features: [
            'Agendamentos ilimitados',
            '200 créditos SG/mês',
            'Suporte prioritário',
            'Cancelamento de consultas grátis',
          ],
          isPopular: true,
          isActive: true,
          sortOrder: 2,
          category: 'premium',
        ),
      );
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível carregar os dados de créditos',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadRecentTransactions() async {
    try {
      // Mock API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      _recentTransactions.assignAll([
        CreditTransactionModel(
          id: '1',
          userId: 'user123',
          amount: 200,
          balanceAfter: 245,
          type: TransactionType.subscription,
          source: TransactionSource.monthlySubscription,
          description: 'Renovação da assinatura Premium',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        CreditTransactionModel(
          id: '2',
          userId: 'user123',
          amount: -25,
          balanceAfter: 220,
          type: TransactionType.spent,
          source: TransactionSource.appointmentBooking,
          description: 'Consulta - Dr. Silva Cardiologia',
          relatedEntityId: 'appointment123',
          relatedEntityType: 'appointment',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        CreditTransactionModel(
          id: '3',
          userId: 'user123',
          amount: 10,
          balanceAfter: 255,
          type: TransactionType.bonus,
          source: TransactionSource.referral,
          description: 'Bônus por indicação - Maria Silva',
          relatedEntityId: 'referral456',
          relatedEntityType: 'referral',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        CreditTransactionModel(
          id: '4',
          userId: 'user123',
          amount: -30,
          balanceAfter: 215,
          type: TransactionType.spent,
          source: TransactionSource.appointmentBooking,
          description: 'Exame - Clínica Vida Saudável',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
        CreditTransactionModel(
          id: '5',
          userId: 'user123',
          amount: 15,
          balanceAfter: 260,
          type: TransactionType.refunded,
          source: TransactionSource.appointmentCancel,
          description: 'Reembolso - Cancelamento de consulta',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ]);
      
    } catch (e) {
      print('Error loading recent transactions: $e');
    }
  }

  Future<void> loadWalletSummary() async {
    try {
      // Mock API call
      await Future.delayed(const Duration(milliseconds: 300));
      
      _walletSummary.value = WalletSummary(
        userId: 'user123',
        balances: [
          WalletBalance(
            id: 'sg_wallet',
            userId: 'user123',
            currency: WalletCurrency.sg,
            balance: _sgBalance.value.toDouble(),
            lockedBalance: _lockedBalance.value.toDouble(),
            lifetimeEarned: 1250.0,
            lifetimeSpent: 1005.0,
            lastUpdated: DateTime.now(),
          ),
          WalletBalance(
            id: 'cashback_wallet',
            userId: 'user123',
            currency: WalletCurrency.cashback,
            balance: 45.0,
            lifetimeEarned: 125.0,
            lifetimeSpent: 80.0,
            lastUpdated: DateTime.now(),
          ),
        ],
        recentTransactions: [],
        totalSgCredits: _sgBalance.value.toDouble(),
        totalCashback: 45.0,
        totalLoyaltyPoints: 23.0,
        monthlySgSpending: _monthlyCreditsUsed.value.toDouble(),
        monthlyCashbackEarned: 8.5,
        lastUpdated: DateTime.now(),
      );
      
    } catch (e) {
      print('Error loading wallet summary: $e');
    }
  }

  Future<void> refreshCreditsData() async {
    await Future.wait([
      loadCreditsOverview(),
      loadRecentTransactions(),
      loadWalletSummary(),
    ]);
  }

  Future<void> purchaseCredits(String packageId) async {
    try {
      _isLoading.value = true;
      
      // Mock purchase flow
      await Future.delayed(const Duration(seconds: 2));
      
      Get.snackbar(
        'Sucesso',
        'Créditos adicionados com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
      // Refresh data after purchase
      await refreshCreditsData();
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível processar a compra',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> changeSubscription(String planId) async {
    try {
      _isLoading.value = true;
      
      // Mock subscription change
      await Future.delayed(const Duration(seconds: 1));
      
      Get.snackbar(
        'Sucesso',
        'Plano alterado com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
      await refreshCreditsData();
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível alterar o plano',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> cancelSubscription() async {
    try {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Cancelar Assinatura'),
          content: const Text(
            'Tem certeza que deseja cancelar sua assinatura? '
            'Você manterá seus créditos atuais até o final do período.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Sim, Cancelar'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      _isLoading.value = true;
      
      // Mock cancellation
      await Future.delayed(const Duration(seconds: 1));
      
      Get.snackbar(
        'Assinatura Cancelada',
        'Sua assinatura será cancelada no final do período atual',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      await refreshCreditsData();
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível cancelar a assinatura',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void showLowBalanceWarning() {
    if (!isLowBalance) return;
    
    Get.snackbar(
      'Saldo Baixo',
      'Seus créditos SG estão acabando. Considere comprar mais créditos.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () => Get.toNamed('/buy-credits'),
        child: const Text('Comprar'),
      ),
    );
  }

  void showRenewalReminder() {
    if (!isNearRenewal) return;
    
    Get.snackbar(
      'Renovação Próxima',
      'Sua assinatura será renovada em breve',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      mainButton: TextButton(
        onPressed: () => Get.toNamed('/subscription-plans'),
        child: const Text('Gerenciar'),
      ),
    );
  }

  // Animation helpers for UI
  bool get shouldShowSparkleAnimation => sgBalance > _sgBalance.value;
  
  void triggerCreditAnimation() {
    // This can be used to trigger golden animations in UI
    update(['credit_animation']);
  }

  // ===== ENGAGEMENT MODULE INTEGRATION =====
  
  /// Award credits for writing a review
  Future<void> awardCreditsForReview(String reviewId, {bool hasPhotos = false}) async {
    try {
      final amount = hasPhotos ? 5 : 3; // 5 SG with photos, 3 SG without
      
      // Mock API call - replace with actual API service
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Update local balance
      _sgBalance.value += amount;
      
      // Add to transaction history
      final transaction = CreditTransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'user123',
        amount: amount,
        balanceAfter: _sgBalance.value,
        type: TransactionType.bonus,
        source: TransactionSource.reviewBonus,
        description: hasPhotos 
            ? 'Avaliação com fotos enviada'
            : 'Avaliação enviada',
        createdAt: DateTime.now(),
        relatedEntityId: reviewId,
        relatedEntityType: 'review',
      );
      
      _recentTransactions.insert(0, transaction);
      
      showEngagementAchievement(
        hasPhotos ? 'Avaliação completa com fotos!' : 'Avaliação enviada!',
        amount,
      );
      
    } catch (e) {
      print('Error awarding credits for review: $e');
    }
  }
  
  /// Award credits for community participation
  Future<void> awardCreditsForCommunityPost(String postId) async {
    try {
      const amount = 2; // 2 SG per community post
      
      // Mock API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Update local balance
      _sgBalance.value += amount;
      
      // Add to transaction history
      final transaction = CreditTransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'user123',
        amount: amount,
        balanceAfter: _sgBalance.value,
        type: TransactionType.bonus,
        source: TransactionSource.communityBonus,
        description: 'Participação na comunidade',
        createdAt: DateTime.now(),
        relatedEntityId: postId,
        relatedEntityType: 'community_post',
      );
      
      _recentTransactions.insert(0, transaction);
      
    } catch (e) {
      print('Error awarding credits for community post: $e');
    }
  }
  
  /// Award credits for valuable feedback
  Future<void> awardCreditsForFeedback(String feedbackId) async {
    try {
      const amount = 3; // 3 SG for valuable feedback
      
      // Mock API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Update local balance
      _sgBalance.value += amount;
      
      // Add to transaction history
      final transaction = CreditTransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'user123',
        amount: amount,
        balanceAfter: _sgBalance.value,
        type: TransactionType.bonus,
        source: TransactionSource.feedbackBonus,
        description: 'Feedback valioso enviado',
        createdAt: DateTime.now(),
        relatedEntityId: feedbackId,
        relatedEntityType: 'feedback',
      );
      
      _recentTransactions.insert(0, transaction);
      
      showEngagementAchievement('Feedback valioso!', amount);
      
    } catch (e) {
      print('Error awarding credits for feedback: $e');
    }
  }
  
  /// Award credits for community engagement
  Future<void> awardCreditsForCommunityEngagement(String action, String reference) async {
    try {
      int amount;
      String description;
      
      switch (action) {
        case 'helpful_comment':
          amount = 2;
          description = 'Comentário útil na comunidade';
          break;
        case 'event_participation':
          amount = 5;
          description = 'Participação em evento';
          break;
        case 'beta_testing':
          amount = 10;
          description = 'Participação em beta testing';
          break;
        default:
          amount = 1;
          description = 'Participação na comunidade';
      }
      
      // Mock API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Update local balance
      _sgBalance.value += amount;
      
      // Add to transaction history
      final transaction = CreditTransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'user123',
        amount: amount,
        balanceAfter: _sgBalance.value,
        type: TransactionType.bonus,
        source: TransactionSource.communityBonus,
        description: description,
        createdAt: DateTime.now(),
        relatedEntityId: reference,
        relatedEntityType: 'engagement',
      );
      
      _recentTransactions.insert(0, transaction);
      
      if (amount >= 5) {
        showEngagementAchievement(description, amount);
      }
      
    } catch (e) {
      print('Error awarding credits for community engagement: $e');
    }
  }
  
  /// Show engagement achievement notification
  void showEngagementAchievement(String achievement, int creditsEarned) {
    Get.snackbar(
      'Conquista Desbloqueada! 🎉',
      '$achievement\n+$creditsEarned SG adicionados à sua conta',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.military_tech,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
  
  /// Get engagement bonus multiplier based on user activity
  double getEngagementMultiplier() {
    final recentBonusTransactions = _recentTransactions
        .where((t) => t.type == TransactionType.bonus)
        .where((t) => DateTime.now().difference(t.createdAt).inDays <= 30)
        .length;
    
    if (recentBonusTransactions >= 20) return 1.5; // 50% bonus for very active users
    if (recentBonusTransactions >= 10) return 1.3; // 30% bonus for active users
    if (recentBonusTransactions >= 5) return 1.1;  // 10% bonus for regular users
    return 1.0; // No bonus for inactive users
  }
  
  /// Get user engagement level
  String getUserEngagementLevel() {
    final monthlyEngagement = getEngagementEarningsThisMonth();
    
    if (monthlyEngagement >= 50) return 'Usuário Super Ativo';
    if (monthlyEngagement >= 25) return 'Usuário Muito Ativo';
    if (monthlyEngagement >= 10) return 'Usuário Ativo';
    if (monthlyEngagement >= 5) return 'Usuário Regular';
    return 'Novo Usuário';
  }
  
  /// Get engagement earnings this month
  double getEngagementEarningsThisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    return _recentTransactions
        .where((t) => t.type == TransactionType.bonus)
        .where((t) => t.createdAt.isAfter(startOfMonth))
        .where((t) => _isEngagementTransaction(t))
        .fold(0.0, (sum, t) => sum + t.amount);
  }
  
  bool _isEngagementTransaction(CreditTransactionModel transaction) {
    final engagementKeywords = ['Avaliação', 'comunidade', 'Feedback', 'evento', 'beta'];
    return engagementKeywords.any((keyword) => transaction.description.contains(keyword));
  }
  
  /// Check if user can earn engagement credits today
  bool canEarnEngagementCredits(String type) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final todayCount = _recentTransactions
        .where((t) => t.createdAt.isAfter(startOfDay))
        .where((t) => t.description.contains(_getEngagementKeyword(type)))
        .length;
    
    // Limit daily earnings per type
    switch (type) {
      case 'review':
        return todayCount < 3; // Max 3 reviews per day
      case 'community':
        return todayCount < 5; // Max 5 community posts per day
      case 'feedback':
        return todayCount < 2; // Max 2 feedback per day
      default:
        return true;
    }
  }
  
  String _getEngagementKeyword(String type) {
    switch (type) {
      case 'review':
        return 'Avaliação';
      case 'community':
        return 'comunidade';
      case 'feedback':
        return 'Feedback';
      default:
        return '';
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}