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
      appBar: const CustomAppBar(title: 'Clínicas', showBackButton: false),
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.clinics.length,
          itemBuilder: (context, index) {
            final clinic = controller.clinics[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () {
                  // Navigate to ClinicServicesScreen passing the clinic
                  Get.to(() => const ClinicServicesScreen(), arguments: clinic);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          clinic.imageUrl.isNotEmpty
                              ? clinic.imageUrl
                              : 'https://via.placeholder.com/60',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.local_hospital,
                                color: AppColors.primary,
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clinic.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: AppColors.warning, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  clinic.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                                const SizedBox(width: 2),
                                Text(
                                  '${clinic.distance.toStringAsFixed(1)} km',
                                  style: const TextStyle(color: AppColors.mediumGrey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mediumGrey),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (index) => Get.find<BottomNavController>().changePage(index),
      ),
    );
  }
}

