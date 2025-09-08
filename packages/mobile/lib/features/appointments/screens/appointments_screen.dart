import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/appointments_controller.dart';
import '../widgets/appointment_card.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../core/constants/app_colors.dart';

/// Appointments Screen
/// Main appointments management screen with tabbed interface
class AppointmentsScreen extends GetView<AppointmentsController> {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Meus Agendamentos',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsHeader(),
          _buildTabBar(),
          Expanded(
            child: _buildTabBarView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/discovery'),
        icon: const Icon(Icons.add),
        label: const Text('Novo Agendamento'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Build statistics header
  Widget _buildStatsHeader() {
    return Obx(() {
      final stats = controller.appointmentStats;
      
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          border: Border(
            bottom: BorderSide(
              color: AppColors.divider,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildStatItem(
              'Próximos',
              stats['upcoming'].toString(),
              AppColors.primary,
              Icons.schedule,
            ),
            _buildStatItem(
              'Realizados',
              stats['completed'].toString(),
              AppColors.success,
              Icons.check_circle,
            ),
            _buildStatItem(
              'Cancelados',
              stats['cancelled'].toString(),
              AppColors.error,
              Icons.cancel,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build tab bar
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: controller.tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Próximos'),
          Tab(text: 'Histórico'),
          Tab(text: 'Cancelados'),
        ],
      ),
    );
  }

  /// Build tab bar view
  Widget _buildTabBarView() {
    return TabBarView(
      controller: controller.tabController,
      children: [
        _buildUpcomingTab(),
        _buildHistoryTab(),
        _buildCancelledTab(),
      ],
    );
  }

  /// Build upcoming appointments tab
  Widget _buildUpcomingTab() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final appointments = controller.upcomingAppointments;

      if (appointments.isEmpty) {
        return _buildEmptyState(
          icon: Icons.schedule,
          title: 'Nenhum agendamento próximo',
          subtitle: 'Que tal agendar seu próximo procedimento?',
          actionText: 'Explorar Serviços',
          onAction: () => Get.toNamed('/discovery'),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshAppointments,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppointmentCard(
                appointment: appointments[index],
                onTap: () => _navigateToDetails(appointments[index]),
                onCancel: () => controller.cancelAppointment(appointments[index].id),
                onReschedule: () => controller.rescheduleAppointment(appointments[index].id),
              ),
            );
          },
        ),
      );
    });
  }

  /// Build history tab
  Widget _buildHistoryTab() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final appointments = controller.historyAppointments;

      if (appointments.isEmpty) {
        return _buildEmptyState(
          icon: Icons.history,
          title: 'Nenhum histórico encontrado',
          subtitle: 'Seus procedimentos realizados aparecerão aqui',
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshAppointments,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppointmentCard(
                appointment: appointments[index],
                onTap: () => _navigateToDetails(appointments[index]),
                onRate: appointments[index].canRate 
                    ? () => controller.rateAppointment(appointments[index].id)
                    : null,
              ),
            );
          },
        ),
      );
    });
  }

  /// Build cancelled tab
  Widget _buildCancelledTab() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final appointments = controller.cancelledAppointments;

      if (appointments.isEmpty) {
        return _buildEmptyState(
          icon: Icons.cancel_outlined,
          title: 'Nenhum cancelamento',
          subtitle: 'Agendamentos cancelados aparecerão aqui',
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshAppointments,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppointmentCard(
                appointment: appointments[index],
                onTap: () => _navigateToDetails(appointments[index]),
                showRefundInfo: true,
              ),
            );
          },
        ),
      );
    });
  }

  /// Build empty state
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.mediumGrey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Navigate to appointment details
  void _navigateToDetails(appointment) {
    Get.toNamed('/appointments/details', arguments: appointment);
  }

  /// Show search dialog
  void _showSearchDialog() {
    final searchController = TextEditingController(text: controller.searchQuery);
    
    Get.dialog(
      AlertDialog(
        title: const Text('Pesquisar Agendamentos'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Digite o nome do serviço ou clínica...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => controller.updateSearchQuery(value),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.updateSearchQuery('');
              Get.back();
            },
            child: const Text('Limpar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show filter dialog
  void _showFilterDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Em breve: Filtros por data, tipo de serviço e status'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Aplicar Filtros'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}