import 'package:get/get.dart';
import '../models/wallet_balance.dart';

class WalletController extends GetxController {
  // Reactive variables
  final _isLoading = false.obs;
  final _isProcessingTransfer = false.obs;
  final _walletSummary = Rx<WalletSummary?>(null);
  final _recentTransactions = <WalletTransaction>[].obs;
  final _selectedCurrency = WalletCurrency.sg.obs;
  final _notifications = <Map<String, dynamic>>[].obs;

  // Transfer form states
  final _transferFromCurrency = WalletCurrency.sg.obs;
  final _transferToCurrency = WalletCurrency.brl.obs;
  final _transferAmount = 0.0.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isProcessingTransfer => _isProcessingTransfer.value;
  WalletSummary? get walletSummary => _walletSummary.value;
  List<WalletTransaction> get recentTransactions => _recentTransactions;
  WalletCurrency get selectedCurrency => _selectedCurrency.value;
  List<Map<String, dynamic>> get notifications => _notifications;
  
  // Transfer getters
  WalletCurrency get transferFromCurrency => _transferFromCurrency.value;
  WalletCurrency get transferToCurrency => _transferToCurrency.value;
  double get transferAmount => _transferAmount.value;

  // Balance getters
  WalletBalance? get sgBalance => walletSummary?.sgBalance;
  WalletBalance? get brlBalance => walletSummary?.brlBalance;
  WalletBalance? get cashbackBalance => walletSummary?.cashbackBalance;
  WalletBalance? get loyaltyBalance => walletSummary?.loyaltyBalance;

  double get totalSgCredits => walletSummary?.totalSgCredits ?? 0;
  double get totalCashback => walletSummary?.totalCashback ?? 0;
  double get totalLoyaltyPoints => walletSummary?.totalLoyaltyPoints ?? 0;
  double get monthlySgSpending => walletSummary?.monthlySgSpending ?? 0;
  double get monthlyCashbackEarned => walletSummary?.monthlyCashbackEarned ?? 0;
  
  String get totalWalletValueDisplay => walletSummary?.totalWalletValueDisplay ?? 'R\$ 0,00';
  bool get hasAnyBalance => walletSummary?.hasAnyBalance ?? false;

  List<WalletBalance> get availableBalances => walletSummary?.balances ?? [];

  bool get canTransfer => _canTransfer();

  @override
  void onInit() {
    super.onInit();
    loadWalletSummary();
    loadRecentTransactions();
    loadNotifications();
  }

