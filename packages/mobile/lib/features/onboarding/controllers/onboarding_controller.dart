import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/core/services/storage_service.dart';
import 'package:singleclin_mobile/features/onboarding/models/onboarding_step.dart';

class OnboardingController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late PageController pageController;
  late AnimationController animationController;

  // Observables
  final RxInt currentStep = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isFirstLaunch = true.obs;

  // Services
  final StorageService _storageService = Get.find<StorageService>();

  // Constants
  static const String _firstLaunchKey = 'first_launch';
  static const Duration _animationDuration = Duration(milliseconds: 500);

  @override
  void onInit() {
    super.onInit();
    _initControllers();
    _checkFirstLaunch();
  }

  @override
  void onClose() {
    pageController.dispose();
    animationController.dispose();
    super.onClose();
  }

  /// Initialize controllers
  void _initControllers() {
    pageController = PageController();
    animationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );
    animationController.forward();
  }

  /// Check if this is the first app launch
  Future<void> _checkFirstLaunch() async {
    try {
      isLoading.value = true;
      final hasSeenOnboarding =
          await _storageService.getBool(_firstLaunchKey) ?? false;
      isFirstLaunch.value = !hasSeenOnboarding;
    } catch (e) {
      print('Error checking first launch: $e');
      isFirstLaunch.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get onboarding steps
  List<OnboardingStep> get onboardingSteps => [
    const OnboardingStep(
      id: 0,
      title: 'Bem-vindo ao SingleClin',
      description:
          'Descubra a nova forma de cuidar da sua estética e saúde com tecnologia e praticidade.',
      imageAsset: 'assets/images/onboarding/welcome.png',
      lottieAsset: 'assets/animations/welcome.json',
    ),
    const OnboardingStep(
      id: 1,
      title: 'Créditos SG',
      description:
          'Use nossos créditos dourados SG para agendar procedimentos nas melhores clínicas parceiras.',
      imageAsset: 'assets/images/onboarding/sg_credits.png',
      lottieAsset: 'assets/animations/credits.json',
      customData: {'highlightColor': '#FFB000', 'showCreditAnimation': true},
    ),
    const OnboardingStep(
      id: 2,
      title: 'Encontre Especialistas',
      description:
          'Conecte-se com profissionais qualificados em estética, injetáveis e saúde preventiva.',
      imageAsset: 'assets/images/onboarding/specialists.png',
      lottieAsset: 'assets/animations/specialists.json',
    ),
    const OnboardingStep(
      id: 3,
      title: 'Agende com Facilidade',
      description:
          'Marque seus procedimentos de forma rápida e segura, tudo pelo app.',
      imageAsset: 'assets/images/onboarding/booking.png',
      lottieAsset: 'assets/animations/booking.json',
    ),
  ];

  /// Get current onboarding step
  OnboardingStep get currentOnboardingStep =>
      onboardingSteps[currentStep.value];

  /// Check if is last step
  bool get isLastStep => currentStep.value == onboardingSteps.length - 1;

  /// Check if is first step
  bool get isFirstStep => currentStep.value == 0;

  /// Get progress percentage
  double get progressPercentage =>
      (currentStep.value + 1) / onboardingSteps.length;

  /// Navigate to next step
  Future<void> nextStep() async {
    if (isLastStep) {
      await completeOnboarding();
      return;
    }

    try {
      animationController.reset();
      await pageController.nextPage(
        duration: _animationDuration,
        curve: Curves.easeInOut,
      );
      animationController.forward();
    } catch (e) {
      print('Error navigating to next step: $e');
    }
  }

  /// Navigate to previous step
  Future<void> previousStep() async {
    if (isFirstStep) return;

    try {
      animationController.reset();
      await pageController.previousPage(
        duration: _animationDuration,
        curve: Curves.easeInOut,
      );
      animationController.forward();
    } catch (e) {
      print('Error navigating to previous step: $e');
    }
  }

  /// Skip to last step
  Future<void> skipToEnd() async {
    try {
      animationController.reset();
      await pageController.animateToPage(
        onboardingSteps.length - 1,
        duration: _animationDuration,
        curve: Curves.easeInOut,
      );
      animationController.forward();
    } catch (e) {
      print('Error skipping to end: $e');
    }
  }

  /// Navigate to specific step
  Future<void> goToStep(int step) async {
    if (step < 0 || step >= onboardingSteps.length) return;

    try {
      animationController.reset();
      await pageController.animateToPage(
        step,
        duration: _animationDuration,
        curve: Curves.easeInOut,
      );
      animationController.forward();
    } catch (e) {
      print('Error navigating to step $step: $e');
    }
  }

  /// Update current step when page changes
  void onPageChanged(int page) {
    currentStep.value = page;
  }

  /// Complete onboarding process
  Future<void> completeOnboarding() async {
    try {
      isLoading.value = true;

      // Mark onboarding as completed
      await _storageService.setBool(_firstLaunchKey, true);

      // Navigate to dashboard with replacement
      Get.offAllNamed('/dashboard');
    } catch (e) {
      print('Error completing onboarding: $e');
      Get.snackbar(
        'Erro',
        'Ocorreu um erro ao finalizar o tutorial. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset onboarding (for testing purposes)
  Future<void> resetOnboarding() async {
    try {
      await _storageService.remove(_firstLaunchKey);
      isFirstLaunch.value = true;
      currentStep.value = 0;
      await goToStep(0);
    } catch (e) {
      print('Error resetting onboarding: $e');
    }
  }

  /// Check if should show onboarding
  bool shouldShowOnboarding() {
    return isFirstLaunch.value;
  }

  /// Get fade animation for current step
  Animation<double> getFadeAnimation() {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeIn),
    );
  }

  /// Get slide animation for current step
  Animation<Offset> getSlideAnimation() {
    return Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOutBack),
    );
  }

  /// Get scale animation for current step
  Animation<double> getScaleAnimation() {
    return Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.elasticOut),
    );
  }

  /// Vibrate device for feedback
  void _hapticFeedback() {
    // HapticFeedback.lightImpact();
  }

  /// Log onboarding analytics
  void _logStep(int step) {
    // Analytics.track('onboarding_step_viewed', {'step': step});
  }
}
