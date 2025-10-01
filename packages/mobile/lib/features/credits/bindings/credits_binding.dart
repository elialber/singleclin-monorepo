import 'package:get/get.dart';
import 'package:singleclin_mobile/features/credits/controllers/credit_history_controller.dart';

class CreditsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreditHistoryController>(CreditHistoryController.new);
  }
}
