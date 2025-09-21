import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/clinic.dart';
import '../widgets/clinic_card.dart';
import '../controllers/clinic_discovery_controller.dart';
import '../../../core/constants/app_colors.dart';

class ClinicDiscoveryScreen extends StatelessWidget {
  const ClinicDiscoveryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ClinicDiscoveryController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, controller),
            _buildSearchBar(context, controller),
            _buildQuickFilters(controller),
            _buildActiveFiltersIndicator(controller),
            Expanded(
              child: _buildClinicList(controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ClinicDiscoveryController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Para você',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                  controller.isLoadingLocation
                      ? 'Localizando...'
                      : controller.selectedSpecializations.isEmpty
                          ? 'Clínicas próximas de você'
                          : '${controller.filteredClinics.length} clínicas encontradas',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                )),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showSearchModal(context, controller),
            icon: const Icon(Icons.search),
            iconSize: 28,
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ClinicDiscoveryController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller.searchController,
          onChanged: controller.searchClinics,
          decoration: InputDecoration(
            hintText: 'Buscar por categoria, serviço ou nome da clínica',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[500],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilters(ClinicDiscoveryController controller) {
    return Container(
      height: 60,
      color: Colors.white,
      child: Obx(() => ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.availableSpecializations.length,
        itemBuilder: (context, index) {
          final specialization = controller.availableSpecializations[index];
          final isSelected = controller.selectedSpecializations.contains(specialization);
          
          return Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: FilterChip(
              label: Text(
                specialization,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                print('🎯 Chip clicado: $specialization, selecionado: $selected');
                print('🏷️ Estado antes: ${controller.selectedSpecializations}');

                if (selected) {
                  controller.addSpecializationFilter(specialization);
                } else {
                  controller.removeSpecializationFilter(specialization);
                }

                print('🏷️ Estado depois: ${controller.selectedSpecializations}');
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              showCheckmark: false,
            ),
          );
        },
      )),
    );
  }

  Widget _buildActiveFiltersIndicator(ClinicDiscoveryController controller) {
    return Obx(() {
      if (controller.selectedSpecializations.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_list,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Filtrando por: ${controller.selectedSpecializations.join(", ")}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            TextButton(
              onPressed: controller.clearFilters,
              child: const Text(
                'Limpar',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildClinicList(ClinicDiscoveryController controller) {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (controller.filteredClinics.isEmpty) {
        return _buildEmptyState(controller);
      }

      return RefreshIndicator(
        onRefresh: controller.refreshClinics,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: controller.filteredClinics.length,
          itemBuilder: (context, index) {
            final clinic = controller.filteredClinics[index];
            return ClinicCard(
              clinic: clinic,
              onTap: () => _navigateToClinicDetails(clinic),
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(ClinicDiscoveryController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_hospital_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma clínica encontrada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente ajustar os filtros ou buscar por outro termo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.clearFilters,
            icon: const Icon(Icons.refresh),
            label: const Text('Limpar filtros'),
          ),
        ],
      ),
    );
  }


  void _showSearchModal(BuildContext context, ClinicDiscoveryController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Busca Avançada',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Advanced search options will be implemented here
            const Text('Recursos de busca avançada em desenvolvimento...'),
          ],
        ),
      ),
    );
  }

  void _navigateToClinicDetails(Clinic clinic) {
    Get.toNamed('/clinic-details', arguments: clinic);
  }


}