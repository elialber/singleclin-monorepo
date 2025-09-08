import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/onboarding_controller.dart';
import '../../../shared/widgets/sg_credit_widget.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildPageView(),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Skip button
          Obx(() => AnimatedOpacity(
            opacity: controller.isLastStep ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: TextButton(
              onPressed: controller.isLastStep ? null : controller.skipToEnd,
              child: const Text(
                'Pular',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mediumGrey,
                ),
              ),
            ),
          )),
          
          // Progress indicator
          Expanded(
            child: Obx(() => _buildProgressIndicator()),
          ),
          
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'SC',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: List.generate(
              controller.onboardingSteps.length,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index == controller.onboardingSteps.length - 1 ? 0 : 8,
                  ),
                  height: 3,
                  decoration: BoxDecoration(
                    color: index <= controller.currentStep.value
                        ? AppColors.primary
                        : AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${controller.currentStep.value + 1} de ${controller.onboardingSteps.length}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mediumGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: controller.pageController,
      onPageChanged: controller.onPageChanged,
      itemCount: controller.onboardingSteps.length,
      itemBuilder: (context, index) {
        final step = controller.onboardingSteps[index];
        return _buildOnboardingPage(step);
      },
    );
  }

  Widget _buildOnboardingPage(step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Image/Animation section
          Expanded(
            flex: 3,
            child: AnimatedBuilder(
              animation: controller.animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: controller.getFadeAnimation(),
                  child: SlideTransition(
                    position: controller.getSlideAnimation(),
                    child: ScaleTransition(
                      scale: controller.getScaleAnimation(),
                      child: _buildStepContent(step),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Text section
          Expanded(
            flex: 2,
            child: AnimatedBuilder(
              animation: controller.animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: controller.getFadeAnimation(),
                  child: _buildTextContent(step),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(step) {
    // Special handling for SG credits step
    if (step.id == 1) {
      return _buildSgCreditsDemo();
    }
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.lightGrey.withOpacity(0.3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder for illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(
              _getStepIcon(step.id),
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          if (step.customData?['showCreditAnimation'] == true)
            _buildCreditAnimation(),
        ],
      ),
    );
  }

  Widget _buildSgCreditsDemo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mock SG Credit Widget for demonstration
        SgCreditWidget(
          credits: 1500,
          renewDate: DateTime.now().add(const Duration(days: 30)),
          showRenewInfo: true,
          onTap: () {
            Get.snackbar(
              'Créditos SG',
              'Use os créditos SG para agendar seus procedimentos!',
              backgroundColor: AppColors.sgPrimary,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              borderRadius: 12,
              margin: const EdgeInsets.all(16),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // Benefits list
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildBenefitItem(
                Icons.discount,
                'Descontos exclusivos',
                'Economize até 30% nos procedimentos',
              ),
              const Divider(height: 24),
              _buildBenefitItem(
                Icons.schedule,
                'Agendamento rápido',
                'Reserve em segundos, pague com SG',
              ),
              const Divider(height: 24),
              _buildBenefitItem(
                Icons.star,
                'Clínicas premium',
                'Acesso às melhores clínicas parceiras',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.sgPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.sgPrimary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.black,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mediumGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreditAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = (value - delay).clamp(0.0, 1.0);
            
            return Transform.scale(
              scale: animationValue,
              child: Container(
                width: 60 + (index * 20),
                height: 60 + (index * 20),
                decoration: BoxDecoration(
                  color: AppColors.sgPrimary.withOpacity(0.3 - (index * 0.1)),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildTextContent(step) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          step.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        Text(
          step.description,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.mediumGrey,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        
        // Special content for SG credits step
        if (step.id == 1) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.sgGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Moeda virtual dourada',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Navigation buttons
          Obx(() => Row(
            children: [
              // Back button
              if (!controller.isFirstStep)
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.previousStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.mediumGrey),
                    ),
                    child: const Text(
                      'Anterior',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mediumGrey,
                      ),
                    ),
                  ),
                ),
              
              if (!controller.isFirstStep) const SizedBox(width: 16),
              
              // Next/Complete button
              Expanded(
                flex: controller.isFirstStep ? 1 : 1,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          controller.isLastStep ? 'Começar' : 'Próximo',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          )),
          
          // Skip hint
          const SizedBox(height: 16),
          Obx(() => AnimatedOpacity(
            opacity: controller.isLastStep ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Text(
              'Você pode pular este tutorial a qualquer momento',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mediumGrey.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          )),
        ],
      ),
    );
  }

  IconData _getStepIcon(int stepId) {
    switch (stepId) {
      case 0:
        return Icons.waving_hand;
      case 1:
        return Icons.account_balance_wallet;
      case 2:
        return Icons.people;
      case 3:
        return Icons.calendar_today;
      default:
        return Icons.info;
    }
  }
}