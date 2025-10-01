import 'package:get/get.dart';
import 'package:singleclin_mobile/features/onboarding/controllers/onboarding_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(OnboardingController.new, fenix: true);
  }
}