  Future<void> loadWalletSummary() async {
    try {
      _isLoading.value = true;
      
      // Mock API call
      await Future.delayed(const Duration(seconds: 1));
      
      final balances = [
        WalletBalance(
          id: 'sg_wallet',
          userId: 'user_123',
          currency: WalletCurrency.sg,
          balance: 245.0,
          lockedBalance: 15.0,
          lifetimeEarned: 1250.0,
          lifetimeSpent: 1020.0,
          lastUpdated: DateTime.now(),
        ),
        WalletBalance(
          id: 'brl_wallet',
          userId: 'user_123',
          currency: WalletCurrency.brl,
          balance: 123.45,
          lifetimeEarned: 500.00,
          lifetimeSpent: 376.55,
          lastUpdated: DateTime.now(),
        ),
        WalletBalance(
          id: 'cashback_wallet',
          userId: 'user_123',
          currency: WalletCurrency.cashback,
          balance: 45.0,
          lifetimeEarned: 125.0,
          lifetimeSpent: 80.0,
          lastUpdated: DateTime.now(),
        ),
        WalletBalance(
          id: 'loyalty_wallet',
          userId: 'user_123',
          currency: WalletCurrency.loyalty,
          balance: 23.0,
          lifetimeEarned: 50.0,
          lifetimeSpent: 27.0,
          lastUpdated: DateTime.now(),
        ),
      ];
      
      _walletSummary.value = WalletSummary(
        userId: 'user_123',
        balances: balances,
        recentTransactions: _recentTransactions,
        totalSgCredits: 245.0,
        totalCashback: 45.0,
        totalLoyaltyPoints: 23.0,
        monthlySgSpending: 68.0,
        monthlyCashbackEarned: 8.5,
        lastUpdated: DateTime.now(),
      );
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível carregar os dados da carteira',
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
        WalletTransaction(
          id: 'wtx_001',
          walletId: 'sg_wallet',
          userId: 'user_123',
          type: WalletTransactionType.subscription,
          currency: WalletCurrency.sg,
          amount: 200.0,
          balanceAfter: 245.0,
          description: 'Renovação da assinatura Premium',
          referenceId: 'sub_123',
          referenceType: 'subscription',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        WalletTransaction(
          id: 'wtx_002',
          walletId: 'sg_wallet',
          userId: 'user_123',
          type: WalletTransactionType.debit,
          currency: WalletCurrency.sg,
          amount: 25.0,
          balanceAfter: 220.0,
          description: 'Consulta - Dr. Silva Cardiologia',
          referenceId: 'booking_456',
          referenceType: 'booking',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        WalletTransaction(
          id: 'wtx_003',
          walletId: 'cashback_wallet',
          userId: 'user_123',
          type: WalletTransactionType.cashback,
          currency: WalletCurrency.cashback,
          amount: 2.5,
          balanceAfter: 45.0,
          description: 'Cashback - Compra de créditos',
          referenceId: 'purchase_789',
          referenceType: 'purchase',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        WalletTransaction(
          id: 'wtx_004',
          walletId: 'sg_wallet',
          userId: 'user_123',
          type: WalletTransactionType.bonus,
          currency: WalletCurrency.sg,
          amount: 10.0,
          balanceAfter: 255.0,
          description: 'Bônus por indicação - Maria Silva',
          referenceId: 'ref_321',
          referenceType: 'referral',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        WalletTransaction(
          id: 'wtx_005',
          walletId: 'brl_wallet',
          userId: 'user_123',
          type: WalletTransactionType.transfer,
          currency: WalletCurrency.brl,
          amount: 50.0,
          balanceAfter: 123.45,
          description: 'Transferência recebida',
          referenceId: 'transfer_654',
          referenceType: 'transfer',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ]);
      
    } catch (e) {
      print('Error loading recent transactions: $e');
    }
  }

  Future<void> loadNotifications() async {
    try {
      // Mock notification loading
      await Future.delayed(const Duration(milliseconds: 300));
      
      _notifications.assignAll([
        {
          'id': 'notif_001',
          'type': 'low_balance',
          'title': 'Saldo Baixo',
          'message': 'Seus créditos SG estão acabando',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'isRead': false,
          'priority': 'high',
        },
        {
          'id': 'notif_002',
          'type': 'cashback_earned',
          'title': 'Cashback Recebido',
          'message': 'Você ganhou 2,5 pontos de cashback',
          'timestamp': DateTime.now().subtract(const Duration(days: 1)),
          'isRead': true,
          'priority': 'medium',
        },
        {
          'id': 'notif_003',
          'type': 'transfer_completed',
          'title': 'Transferência Concluída',
          'message': 'Transferência de R$ 50,00 foi processada',
          'timestamp': DateTime.now().subtract(const Duration(days: 3)),
          'isRead': true,
          'priority': 'low',
        },
      ]);
      
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  void selectCurrency(WalletCurrency currency) {
    _selectedCurrency.value = currency;
    update(['currency_selection']);
  }

  void setTransferFromCurrency(WalletCurrency currency) {
    _transferFromCurrency.value = currency;
    // Ensure we can't transfer to the same currency
    if (_transferToCurrency.value == currency) {
      final availableCurrencies = WalletCurrency.values.where((c) => c != currency).toList();
      if (availableCurrencies.isNotEmpty) {
        _transferToCurrency.value = availableCurrencies.first;
      }
    }
    update(['transfer_form']);
  }

  void setTransferToCurrency(WalletCurrency currency) {
    _transferToCurrency.value = currency;
    update(['transfer_form']);
  }

  void setTransferAmount(double amount) {
    _transferAmount.value = amount;
    update(['transfer_form']);
  }

  bool _canTransfer() {
    if (transferAmount <= 0) return false;
    if (transferFromCurrency == transferToCurrency) return false;
    
    final fromBalance = _getBalanceByCurrency(transferFromCurrency);
    if (fromBalance == null) return false;
    
    return fromBalance.canSpend(transferAmount);
  }

  WalletBalance? _getBalanceByCurrency(WalletCurrency currency) {
    return availableBalances.firstWhere(
      (balance) => balance.currency == currency,
      orElse: () => WalletBalance(
        id: '',
        userId: '',
        currency: currency,
        balance: 0,
        lifetimeEarned: 0,
        lifetimeSpent: 0,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  Future<void> transferFunds() async {
    if (!canTransfer) {
      Get.snackbar(
        'Erro',
        'Não é possível realizar a transferência',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      _isProcessingTransfer.value = true;
      
      // Show confirmation dialog
      final confirmed = await _showTransferConfirmation();
      if (!confirmed) return;
      
      // Show processing dialog
      Get.dialog(
        AlertDialog(
          title: const Text('Processando Transferência'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Aguarde enquanto processamos sua transferência...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );
      
      // Mock transfer processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Close processing dialog
      Get.back();
      
      // Show success dialog
      Get.dialog(
        AlertDialog(
          title: const Text('✅ Transferência Realizada!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transferência de ${_formatAmount(transferAmount, transferFromCurrency)} concluída com sucesso!'),
              const SizedBox(height: 8),
              Text('De: ${_getCurrencyDisplayName(transferFromCurrency)}'),
              Text('Para: ${_getCurrencyDisplayName(transferToCurrency)}'),
              Text('Valor convertido: ${_formatAmount(_calculateConvertedAmount(), transferToCurrency)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                _resetTransferForm();
                refreshWalletData();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      Get.back(); // Close any open dialog
      Get.snackbar(
        'Erro',
        'Não foi possível processar a transferência',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isProcessingTransfer.value = false;
    }
  }

  Future<bool> _showTransferConfirmation() async {
    final convertedAmount = _calculateConvertedAmount();
    final exchangeRate = _getExchangeRate(transferFromCurrency, transferToCurrency);
    
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar Transferência'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('De: ${_getCurrencyDisplayName(transferFromCurrency)}'),
            Text('Para: ${_getCurrencyDisplayName(transferToCurrency)}'),
            const SizedBox(height: 8),
            Text('Valor a transferir: ${_formatAmount(transferAmount, transferFromCurrency)}'),
            Text('Valor a receber: ${_formatAmount(convertedAmount, transferToCurrency)}'),
            const SizedBox(height: 8),
            Text(
              'Taxa de câmbio: $exchangeRate',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Confirmar Transferência'),
          ),
        ],
      ),
    );
    
    return confirmed ?? false;
  }

  double _calculateConvertedAmount() {
    final exchangeRate = _getExchangeRate(transferFromCurrency, transferToCurrency);
    return transferAmount * exchangeRate;
  }

  double _getExchangeRate(WalletCurrency from, WalletCurrency to) {
    // Mock exchange rates - in a real app, these would come from an API
    if (from == WalletCurrency.sg && to == WalletCurrency.brl) {
      return 0.50; // 1 SG = R$ 0.50
    } else if (from == WalletCurrency.brl && to == WalletCurrency.sg) {
      return 2.0; // R$ 1.00 = 2 SG
    } else if (from == WalletCurrency.cashback && to == WalletCurrency.brl) {
      return 0.01; // 1 cashback point = R$ 0.01
    } else if (from == WalletCurrency.loyalty && to == WalletCurrency.sg) {
      return 0.5; // 1 loyalty point = 0.5 SG
    }
    return 1.0; // Default 1:1 rate
  }

  String _formatAmount(double amount, WalletCurrency currency) {
    switch (currency) {
      case WalletCurrency.sg:
        return '${amount.toInt()} SG';
      case WalletCurrency.brl:
        return 'R\$ ${amount.toStringAsFixed(2)}';
      case WalletCurrency.cashback:
        return '${amount.toInt()} pts cashback';
      case WalletCurrency.loyalty:
        return '${amount.toInt()} pts fidelidade';
    }
  }

  String _getCurrencyDisplayName(WalletCurrency currency) {
    switch (currency) {
      case WalletCurrency.sg:
        return 'Créditos SG';
      case WalletCurrency.brl:
        return 'Real Brasileiro';
      case WalletCurrency.cashback:
        return 'Cashback';
      case WalletCurrency.loyalty:
        return 'Pontos de Fidelidade';
    }
  }

  void _resetTransferForm() {
    _transferFromCurrency.value = WalletCurrency.sg;
    _transferToCurrency.value = WalletCurrency.brl;
    _transferAmount.value = 0.0;
    update(['transfer_form']);
  }

  Future<void> refreshWalletData() async {
    await Future.wait([
      loadWalletSummary(),
      loadRecentTransactions(),
      loadNotifications(),
    ]);
  }

  void showTransactionDetails(WalletTransaction transaction) {
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
                  'Transação #${transaction.id.substring(0, 8)}',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  transaction.amountDisplay,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: transaction.isCredit 
                        ? Colors.green.shade600 
                        : Colors.red.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildTransactionDetailRow('Tipo', transaction.typeDisplayName),
            _buildTransactionDetailRow('Descrição', transaction.description),
            _buildTransactionDetailRow('Data', 
              '${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year} ${transaction.createdAt.hour}:${transaction.createdAt.minute.toString().padLeft(2, '0')}'),
            _buildTransactionDetailRow('Saldo após', transaction.balanceAfterDisplay),
            
            if (transaction.referenceId != null)
              _buildTransactionDetailRow('Referência', transaction.referenceId!),
            
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

  Widget _buildTransactionDetailRow(String label, String value) {
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

  void markNotificationAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n['id'] == notificationId);
    if (index != -1) {
      _notifications[index]['isRead'] = true;
      _notifications.refresh();
    }
  }

  void clearAllNotifications() {
    _notifications.clear();
    Get.snackbar(
      'Notificações',
      'Todas as notificações foram removidas',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  List<Map<String, dynamic>> get unreadNotifications => 
      _notifications.where((n) => n['isRead'] == false).toList();

  int get unreadNotificationsCount => unreadNotifications.length;

  @override
  void onClose() {
    super.onClose();
  }
}