import 'package:get/get.dart';
import 'package:singleclin_mobile/features/credits/controllers/credit_history_controller.dart';

class CreditsBinding extends Bindings {
  @override
  void dependencies() {
    print('🟢 CreditsBinding.dependencies() - Iniciando binding');
    // Using put instead of lazyPut to force fresh instance
    final controller = Get.put<CreditHistoryController>(
      CreditHistoryController(),
      tag: 'creditHistory',
    );
    print('🟢 CreditsBinding.dependencies() - Controller criado: $controller');
  }
}
