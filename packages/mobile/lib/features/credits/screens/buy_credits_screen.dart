import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/buy_credits_controller.dart';
import '../widgets/credit_package_card.dart';
import '../../../core/constants/app_colors.dart';

class BuyCreditsScreen extends StatelessWidget {
  const BuyCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BuyCreditsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprar Créditos SG'),
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Header with golden theme
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.sgGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.add_card,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Escolha o Pacote Ideal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Créditos extras para seus procedimentos',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Packages list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.packages.length,
                itemBuilder: (context, index) {
                  final package = controller.packages[index];
                  return CreditPackageCard(
                    package: package,
                    isSelected: controller.selectedPackage?.id == package.id,
                    onTap: () => controller.selectPackage(package),
                    onDetails: () => controller.showPackageDetails(package),
                  );
                },
              ),
            ),

            // Purchase section
            if (controller.selectedPackage != null)
              Container(
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
                child: Column(
                  children: [
                    // Promo code input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Código promocional',
                              prefixIcon: const Icon(Icons.local_offer),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onSubmitted: controller.applyPromoCode,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Price summary
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (controller.appliedDiscount > 0) ...[
                              Text(
                                controller.selectedPackage!.priceDisplay,
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              controller.finalPriceDisplay,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.sgPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Purchase button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: controller.canPurchase && !controller.isProcessingPurchase
                            ? controller.purchaseCredits
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sgPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: controller.isProcessingPurchase
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Comprar ${controller.selectedPackage!.credits} Créditos SG',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }
}