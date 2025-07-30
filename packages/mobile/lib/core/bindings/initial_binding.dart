import 'package:get/get.dart';
import 'package:mobile/presentation/controllers/controllers.dart';

/// Initial binding for dependency injection
/// This binding is loaded when the app starts
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services that should be available throughout the app
    // These are initialized lazily (only when needed) to save memory
    
    // Controllers that need to be available immediately
    Get
      ..put<ThemeController>(ThemeController())
      ..put<AuthController>(AuthController());
    
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