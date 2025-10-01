import 'package:get/get.dart';
import 'package:singleclin_mobile/core/services/storage_service.dart';
import 'package:singleclin_mobile/core/services/api_service.dart';
import 'package:singleclin_mobile/core/services/auth_service.dart';
import 'package:singleclin_mobile/core/services/location_service.dart';
import 'package:singleclin_mobile/features/auth/controllers/auth_controller.dart';
import 'package:singleclin_mobile/shared/controllers/bottom_nav_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Core services - permanent instances
    Get.put<StorageService>(StorageService(), permanent: true);
    Get.put<ApiService>(ApiService(), permanent: true);
    Get.put<AuthService>(AuthService(), permanent: true);
    Get.put<LocationService>(LocationService(), permanent: true);

    // Controllers
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<BottomNavController>(BottomNavController(), permanent: true);
  }
}

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}
