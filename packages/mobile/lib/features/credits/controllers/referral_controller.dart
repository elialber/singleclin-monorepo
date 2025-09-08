import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/referral.dart';

class ReferralController extends GetxController {
  // Reactive variables
  final _isLoading = false.obs;
  final _isGeneratingCode = false.obs;
  final _referralProgram = Rx<ReferralProgram?>(null);
  final _referrals = <Referral>[].obs;
  final _stats = <String, dynamic>{}.obs;
  final _leaderboard = <Map<String, dynamic>>[].obs;
  
  // Getters
  bool get isLoading => _isLoading.value;
  bool get isGeneratingCode => _isGeneratingCode.value;
  ReferralProgram? get referralProgram => _referralProgram.value;
  List<Referral> get referrals => _referrals;
  Map<String, dynamic> get stats => _stats;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  
  String get referralCode => referralProgram?.referralCode ?? '';
  String get qrCodeUrl => referralProgram?.qrCodeUrl ?? '';
  int get totalReferrals => referralProgram?.totalReferrals ?? 0;
  int get approvedReferrals => referralProgram?.approvedReferrals ?? 0;
  int get pendingReferrals => referralProgram?.pendingReferrals ?? 0;
  int get totalCreditsEarned => referralProgram?.totalCreditsEarned ?? 0;
  int get bonusCredits => referralProgram?.bonusCredits ?? 10;
  int get currentRanking => referralProgram?.currentRanking ?? 0;
  String get rankingTier => referralProgram?.rankingTier ?? 'bronze';
  
  String get shareMessage => referralProgram?.shareMessage ?? '';
  String get shareUrl => referralProgram?.shareUrl ?? '';
  double get conversionRate => referralProgram?.conversionRate ?? 0;
  String get conversionRateDisplay => referralProgram?.conversionRateDisplay ?? '0%';
  
  List<Referral> get recentReferrals => referralProgram?.recentReferrals ?? [];
  int get thisMonthReferrals => referralProgram?.thisMonthReferrals ?? 0;
  bool get isTopPerformer => referralProgram?.isTopPerformer ?? false;
  
  Map<String, dynamic> get nextTierRequirements => referralProgram?.nextTierRequirements ?? {};

  @override
  void onInit() {
    super.onInit();
    loadReferralProgram();
    loadReferralStats();
    loadLeaderboard();
  }

  Future<void> loadReferralProgram() async {
    try {
      _isLoading.value = true;
      
      // Mock API call
      await Future.delayed(const Duration(seconds: 1));
      
      _referralProgram.value = ReferralProgram(
        id: 'ref_123',
        userId: 'user_123',
        referralCode: 'SINGLECLIN2024',
        qrCodeUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=https://singleclin.com/app?ref=SINGLECLIN2024',
        bonusCredits: 10,
        totalReferrals: 12,
        approvedReferrals: 8,
        pendingReferrals: 2,
        totalCreditsEarned: 80,
        referrals: _generateMockReferrals(),
        monthlyStats: {
          '2024-01': 2,
          '2024-02': 4,
          '2024-03': 6,
        },
        currentRanking: 15,
        rankingTier: 'silver',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now(),
      );
      
      _referrals.assignAll(_referralProgram.value?.referrals ?? []);
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível carregar os dados de indicação',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadReferralStats() async {
    try {
      // Mock API call for additional stats
      await Future.delayed(const Duration(milliseconds: 500));
      
      _stats.assignAll({
        'totalPotentialCredits': totalReferrals * bonusCredits,
        'successRate': approvedReferrals / (totalReferrals > 0 ? totalReferrals : 1) * 100,
        'averagePerMonth': totalReferrals / 3, // last 3 months
        'nextTierCreditsNeeded': _calculateNextTierCreditsNeeded(),
        'monthlyTrend': 'up', // 'up', 'down', 'stable'
        'bestMonth': '2024-03',
        'bestMonthCount': 6,
      });
      
    } catch (e) {
      print('Error loading referral stats: $e');
    }
  }

  Future<void> loadLeaderboard() async {
    try {
      // Mock leaderboard data
      await Future.delayed(const Duration(milliseconds: 300));
      
      _leaderboard.assignAll([
        {
          'rank': 1,
          'name': 'Maria Silva',
          'referrals': 45,
          'tier': 'platinum',
          'isCurrentUser': false,
        },
        {
          'rank': 2,
          'name': 'João Santos',
          'referrals': 38,
          'tier': 'gold',
          'isCurrentUser': false,
        },
        {
          'rank': 3,
          'name': 'Ana Costa',
          'referrals': 32,
          'tier': 'gold',
          'isCurrentUser': false,
        },
        // ... more entries
        {
          'rank': 15,
          'name': 'Você',
          'referrals': approvedReferrals,
          'tier': rankingTier,
          'isCurrentUser': true,
        },
        // ... more entries
      ]);
      
    } catch (e) {
      print('Error loading leaderboard: $e');
    }
  }

  Future<void> generateNewReferralCode() async {
    if (_isGeneratingCode.value) return;
    
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Gerar Novo Código'),
        content: const Text(
          'Deseja gerar um novo código de indicação? '
          'O código atual ficará inválido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Gerar Novo'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      _isGeneratingCode.value = true;
      
      // Mock code generation
      await Future.delayed(const Duration(seconds: 2));
      
      // Generate new code (mock)
      final newCode = 'SINGLE${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      
      // Update referral program
      _referralProgram.value = _referralProgram.value!.copyWith(
        referralCode: newCode,
        qrCodeUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=https://singleclin.com/app?ref=$newCode',
        updatedAt: DateTime.now(),
      );
      
      Get.snackbar(
        'Novo Código Gerado!',
        'Seu novo código de indicação: $newCode',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 4),
      );
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível gerar um novo código',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isGeneratingCode.value = false;
    }
  }

