import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';
import 'package:singleclin_mobile/features/clinic_discovery/controllers/clinics_list_controller.dart';
import 'package:singleclin_mobile/features/clinic_services/screens/clinic_services_screen.dart';
import 'package:singleclin_mobile/shared/controllers/bottom_nav_controller.dart';
import 'package:singleclin_mobile/shared/widgets/custom_app_bar.dart';
import 'package:singleclin_mobile/shared/widgets/custom_bottom_nav.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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
      body: Column(
        children: [
          // Barra de busca
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar clínicas ou especialidades...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Lista de clínicas
          Expanded(
            child: Obx(() {
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
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        controller.searchQuery.value.isEmpty
                            ? Icons.business_outlined
                            : Icons.search_off,
                        size: 64,
                        color: AppColors.mediumGrey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.searchQuery.value.isEmpty
                            ? 'Nenhuma clínica disponível'
                            : 'Nenhuma clínica encontrada',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
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
          ),
        ],
      ),
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
            // Imagem principal / carousel
            ClinicImageCarousel(images: clinic.images),

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
                  const SizedBox(height: 6),
                  // Endereço da clínica
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.place,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          clinic.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.mediumGrey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.warning,
                        size: 18,
                      ),
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
                      const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 18,
                      ),
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
                      children: clinic.specializations.take(3).map<Widget>((
                        spec,
                      ) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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

class ClinicImageCarousel extends StatefulWidget {
  const ClinicImageCarousel({super.key, required this.images});

  final List<String> images;

  @override
  State<ClinicImageCarousel> createState() => _ClinicImageCarouselState();
}

class _ClinicImageCarouselState extends State<ClinicImageCarousel> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.images.isNotEmpty;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: hasImages
              ? SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.images.length,
                    itemBuilder: (context, index) {
                      final url = widget.images[index];
                      return Image.network(
                        url,
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

        // Indicadores e contador
        if (hasImages && widget.images.length > 1) ...[
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: widget.images.length,
                effect: const ExpandingDotsEffect(
                  activeDotColor: Colors.white,
                  dotColor: Colors.white54,
                  dotHeight: 6,
                  dotWidth: 6,
                  expansionFactor: 3,
                ),
              ),
            ),
          ),
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
                  const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.images.length}',
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
      ],
    );
  }
}
