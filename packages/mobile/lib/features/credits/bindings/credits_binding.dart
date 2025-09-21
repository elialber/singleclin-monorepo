import 'package:get/get.dart';
import '../controllers/credit_history_controller.dart';

class CreditsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreditHistoryController>(
      () => CreditHistoryController(),
    );
  }
}