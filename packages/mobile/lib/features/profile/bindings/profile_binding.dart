import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../controllers/health_history_controller.dart';
import '../controllers/documents_controller.dart';

/// Profile Binding
/// Binds profile-related controllers for dependency injection
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Main profile controller
    Get.lazyPut<ProfileController>(
      () => ProfileController(),
    );
    
    // Health history controller
    Get.lazyPut<HealthHistoryController>(
      () => HealthHistoryController(),
    );
    
    // Documents controller
    Get.lazyPut<DocumentsController>(
      () => DocumentsController(),
    );
  }
}