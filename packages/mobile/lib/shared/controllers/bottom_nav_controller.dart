import 'package:get/get.dart';
import 'package:singleclin_mobile/routes/app_routes.dart';

class BottomNavController extends GetxController {
  final RxInt _currentIndex = 0.obs;

  int get currentIndex => _currentIndex.value;

  void changePage(int index) {
    print('🔵 BottomNavController.changePage() - Index: $index');
    print('🔵 Current index: ${_currentIndex.value}');
    if (_currentIndex.value != index) {
      _currentIndex.value = index;
      print('🔵 Navigating to index: $index');
      _navigateToPage(index);
    } else {
      print('🔵 Same index, skipping navigation');
    }
  }

  void _navigateToPage(int index) {
    print('🔵 _navigateToPage() - Index: $index');
    switch (index) {
      case 0:
        print('🔵 Navigating to Discovery');
        Get.offAllNamed(AppRoutes.discovery); // Início = Lista de clínicas
        break;
      case 1:
        print('🔵 Navigating to Credit History');
        Get.offAllNamed(AppRoutes.creditHistory); // Transações
        break;
      case 2:
        print('🔵 Navigating to Subscription Plans');
        Get.offAllNamed(AppRoutes.subscriptionPlans); // Planos
        break;
      case 3:
        print('🔵 Navigating to Profile');
        Get.offAllNamed(AppRoutes.profile); // Perfil
        break;
    }
    print('🔵 Navigation command sent for route');
  }

  void setIndex(int index) {
    _currentIndex.value = index;
  }
}
