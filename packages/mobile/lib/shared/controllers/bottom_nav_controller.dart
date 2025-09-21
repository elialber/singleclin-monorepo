import 'package:get/get.dart';

class BottomNavController extends GetxController {
  final RxInt _currentIndex = 0.obs;

  int get currentIndex => _currentIndex.value;

  void changePage(int index) {
    _currentIndex.value = index;

    // Navigate to the corresponding route based on index
    switch (index) {
      case 0:
        Get.toNamed('/dashboard');
        break;
      case 1:
        Get.toNamed('/discovery');
        break;
      case 2:
        Get.toNamed('/plans');
        break;
      case 3:
        Get.toNamed('/transactions');
        break;
      case 4:
        Get.toNamed('/profile');
        break;
    }
  }

  void setCurrentIndex(int index) {
    _currentIndex.value = index;
  }
}