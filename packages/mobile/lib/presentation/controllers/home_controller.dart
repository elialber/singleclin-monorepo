import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/presentation/controllers/base_controller.dart';

/// Example home controller demonstrating reactive state with GetX
class HomeController extends BaseController {
  // Reactive counter
  final RxInt _counter = 0.obs;
  int get counter => _counter.value;

  // Reactive string
  final RxString _welcomeMessage = 'Bem-vindo ao SingleClin'.obs;
  String get welcomeMessage => _welcomeMessage.value;

  // Reactive list example
  final RxList<String> _items = <String>[].obs;
  List<String> get items => _items;

  // Get theme controller (commented out until ThemeController is implemented)
  // final ThemeController themeController = Get.find<ThemeController>();

  @override
  void onInit() {
    super.onInit();
    // Initialize data when controller is created
    _loadInitialData();
  }

  @override
  void onReady() {
    super.onReady();
    // Called after the widget is rendered on screen
    showInfoSnackbar('Página carregada com sucesso!');
  }

  @override
  void onClose() {
    // Clean up resources when controller is removed
    super.onClose();
  }

  /// Increment counter
  void incrementCounter() {
    _counter.value++;
    
    // Example of using executeAsync for async operations
    executeAsync(
      () async {
        // Simulate API call
        await Future.delayed(const Duration(seconds: 1));
        return 'Counter updated to ${_counter.value}';
      },
      onSuccess: (result) {
        setSuccessMessage(result);
      },
    );
  }

  /// Toggle dark mode using theme controller
  void toggleDarkMode() {
    // TODO: Implement when ThemeController is available
    // themeController.toggleTheme();
    Get.changeThemeMode(
      Get.isDarkMode ? ThemeMode.light : ThemeMode.dark,
    );
  }

  /// Add item to list
  void addItem(String item) {
    if (item.isNotEmpty) {
      _items.add(item);
      showSuccessSnackbar('Item adicionado: $item');
    } else {
      showWarningSnackbar('Digite um item válido');
    }
  }

  /// Remove item from list
  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      final removedItem = _items[index];
      _items.removeAt(index);
      showInfoSnackbar('Item removido: $removedItem');
    }
  }

  /// Clear all items
  void clearItems() {
    _items.clear();
    showInfoSnackbar('Lista limpa');
  }

  /// Update welcome message
  void updateWelcomeMessage(String newMessage) {
    _welcomeMessage.value = newMessage;
  }

  /// Private method to load initial data
  void _loadInitialData() {
    _items.addAll([
      'Exemplo 1',
      'Exemplo 2',
      'Exemplo 3',
    ]);
  }

  /// Example of navigation with GetX
  void navigateToDetails() {
    // Get.to(() => DetailsPage());
    // or with arguments
    // Get.to(() => DetailsPage(), arguments: {'id': 123});
    // or with named routes
    // Get.toNamed('/details', arguments: {'id': 123});
  }

  /// Example of showing dialog with GetX
  void showExampleDialog() {
    Get.defaultDialog(
      title: 'Exemplo de Diálogo',
      middleText: 'Este é um diálogo do GetX',
      textConfirm: 'OK',
      textCancel: 'Cancelar',
      onConfirm: () {
        Get.back();
        showSuccessSnackbar('Confirmado!');
      },
      onCancel: () {
        showInfoSnackbar('Cancelado');
      },
    );
  }

  /// Example of showing bottom sheet with GetX
  void showExampleBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Exemplo de Bottom Sheet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }
}