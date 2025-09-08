import 'package:get/get.dart';
import '../../features/auth/controllers/auth_controller.dart';

/// Initial binding for dependency injection
/// This binding is loaded when the app starts
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services that should be available throughout the app
    // These are initialized lazily (only when needed) to save memory

    // Controllers that need to be available immediately
    Get.put<AuthController>(AuthController(), permanent: true);

    // Example: Local storage service
    // Get.lazyPut<StorageService>(() => StorageService());

    // Example: API client
    // Get.lazyPut<ApiClient>(() => ApiClient());

    // Example: Analytics service
    // Get.lazyPut<AnalyticsService>(() => AnalyticsService());

    // Put services that need to be immediately available
    // Get.put<AppConfig>(AppConfig());
  }
}
