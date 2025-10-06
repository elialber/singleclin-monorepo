import 'package:get/get.dart';
import 'package:singleclin_mobile/features/profile/controllers/documents_controller.dart';
import 'package:singleclin_mobile/features/profile/controllers/health_history_controller.dart';
import 'package:singleclin_mobile/features/profile/controllers/profile_controller.dart';

/// Profile Binding
/// Binds profile-related controllers for dependency injection
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Main profile controller
    Get.lazyPut<ProfileController>(ProfileController.new);

    // Health history controller
    Get.lazyPut<HealthHistoryController>(HealthHistoryController.new);

    // Documents controller
    Get.lazyPut<DocumentsController>(DocumentsController.new);
  }
}
