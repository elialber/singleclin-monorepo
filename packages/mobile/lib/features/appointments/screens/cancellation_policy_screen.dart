import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';
import 'package:singleclin_mobile/features/appointments/controllers/cancellation_controller.dart';
import 'package:singleclin_mobile/shared/widgets/custom_app_bar.dart';

/// Cancellation Policy Screen
/// Shows cancellation policy with refund calculator
class CancellationPolicyScreen extends GetView<CancellationController> {
  const CancellationPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Cancelar Agendamento'),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final appointment = controller.appointment;
        final calculation = controller.calculation;

        if (appointment == null) {
          return const Center(child: Text('Agendamento não encontrado'));
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppointmentSummary(appointment),
              const SizedBox(height: 16),
              _buildEmergencyToggle(),
              const SizedBox(height: 16),
              _buildCancellationReasons(),
              const SizedBox(height: 16),
              if (calculation != null) ...[
                _buildRefundCalculation(calculation),
                const SizedBox(height: 16),
              ],
              _buildPolicyInfo(),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  /// Build appointment summary
  Widget _buildAppointmentSummary(appointment) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agendamento para Cancelamento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            appointment.serviceName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            appointment.clinicName,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${appointment.formattedDate} às ${appointment.formattedTime}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 16,
                color: AppColors.sgPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                '${appointment.sgCreditsUsed.toStringAsFixed(0)} SG créditos utilizados',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sgPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build emergency toggle
  Widget _buildEmergencyToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de Cancelamento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => SwitchListTile(
              title: const Text(
                'Cancelamento por Emergência',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Emergências médicas podem ter reembolso total',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              value: controller.isEmergency,
              onChanged: controller.updateEmergencyStatus,
              activeThumbColor: AppColors.warning,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  /// Build cancellation reasons
  Widget _buildCancellationReasons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Motivo do Cancelamento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final reasons = controller.availableReasons;
            return Column(
              children: reasons
                  .map(
                    (reason) => RadioListTile<CancellationReason>(
                      title: Text(
                        reason.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: reason,
                      groupValue: controller.selectedReason,
                      onChanged: controller.updateSelectedReason,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            );
          }),
          Obx(() {
            if (controller.selectedReason == CancellationReason.other) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Descreva o motivo',
                    border: OutlineInputBorder(),
                    hintText: 'Digite o motivo específico...',
                  ),
                  maxLines: 3,
                  onChanged: controller.updateCustomReason,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  /// Build refund calculation
  Widget _buildRefundCalculation(calculation) {
    final color = Color(
      int.parse(calculation.refundColor.substring(1), radix: 16) + 0xFF000000,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                calculation.canCancel
                    ? Icons.info_outline
                    : Icons.warning_outlined,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  calculation.canCancel
                      ? 'Resumo do Reembolso'
                      : 'Cancelamento Não Permitido',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCalculationRow(
            'Tempo até o agendamento',
            calculation.timeDescription,
          ),
          const SizedBox(height: 8),
          _buildCalculationRow(
            'Porcentagem de reembolso',
            '${calculation.refundPercentage}%',
            valueColor: color,
          ),
          if (calculation.refundAmount > 0) ...[
            const SizedBox(height: 8),
            _buildCalculationRow(
              'Reembolso em SG créditos',
              '${calculation.refundAmount.toStringAsFixed(0)} SG',
              valueColor: AppColors.success,
              isHighlight: true,
            ),
          ],
          if (calculation.penalty > 0) ...[
            const SizedBox(height: 8),
            _buildCalculationRow(
              'Taxa de cancelamento',
              '${calculation.penalty.toStringAsFixed(0)} SG',
              valueColor: AppColors.error,
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              calculation.formattedMessage,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(
    String label,
    String value, {
    Color? valueColor,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 16 : 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Build policy information
  Widget _buildPolicyInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Política de Cancelamento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Regras de Reembolso:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildPolicyItem('48h antes', '100% de reembolso', AppColors.success),
          _buildPolicyItem(
            '24h antes',
            '80% de reembolso',
            AppColors.successLight,
          ),
          _buildPolicyItem('12h antes', '50% de reembolso', AppColors.warning),
          _buildPolicyItem('Menos de 12h', 'Sem reembolso', AppColors.error),
          const SizedBox(height: 12),
          const Text(
            '* Emergências médicas comprovadas podem ter reembolso total independente do prazo.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String time, String rule, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$time: $rule',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build bottom bar with cancel button
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Obx(() {
          final calculation = controller.calculation;
          final isFormValid = controller.isFormValid;
          final canCancel = calculation?.canCancel ?? false;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (calculation != null && !calculation.isFavorableRefund) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_outlined,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reembolso parcial ou sem reembolso',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: Get.back,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Voltar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          (canCancel && isFormValid && !controller.isProcessing)
                          ? controller.processCancellation
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: controller.isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Cancelar Agendamento'),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}
