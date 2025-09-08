import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/features/clinic_discovery/models/clinic.dart';
import 'package:singleclin_mobile/features/appointment_booking/widgets/clinic_image_carousel.dart';
import 'package:singleclin_mobile/features/appointment_booking/widgets/clinic_info_section.dart';
import 'package:singleclin_mobile/features/appointment_booking/widgets/action_buttons_section.dart';
import 'package:singleclin_mobile/features/appointment_booking/widgets/reviews_section.dart';
import 'package:singleclin_mobile/features/appointment_booking/widgets/subscription_section.dart';
import 'package:singleclin_mobile/features/appointment_booking/widgets/location_section.dart';
import 'package:singleclin_mobile/features/appointment_booking/widgets/social_media_section.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';

class AppointmentBookingScreen extends StatelessWidget {
  final Clinic clinic;

  const AppointmentBookingScreen({
    Key? key,
    required this.clinic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Navigation Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Back Button
                InkWell(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Clinic Name
                Expanded(
                  child: Text(
                    clinic.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                // Credits Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '120', // This should come from user state
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Image Carousel
                  ClinicImageCarousel(clinic: clinic),
                  
                  // Main Content Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Clinic Info Section
                        ClinicInfoSection(clinic: clinic),
                        
                        const SizedBox(height: 16),
                        
                        // Action Buttons (Save/Share)
                        ActionButtonsSection(clinic: clinic),
                        
                        const SizedBox(height: 24),
                        
                        // Reviews Section
                        ReviewsSection(clinic: clinic),
                        
                        const SizedBox(height: 24),
                        
                        // Subscription Section
                        SubscriptionSection(clinic: clinic),
                        
                        const SizedBox(height: 24),
                        
                        // Location Section
                        LocationSection(clinic: clinic),
                        
                        const SizedBox(height: 24),
                        
                        // Social Media Section
                        SocialMediaSection(clinic: clinic),
                        
                        // Bottom spacing for fixed CTA button
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Fixed Bottom CTA Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to time slots selection
                Get.toNamed('/appointment-slots', arguments: clinic);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Ver horários',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}