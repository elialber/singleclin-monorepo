import 'package:flutter/material.dart';
import '../models/credit_package.dart';
import '../../../core/constants/app_colors.dart';

class CreditPackageCard extends StatelessWidget {
  final CreditPackage package;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDetails;

  const CreditPackageCard({
    super.key,
    required this.package,
    this.isSelected = false,
    required this.onTap,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.sgPrimary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.sgPrimary.withOpacity(0.1),
                      AppColors.sgSecondary.withOpacity(0.05),
                    ],
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.sgGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${package.credits} SG',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (package.isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade500,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'POPULAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Title and description
              Text(
                package.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                package.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 16),

              // Pricing
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (package.hasDiscount) ...[
                    Text(
                      package.originalPriceDisplay,
                      style: TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    package.priceDisplay,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sgPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (package.hasDiscount)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Text(
                        package.discountDisplay,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                package.creditValueDisplay,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),

              if (package.isPromoValid) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department, 
                           color: Colors.orange.shade700, 
                           size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              package.promoDescription ?? 'Oferta especial!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              package.promoTimeRemainingDisplay,
                              style: TextStyle(
                                color: Colors.orange.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (isSelected) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.sgPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.sgPrimary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, 
                           color: AppColors.sgPrimary, 
                           size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Pacote selecionado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}