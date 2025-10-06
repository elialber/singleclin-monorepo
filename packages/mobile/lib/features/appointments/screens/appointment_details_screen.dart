import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';
import 'package:singleclin_mobile/features/appointments/controllers/appointment_details_controller.dart';
import 'package:singleclin_mobile/features/appointments/widgets/status_timeline.dart';
import 'package:singleclin_mobile/shared/widgets/custom_app_bar.dart';

/// Appointment Details Screen
/// Shows detailed appointment information with timeline and actions
class AppointmentDetailsScreen extends GetView<AppointmentDetailsController> {
  const AppointmentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Detalhes do Agendamento',
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: controller.shareAppointment,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 12),
                    Text('Baixar Comprovante'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'contact',
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 20),
                    SizedBox(width: 12),
                    Text('Contatar Clínica'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'location',
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 20),
                    SizedBox(width: 12),
                    Text('Ver Localização'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final appointment = controller.appointment;
        if (appointment == null) {
          return const Center(child: Text('Agendamento não encontrado'));
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainInfo(appointment),
              const SizedBox(height: 16),
              _buildTimeline(),
              const SizedBox(height: 16),
              _buildInstructions(),
              const SizedBox(height: 16),
              _buildClinicInfo(appointment),
              const SizedBox(height: 16),
              _buildPriceBreakdown(appointment),
              const SizedBox(height: 24),
              _buildActions(),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  /// Build main appointment information
  Widget _buildMainInfo(appointment) {
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.serviceName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.getCategoryColor(
                          appointment.categoryName,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        appointment.categoryName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getCategoryColor(
                            appointment.categoryName,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              appointment.status.statusBadge(fontSize: 14),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            icon: Icons.calendar_today,
            title: 'Data e Horário',
            value:
                '${appointment.formattedDate} às ${appointment.formattedTime}',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            title: 'Clínica',
            value: appointment.clinicName,
          ),
          if (appointment.professionalName != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.person_outline,
              title: 'Profissional',
              value: appointment.professionalName!,
            ),
          ],
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.schedule,
            title: 'Duração',
            value:
                '${appointment.metadata?['procedureDuration'] ?? 60} minutos',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build timeline widget
  Widget _buildTimeline() {
    return Obx(() {
      final timeline = controller.timeline;
      if (timeline.isEmpty) return const SizedBox.shrink();

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
              'Timeline do Agendamento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            StatusTimeline(events: timeline),
          ],
        ),
      );
    });
  }

  /// Build instructions section
  Widget _buildInstructions() {
    return Obx(() {
      final instructions = controller.currentInstructions;
      if (instructions.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.info.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 20),
                SizedBox(width: 8),
                Text(
                  'Instruções Importantes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...instructions.map(
              (instruction) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  instruction,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Build clinic information section
  Widget _buildClinicInfo(appointment) {
    final address = appointment.metadata?['clinicAddress'] as String?;
    final phone = appointment.metadata?['clinicPhone'] as String?;
    final parking = appointment.metadata?['parkingAvailable'] as bool?;
    final wheelchair = appointment.metadata?['wheelchairAccessible'] as bool?;

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
            'Informações da Clínica',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (address != null) ...[
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              title: 'Endereço',
              value: address,
            ),
            const SizedBox(height: 12),
          ],
          if (phone != null) ...[
            _buildInfoRow(
              icon: Icons.phone_outlined,
              title: 'Telefone',
              value: phone,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              if (parking ?? false) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_parking,
                        size: 14,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Estacionamento',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (wheelchair ?? false) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.accessible, size: 14, color: AppColors.info),
                      SizedBox(width: 4),
                      Text(
                        'Acessível',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Build price breakdown
  Widget _buildPriceBreakdown(appointment) {
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
            'Detalhes do Pagamento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow(
            'Valor do serviço',
            'R\$ ${appointment.price.toStringAsFixed(2)}',
          ),
          if (appointment.sgCreditsUsed > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              'SG Créditos utilizados',
              '- ${appointment.sgCreditsUsed.toStringAsFixed(0)} SG',
              color: AppColors.sgPrimary,
            ),
          ],
          const Divider(height: 24),
          _buildPriceRow(
            'Total pago',
            'R\$ ${(appointment.price - (appointment.sgCreditsUsed * 0.01)).toStringAsFixed(2)}',
            isTotal: true,
          ),
          if (appointment.sgCreditsEarned > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.sgGradient.colors.first.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.add_circle,
                    color: AppColors.sgPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Você ganhará ${appointment.sgCreditsEarned.toStringAsFixed(0)} SG créditos após o procedimento',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.sgPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    Color? color,
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Build action buttons
  Widget _buildActions() {
    return Obx(() {
      final actions = controller.availableActions;
      if (actions.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            if (actions.length <= 2)
              Row(
                children: actions
                    .map(
                      (action) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: actions.indexOf(action) < actions.length - 1
                                ? 12
                                : 0,
                          ),
                          child: _buildActionButton(action),
                        ),
                      ),
                    )
                    .toList(),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: actions
                    .map(
                      (action) => SizedBox(
                        width: (Get.width - 44) / 2,
                        child: _buildActionButton(action),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildActionButton(action) {
    final color = Color(
      int.parse(action.color.substring(1), radix: 16) + 0xFF000000,
    );
    final icon = _getIconData(action.icon);

    return OutlinedButton.icon(
      onPressed: action.action,
      icon: Icon(icon, size: 18),
      label: Text(action.title),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  /// Handle menu actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'download':
        controller.downloadReceipt();
        break;
      case 'contact':
        controller.contactClinic();
        break;
      case 'location':
        controller.openClinicLocation();
        break;
    }
  }

  /// Get icon data from string
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'cancel':
        return Icons.cancel_outlined;
      case 'event':
        return Icons.event;
      case 'star':
        return Icons.star;
      case 'share':
        return Icons.share;
      case 'download':
        return Icons.download;
      default:
        return Icons.help_outline;
    }
  }
}
