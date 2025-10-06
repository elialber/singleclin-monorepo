import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';
import 'package:singleclin_mobile/features/profile/controllers/health_history_controller.dart';
import 'package:singleclin_mobile/features/profile/widgets/health_timeline.dart';
import 'package:singleclin_mobile/shared/widgets/custom_app_bar.dart';

/// Health History Screen
/// Shows medical history timeline with records and metrics
class HealthHistoryScreen extends GetView<HealthHistoryController> {
  const HealthHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Histórico de Saúde',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 12),
                    Text('Exportar Dados'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 20),
                    SizedBox(width: 12),
                    Text('Filtros'),
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

        return Column(
          children: [
            _buildStatsHeader(),
            _buildFilterChips(),
            Expanded(child: _buildHistoryTimeline()),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecordDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Build statistics header
  Widget _buildStatsHeader() {
    return Obx(() {
      final stats = controller.statistics;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          border: const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            _buildStatItem(
              'Total',
              stats['totalRecords'].toString(),
              AppColors.primary,
              Icons.folder,
            ),
            _buildStatItem(
              'Recentes',
              stats['recentRecords'].toString(),
              AppColors.success,
              Icons.schedule,
            ),
            _buildStatItem(
              'Pendentes',
              stats['followUpsDue'].toString(),
              AppColors.warning,
              Icons.notification_important,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build filter chips
  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(
          () => Row(
            children: [
              _buildFilterChip('Todos', HealthRecordType.other),
              const SizedBox(width: 8),
              ...HealthRecordType.values
                  .where((type) => type != HealthRecordType.other)
                  .map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(type.label, type),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, HealthRecordType type) {
    final isSelected = controller.selectedFilter == type;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        controller.updateFilter(type);
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }

  /// Build history timeline
  Widget _buildHistoryTimeline() {
    return Obx(() {
      final records = controller.filteredRecords;

      if (records.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: controller.refreshHealthHistory,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: HealthTimeline(
                record: records[index],
                onTap: () => _viewRecordDetails(records[index]),
                onEdit: () => _editRecord(records[index]),
                onArchive: () =>
                    controller.archiveHealthRecord(records[index].id),
                onDelete: () =>
                    controller.deleteHealthRecord(records[index].id),
              ),
            );
          },
        ),
      );
    });
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.lightGrey,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                size: 48,
                color: AppColors.mediumGrey,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum registro encontrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Seu histórico médico aparecerá aqui conforme você realiza procedimentos',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddRecordDialog,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Registro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle menu actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        controller.exportHealthData();
        break;
      case 'filter':
        _showFilterDialog();
        break;
    }
  }

  /// Show search dialog
  void _showSearchDialog() {
    final searchController = TextEditingController(
      text: controller.searchQuery,
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Pesquisar Histórico'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Digite o nome do procedimento...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: controller.updateSearchQuery,
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.updateSearchQuery('');
              Get.back();
            },
            child: const Text('Limpar'),
          ),
          ElevatedButton(onPressed: Get.back, child: const Text('OK')),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(onPressed: Get.back, icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Período',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Column(
                children: DateRange.values
                    .map(
                      (range) => RadioListTile<DateRange>(
                        title: Text(range.label),
                        value: range,
                        groupValue: controller.selectedDateRange,
                        onChanged: (value) {
                          if (value != null) {
                            controller.updateDateRange(value);
                          }
                        },
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: Get.back,
                child: const Text('Aplicar Filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show add record dialog
  void _showAddRecordDialog() {
    Get.snackbar(
      'Em Desenvolvimento',
      'Funcionalidade de adicionar registro será implementada em breve',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// View record details
  void _viewRecordDetails(record) {
    Get.dialog(
      AlertDialog(
        title: Text(record.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Descrição:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(record.description),
              const SizedBox(height: 12),
              Text(
                'Data: ${record.formattedDate}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (record.clinicName != null) ...[
                const SizedBox(height: 8),
                Text('Clínica: ${record.clinicName}'),
              ],
              if (record.professionalName != null) ...[
                const SizedBox(height: 8),
                Text('Profissional: ${record.professionalName}'),
              ],
              if (record.recommendations.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Recomendações:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...record.recommendations.map((rec) => Text('• $rec')),
              ],
            ],
          ),
        ),
        actions: [TextButton(onPressed: Get.back, child: const Text('Fechar'))],
      ),
    );
  }

  /// Edit record
  void _editRecord(record) {
    Get.snackbar(
      'Em Desenvolvimento',
      'Funcionalidade de editar registro será implementada em breve',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
