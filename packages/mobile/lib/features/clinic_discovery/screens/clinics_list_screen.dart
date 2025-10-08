import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';
import 'package:singleclin_mobile/features/clinic_discovery/controllers/clinics_list_controller.dart';
import 'package:singleclin_mobile/features/clinic_services/screens/clinic_services_screen.dart';
import 'package:singleclin_mobile/shared/controllers/bottom_nav_controller.dart';
import 'package:singleclin_mobile/shared/widgets/custom_app_bar.dart';
import 'package:singleclin_mobile/shared/widgets/custom_bottom_nav.dart';

class ClinicsListScreen extends StatelessWidget {
  const ClinicsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ClinicsListController());

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Descubra Clínicas',
        showBackButton: false,
      ),
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  controller.error.value,
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: controller.loadClinics,
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        if (controller.clinics.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business_outlined, size: 64, color: AppColors.mediumGrey),
                SizedBox(height: 16),
                Text(
                  'Nenhuma clínica disponível',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadClinics,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.clinics.length,
            itemBuilder: (context, index) {
              final clinic = controller.clinics[index];
              return _buildClinicCard(clinic);
            },
          ),
        );
      }),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (index) => Get.find<BottomNavController>().changePage(index),
      ),
    );
  }

  Widget _buildClinicCard(clinic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Get.to(() => const ClinicServicesScreen(), arguments: clinic);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem principal com carousel se houver múltiplas imagens
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: clinic.images.isNotEmpty
                      ? SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: PageView.builder(
                            itemCount: clinic.images.length,
                            itemBuilder: (context, imageIndex) {
                              return Image.network(
                                clinic.images[imageIndex],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    color: AppColors.surfaceVariant,
                                    child: const Icon(
                                      Icons.local_hospital,
                                      color: AppColors.primary,
                                      size: 60,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        )
                      : Container(
                          height: 200,
                          color: AppColors.surfaceVariant,
                          child: const Icon(
                            Icons.local_hospital,
                            color: AppColors.primary,
                            size: 60,
                          ),
                        ),
                ),
                // Indicador de múltiplas fotos
                if (clinic.images.length > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${clinic.images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            
            // Informações da clínica
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clinic.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.warning, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        clinic.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        ' (${clinic.reviewCount} avaliações)',
                        style: TextStyle(
                          color: AppColors.mediumGrey,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                      const SizedBox(width: 2),
                      Text(
                        '${clinic.distance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: AppColors.mediumGrey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (clinic.specializations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: clinic.specializations.take(3).map((spec) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            spec,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

