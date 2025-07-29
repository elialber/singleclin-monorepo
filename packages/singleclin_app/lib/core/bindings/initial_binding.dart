import 'package:get/get.dart';
import 'package:singleclin_app/presentation/controllers/controllers.dart';

/// Initial binding for dependency injection
/// This binding is loaded when the app starts
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services that should be available throughout the app
    // These are initialized lazily (only when needed) to save memory
    
    // Theme controller - needs to be available immediately
    Get.put<ThemeController>(ThemeController());
    
    // Authentication controller - needs to be available immediately
    Get.put<AuthController>(AuthController());
    
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