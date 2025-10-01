import 'package:flutter/material.dart';
import 'package:singleclin_mobile/features/clinic_services/models/clinic_service.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';

class ServiceListItem extends StatelessWidget {
  const ServiceListItem({
    Key? key,
    required this.service,
    required this.userCredits,
    required this.creditsLoaded,
    required this.onBookPressed,
  }) : super(key: key);
  final ClinicService service;
  final int userCredits;
  final bool creditsLoaded;
  final VoidCallback onBookPressed;

  @override
  Widget build(BuildContext context) {
    print(
      'DEBUG: ServiceListItem building for: ${service.name} - Price: ${service.price}',
    );
    final canAfford = userCredits >= service.price;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: service.isAvailable
              ? AppColors.divider
              : AppColors.error.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service image and basic info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: Container(
                  width: 80,
                  height: 80,
                  color: AppColors.surfaceVariant,
                  child: service.imageUrl != null
                      ? Image.network(
                          service.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                        )
                      : _buildPlaceholderImage(),
                ),
              ),

              // Service details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service name and availability
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              service.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: service.isAvailable
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!service.isAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Indisponível',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Category
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          service.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Price and duration
                      Row(
                        children: [
                          Text(
                            service.formattedPrice,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: canAfford
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            service.formattedDuration,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Description
          if (service.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                service.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Action buttons and status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Credits indicator - only show if credits are loaded and insufficient
                if (creditsLoaded && !canAfford && service.isAvailable)
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.warning, size: 16, color: AppColors.warning),
                        SizedBox(width: 4),
                        Text(
                          'Créditos insuficientes',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Spacer(),

                // Action button
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: service.isAvailable && canAfford
                        ? onBookPressed
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: service.isAvailable && canAfford
                          ? AppColors.primary
                          : AppColors.mediumGrey,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(
                      service.isAvailable ? 'Agendar' : 'Indisponível',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    IconData icon;
    switch (service.category.toLowerCase()) {
      case 'consulta':
        icon = Icons.medical_services;
        break;
      case 'exame':
        icon = Icons.biotech;
        break;
      case 'procedimento':
        icon = Icons.healing;
        break;
      default:
        icon = Icons.local_hospital;
    }

    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(child: Icon(icon, color: AppColors.primary, size: 32)),
    );
  }
}
