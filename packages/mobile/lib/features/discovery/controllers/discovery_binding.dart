import 'package:get/get.dart';

import 'package:singleclin_mobile/features/discovery/controllers/discovery_controller.dart';
import 'package:singleclin_mobile/features/discovery/controllers/map_controller.dart';
import 'package:singleclin_mobile/features/discovery/controllers/filters_controller.dart';
import 'package:singleclin_mobile/features/discovery/controllers/booking_controller.dart';

/// Discovery module binding for dependency injection
class DiscoveryBinding extends Bindings {
  @override
  void dependencies() {
    // Core discovery controller - always available
    Get.lazyPut<DiscoveryController>(DiscoveryController.new, fenix: true);

    // Map controller - lazy loaded when needed
    Get.lazyPut<MapController>(MapController.new);

    // Filters controller - lazy loaded when needed
    Get.lazyPut<FiltersController>(FiltersController.new);

    // Booking controller - lazy loaded when needed
    Get.lazyPut<BookingController>(BookingController.new);
  }
}
