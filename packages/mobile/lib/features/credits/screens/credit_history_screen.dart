import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';
import 'package:singleclin_mobile/features/credits/controllers/credit_history_controller.dart';
import 'package:singleclin_mobile/shared/controllers/bottom_nav_controller.dart';
import 'package:singleclin_mobile/shared/widgets/custom_app_bar.dart';
import 'package:singleclin_mobile/shared/widgets/custom_bottom_nav.dart';

class CreditHistoryScreen extends GetView<CreditHistoryController> {
  const CreditHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('📱 CreditHistoryScreen.build() - Construindo tela');
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Histórico de Transações',
        showBackButton: false,
      ),
      body: Obx(_buildBody),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1, // CORRIGIDO: Index 1 = Transações
        onTap: (index) => Get.find<BottomNavController>().changePage(index),
      ),
    );
  }

  Widget _buildBody() {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (controller.error.isNotEmpty) {
      return _buildErrorState();
    }

    if (controller.transactions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.transactions.length,
        itemBuilder: (context, index) {
          final transaction = controller.transactions[index];
          return _buildTransactionCard(transaction);
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar transações',
              style: Get.textTheme.headlineSmall?.copyWith(
                color: AppColors.darkGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              controller.error,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppColors.mediumGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: controller.refresh,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.mediumGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma transação encontrada',
              style: Get.textTheme.headlineSmall?.copyWith(
                color: AppColors.darkGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Suas transações aparecerão aqui quando você começar a usar seus créditos',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppColors.mediumGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(dynamic transaction) {
    final isDebit = transaction.amount < 0;
    final absoluteAmount = transaction.amount.abs();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _showTransactionDetails(transaction);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDebit
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDebit
                      ? Icons.event_busy_outlined
                      : Icons.event_available_outlined,
                  color: isDebit ? AppColors.error : AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description ?? 'Transação',
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGrey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (transaction.clinicName != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.business_outlined,
                            size: 14,
                            color: AppColors.mediumGrey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              transaction.clinicName!,
                              style: Get.textTheme.bodySmall?.copyWith(
                                color: AppColors.mediumGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_outlined,
                          size: 14,
                          color: AppColors.mediumGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(transaction.createdAt),
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: AppColors.mediumGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isDebit ? '-' : '+'}$absoluteAmount',
                    style: Get.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDebit ? AppColors.error : AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'créditos',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumGrey,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        transaction.status,
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(transaction.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(transaction.status),
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(transaction.status),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(dynamic transaction) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color:
                        (transaction.amount < 0
                                ? AppColors.error
                                : AppColors.success)
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    transaction.amount < 0
                        ? Icons.event_busy
                        : Icons.event_available,
                    color: transaction.amount < 0
                        ? AppColors.error
                        : AppColors.success,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalhes da Transação',
                        style: Get.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        _formatDate(transaction.createdAt),
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: AppColors.mediumGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                  color: AppColors.mediumGrey,
                ),
              ],
            ),
            const Divider(height: 32),
            _buildDetailRow('Serviço', transaction.description ?? 'N/A'),
            if (transaction.clinicName != null)
              _buildDetailRow('Clínica', transaction.clinicName!),
            _buildDetailRow(
              'Créditos',
              '${transaction.amount < 0 ? '-' : '+'}${transaction.amount.abs()} créditos',
            ),
            _buildDetailRow('Status', _getStatusText(transaction.status)),
            _buildDetailRow('ID da Transação', transaction.id),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Fechar',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppColors.mediumGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppColors.darkGrey,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDay = DateTime(date.year, date.month, date.day);

    if (transactionDay == today) {
      return 'Hoje, ${_formatTime(date)}';
    } else if (transactionDay == today.subtract(const Duration(days: 1))) {
      return 'Ontem, ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
      case 'error':
        return AppColors.error;
      default:
        return AppColors.mediumGrey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return 'Concluído';
      case 'pending':
        return 'Pendente';
      case 'cancelled':
      case 'canceled':
        return 'Cancelado';
      case 'failed':
      case 'error':
        return 'Falhou';
      default:
        return 'Desconhecido';
    }
  }
}
