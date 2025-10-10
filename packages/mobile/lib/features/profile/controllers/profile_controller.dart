import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/core/services/api_service.dart';
import 'package:singleclin_mobile/features/auth/controllers/auth_controller.dart';
import 'package:singleclin_mobile/routes/app_routes.dart';

class ProfileController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final AuthController _authController = Get.find<AuthController>();

  // Observables
  final RxBool isLoading = false.obs;
  final RxBool isEditing = false.obs;
  final RxInt credits = 0.obs;

  // Form controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Form key
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _loadCredits();
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  /// Load user data from AuthController
  void _loadUserData() {
    final user = _authController.user;
    if (user != null) {
      fullNameController.text = user.displayName ?? '';
      emailController.text = user.email;
      phoneController.text = user.phoneNumber ?? '';
    }
  }

  /// Load user credits
  Future<void> _loadCredits() async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('/Credits/available');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          credits.value = data['data'] as int? ?? 0;
        } else if (data is int) {
          credits.value = data;
        }
      }
    } catch (e) {
      print('❌ Error loading credits: $e');
      // Não mostra erro para o usuário, apenas mantém créditos em 0
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh credits
  Future<void> refreshCredits() async {
    await _loadCredits();
  }

  /// Toggle edit mode
  void toggleEditMode() {
    if (isEditing.value) {
      // Canceling edit - restore original values
      _loadUserData();
    }
    isEditing.value = !isEditing.value;
  }

  /// Save profile changes
  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;

      final response = await _apiService.put(
        '/User/profile',
        data: {
          'fullName': fullNameController.text.trim(),
          'phoneNumber': phoneController.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        // Update user data in AuthController
        await _authController.refreshUser();

        Get.snackbar(
          'Sucesso',
          'Perfil atualizado com sucesso!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        isEditing.value = false;
      }
    } catch (e) {
      print('❌ Error saving profile: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível atualizar o perfil. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout
  Future<void> logout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        isLoading.value = true;
        await _authController.logout();
        Get.offAllNamed(AppRoutes.login);
      } catch (e) {
        print('❌ Error during logout: $e');
        Get.snackbar(
          'Erro',
          'Não foi possível sair. Tente novamente.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } finally {
        isLoading.value = false;
      }
    }
  }

  /// Validator for full name
  String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome completo é obrigatório';
    }
    if (value.trim().split(' ').length < 2) {
      return 'Digite nome e sobrenome';
    }
    return null;
  }

  /// Validator for phone
  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    // Basic phone validation (10-11 digits)
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10 || digitsOnly.length > 11) {
      return 'Telefone inválido';
    }
    return null;
  }
}
