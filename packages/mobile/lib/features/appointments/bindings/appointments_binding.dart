import 'package:get/get.dart';
import 'package:singleclin_mobile/features/appointments/controllers/appointment_details_controller.dart';
import 'package:singleclin_mobile/features/appointments/controllers/appointments_controller.dart';
import 'package:singleclin_mobile/features/appointments/controllers/cancellation_controller.dart';

/// Appointments Binding
/// Binds appointment-related controllers for dependency injection
class AppointmentsBinding extends Bindings {
  @override
  void dependencies() {
    // Main appointments controller
    Get.lazyPut<AppointmentsController>(AppointmentsController.new);

    // Appointment details controller
    Get.lazyPut<AppointmentDetailsController>(AppointmentDetailsController.new);

    // Cancellation controller
    Get.lazyPut<CancellationController>(CancellationController.new);
  }
}
