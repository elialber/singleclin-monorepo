import 'package:get/get.dart';

import 'discovery_controller.dart';
import 'map_controller.dart';
import 'filters_controller.dart';
import 'booking_controller.dart';

/// Discovery module binding for dependency injection
class DiscoveryBinding extends Bindings {
  @override
  void dependencies() {
    // Core discovery controller - always available
    Get.lazyPut<DiscoveryController>(() => DiscoveryController(), fenix: true);
    
    // Map controller - lazy loaded when needed
    Get.lazyPut<MapController>(() => MapController());
    
    // Filters controller - lazy loaded when needed
    Get.lazyPut<FiltersController>(() => FiltersController());
    
    // Booking controller - lazy loaded when needed
    Get.lazyPut<BookingController>(() => BookingController());
  }
}