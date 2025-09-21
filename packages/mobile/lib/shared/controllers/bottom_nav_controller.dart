import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class BottomNavController extends GetxController {
  final RxInt _currentIndex = 0.obs;

  int get currentIndex => _currentIndex.value;

  void changePage(int index) {
    if (_currentIndex.value != index) {
      _currentIndex.value = index;
      _navigateToPage(index);
    }
  }

  void _navigateToPage(int index) {
    switch (index) {
      case 0:
        Get.offAllNamed(AppRoutes.discovery); // Início = Lista de clínicas
        break;
      case 1:
        Get.offAllNamed(AppRoutes.creditHistory); // Transações
        break;
      case 2:
        Get.offAllNamed(AppRoutes.subscriptionPlans); // Planos
        break;
      case 3:
        Get.offAllNamed(AppRoutes.profile); // Perfil
        break;
    }
  }

  void setIndex(int index) {
    _currentIndex.value = index;
  }
}