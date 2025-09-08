import 'package:get/get.dart';
import '../controllers/appointments_controller.dart';
import '../controllers/appointment_details_controller.dart';
import '../controllers/cancellation_controller.dart';

/// Appointments Binding
/// Binds appointment-related controllers for dependency injection
class AppointmentsBinding extends Bindings {
  @override
  void dependencies() {
    // Main appointments controller
    Get.lazyPut<AppointmentsController>(
      () => AppointmentsController(),
    );
    
    // Appointment details controller
    Get.lazyPut<AppointmentDetailsController>(
      () => AppointmentDetailsController(),
    );
    
    // Cancellation controller
    Get.lazyPut<CancellationController>(
      () => CancellationController(),
    );
  }
}