  Future<void> shareReferralCode() async {
    try {
      await Share.share(
        shareMessage,
        subject: 'Conheça o SingleClin!',
      );
      
      // Track share action for analytics
      _trackShare('general');
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível compartilhar o código',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> shareViaWhatsApp() async {
    try {
      final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent(shareMessage)}';
      
      // In a real app, you would use url_launcher here
      Get.snackbar(
        'WhatsApp',
        'Abrindo WhatsApp para compartilhar...',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      _trackShare('whatsapp');
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível abrir o WhatsApp',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> shareViaInstagram() async {
    try {
      // Mock Instagram sharing
      Get.snackbar(
        'Instagram',
        'Abrindo Instagram Stories para compartilhar...',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      _trackShare('instagram');
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível abrir o Instagram',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> shareViaSMS() async {
    try {
      // Mock SMS sharing
      Get.snackbar(
        'SMS',
        'Abrindo app de mensagens...',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      _trackShare('sms');
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível abrir o SMS',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> shareViaEmail() async {
    try {
      // Mock email sharing
      Get.snackbar(
        'Email',
        'Abrindo app de email...',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      _trackShare('email');
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível abrir o email',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> copyReferralCode() async {
    try {
      // In a real app, you would use Clipboard.setData here
      Get.snackbar(
        'Código Copiado!',
        'Código $referralCode copiado para a área de transferência',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
      _trackShare('copy');
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível copiar o código',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> copyShareLink() async {
    try {
      // In a real app, you would use Clipboard.setData here
      Get.snackbar(
        'Link Copiado!',
        'Link de indicação copiado para a área de transferência',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
      _trackShare('copy_link');
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível copiar o link',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void showReferralDetails(Referral referral) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Indicação #${referral.id.substring(0, 8)}',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(referral.status),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow('Usuário', referral.displayName),
            _buildDetailRow('Data da Indicação', 
              '${referral.referredAt.day}/${referral.referredAt.month}/${referral.referredAt.year}'),
            _buildDetailRow('Créditos', referral.creditsDisplay),
            
            if (referral.isApproved) ...[
              _buildDetailRow('Aprovada em', 
                referral.approvedAt != null 
                  ? '${referral.approvedAt!.day}/${referral.approvedAt!.month}/${referral.approvedAt!.year}'
                  : 'N/A'),
            ] else if (referral.isRejected) ...[
              const SizedBox(height: 8),
              Text(
                'Motivo da Rejeição:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              Text(
                referral.rejectionReason ?? 'Não informado',
                style: TextStyle(color: Colors.red.shade600),
              ),
            ],
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ReferralStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case ReferralStatus.pending:
        color = Colors.orange;
        text = 'Pendente';
        break;
      case ReferralStatus.approved:
        color = Colors.green;
        text = 'Aprovada';
        break;
      case ReferralStatus.rejected:
        color = Colors.red;
        text = 'Rejeitada';
        break;
      case ReferralStatus.expired:
        color = Colors.grey;
        text = 'Expirada';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void showLeaderboard() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        height: Get.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.leaderboard, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Ranking de Indicadores',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView.builder(
                itemCount: leaderboard.length,
                itemBuilder: (context, index) {
                  final entry = leaderboard[index];
                  final isCurrentUser = entry['isCurrentUser'] ?? false;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrentUser 
                          ? Get.theme.primaryColor.withOpacity(0.1)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrentUser
                          ? Border.all(color: Get.theme.primaryColor, width: 2)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _getRankColor(entry['rank']),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entry['rank']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry['name'],
                                style: TextStyle(
                                  fontWeight: isCurrentUser 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                ),
                              ),
                              Text(
                                '${entry['referrals']} indicações',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildTierBadge(entry['tier']),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank <= 3) return Colors.amber;
    if (rank <= 10) return Get.theme.primaryColor;
    return Colors.grey;
  }

  Widget _buildTierBadge(String tier) {
    Color color;
    switch (tier.toLowerCase()) {
      case 'platinum':
        color = Colors.purple;
        break;
      case 'gold':
        color = Colors.amber;
        break;
      case 'silver':
        color = Colors.grey;
        break;
      default:
        color = Colors.brown;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        tier.toUpperCase(),
        style: TextStyle(
          color: color.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  int _calculateNextTierCreditsNeeded() {
    switch (rankingTier.toLowerCase()) {
      case 'bronze':
        return (5 * bonusCredits) - totalCreditsEarned;
      case 'silver':
        return (15 * bonusCredits) - totalCreditsEarned;
      case 'gold':
        return (50 * bonusCredits) - totalCreditsEarned;
      default:
        return 0;
    }
  }

  void _trackShare(String method) {
    // Mock analytics tracking
    final shareData = {
      'method': method,
      'referral_code': referralCode,
      'user_id': 'user_123',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    print('Share tracked: $shareData');
  }

  // Mock data generation
  List<Referral> _generateMockReferrals() {
    return [
      Referral(
        id: 'ref_001',
        referralProgramId: 'ref_123',
        referredUserId: 'user_001',
        referredUserName: 'Maria Silva',
        referredUserEmail: 'maria@example.com',
        creditsEarned: 10,
        status: ReferralStatus.approved,
        referredAt: DateTime.now().subtract(const Duration(days: 5)),
        approvedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Referral(
        id: 'ref_002',
        referralProgramId: 'ref_123',
        referredUserId: 'user_002',
        referredUserName: 'João Santos',
        creditsEarned: 10,
        status: ReferralStatus.pending,
        referredAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Referral(
        id: 'ref_003',
        referralProgramId: 'ref_123',
        referredUserId: 'user_003',
        referredUserName: 'Ana Costa',
        creditsEarned: 0,
        status: ReferralStatus.rejected,
        rejectionReason: 'Usuário já cadastrado anteriormente',
        referredAt: DateTime.now().subtract(const Duration(days: 10)),
        rejectedAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
    ];
  }

  @override
  void onClose() {
    super.onClose();
  }
}

// Extension to add copyWith method to ReferralProgram
extension ReferralProgramCopyWith on ReferralProgram {
  ReferralProgram copyWith({
    String? referralCode,
    String? qrCodeUrl,
    DateTime? updatedAt,
  }) {
    return ReferralProgram(
      id: id,
      userId: userId,
      referralCode: referralCode ?? this.referralCode,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      bonusCredits: bonusCredits,
      totalReferrals: totalReferrals,
      approvedReferrals: approvedReferrals,
      pendingReferrals: pendingReferrals,
      totalCreditsEarned: totalCreditsEarned,
      referrals: referrals,
      monthlyStats: monthlyStats,
      currentRanking: currentRanking,
      rankingTier: rankingTier,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}