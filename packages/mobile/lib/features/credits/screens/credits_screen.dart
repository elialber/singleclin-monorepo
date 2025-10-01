import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/features/credits/controllers/credits_controller.dart';
import 'package:singleclin_mobile/features/credits/widgets/credit_balance_card.dart';
import 'package:singleclin_mobile/features/credits/widgets/transaction_item.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreditsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Créditos SG'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Get.toNamed('/credit-history'),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.refreshCreditsData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main SG Balance Card with Golden Animation
                CreditBalanceCard(
                  balance: controller.sgBalance,
                  lockedBalance: controller.lockedBalance,
                  isLowBalance: controller.isLowBalance,
                  onTap: () => _showBalanceDetails(context, controller),
                ),

                const SizedBox(height: 24),

                // Subscription Status Card
                _buildSubscriptionCard(controller),

                const SizedBox(height: 24),

                // Monthly Usage Progress
                _buildUsageProgressCard(controller),

                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(controller),

                const SizedBox(height: 24),

                // Recent Transactions Section
                _buildRecentTransactionsSection(controller),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSubscriptionCard(CreditsController controller) {
    final subscription = controller.subscription;

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.card_membership,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription?.plan?.name ?? 'Sem Plano',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          controller.subscriptionStatusDisplay,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (controller.hasActiveSubscription)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ATIVO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (controller.hasActiveSubscription) ...[
                const SizedBox(height: 12),
                Text(
                  controller.nextRenewalDisplay,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
                if (controller.isNearRenewal) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.orange.shade200,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Renovação em breve',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.toNamed('/subscription-plans'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    controller.hasActiveSubscription
                        ? 'Gerenciar Plano'
                        : 'Escolher Plano',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageProgressCard(CreditsController controller) {
    final percentage = controller.creditUsagePercentage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: AppColors.sgPrimary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Uso Mensal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${percentage.toInt()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: percentage > 80 ? Colors.red : AppColors.sgPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 80 ? Colors.red : AppColors.sgPrimary,
                ),
              ),
            ),

            const SizedBox(height: 8),
            Text(
              controller.usageDisplay,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),

            if (percentage > 80) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.orange.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Seus créditos estão acabando este mês',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(CreditsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ações Rápidas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.add_circle_outline,
                label: 'Comprar\nCréditos',
                color: AppColors.sgPrimary,
                onTap: () => Get.toNamed('/buy-credits'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.share_outlined,
                label: 'Indicar\nAmigos',
                color: Colors.green,
                onTap: () => Get.toNamed('/referral-program'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Minha\nCarteira',
                color: Colors.blue,
                onTap: () => Get.toNamed('/wallet'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.history,
                label: 'Histórico\nCompleto',
                color: Colors.purple,
                onTap: () => Get.toNamed('/credit-history'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection(CreditsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Transações Recentes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => Get.toNamed('/credit-history'),
              child: const Text('Ver Todas'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (controller.recentTransactions.isEmpty)
          Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: const Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Nenhuma transação ainda',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Suas transações aparecerão aqui',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ...controller.recentTransactions.map(
            (transaction) => TransactionItem(
              transaction: transaction,
              onTap: () => _showTransactionDetails(transaction),
            ),
          ),
      ],
    );
  }

  void _showBalanceDetails(BuildContext context, CreditsController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: AppColors.sgGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Detalhes do Saldo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildDetailRow('Saldo Total', controller.totalBalanceDisplay),
            _buildDetailRow('Saldo Disponível', controller.balanceDisplay),
            if (controller.lockedBalance > 0)
              _buildDetailRow(
                'Saldo Bloqueado',
                controller.lockedBalanceDisplay,
              ),

            const SizedBox(height: 16),
            const Text(
              'Informações:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Créditos SG não expiram enquanto a assinatura estiver ativa',
            ),
            const Text(
              '• Saldo bloqueado são créditos reservados para agendamentos pendentes',
            ),
            const Text(
              '• Você recebe 2% de cashback em compras de créditos extras',
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Get.toNamed('/buy-credits');
                },
                child: const Text('Comprar Mais Créditos'),
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
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Get.theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(dynamic transaction) {
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
            Text(
              'Detalhes da Transação',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Text('Tipo: ${transaction.typeDisplayName}'),
            const SizedBox(height: 4),
            Text('Valor: ${transaction.amountDisplay}'),
            const SizedBox(height: 4),
            Text('Descrição: ${transaction.description}'),
            const SizedBox(height: 4),
            Text(
              'Data: ${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year}',
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: Get.back,
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, CreditsController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Atualizar Dados'),
              onTap: () {
                Navigator.pop(context);
                controller.refreshCreditsData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Configurar Notificações'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to notification settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Como Funcionam os Créditos'),
              onTap: () {
                Navigator.pop(context);
                _showCreditsHelp(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Falar com Suporte'),
              onTap: () {
                Navigator.pop(context);
                // Open support
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreditsHelp(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Como Funcionam os Créditos SG'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🎯 O que são Créditos SG?'),
              Text(
                'Créditos SG são a moeda virtual do SingleClin. Use-os para agendar consultas e procedimentos.',
              ),
              SizedBox(height: 12),

              Text('💰 Como Obter Créditos?'),
              Text(
                '• Assinatura mensal/anual\n• Compra de pacotes extras\n• Indicação de amigos (+10 SG)\n• Cashback (2% em compras)',
              ),
              SizedBox(height: 12),

              Text('⏰ Validade dos Créditos'),
              Text(
                'Créditos SG não expiram enquanto sua assinatura estiver ativa.',
              ),
              SizedBox(height: 12),

              Text('📊 Uso dos Créditos'),
              Text(
                'O valor varia por procedimento:\n• Consulta básica: 15-30 SG\n• Exames: 20-50 SG\n• Procedimentos: 30-100 SG',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Entendi')),
        ],
      ),
    );
  }
}
