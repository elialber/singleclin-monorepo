import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/core/services/api_service.dart';
import 'package:singleclin_mobile/core/services/credits_service.dart';
import 'package:singleclin_mobile/features/auth/controllers/auth_controller.dart';
import 'package:singleclin_mobile/routes/app_routes.dart';

class ProfileController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final AuthController _authController = Get.find<AuthController>();
  // Observables
  final RxBool isLoading = false.obs;
  final RxBool isEditing = false.obs;
  final RxBool isSaving = false.obs;

  // Lazy access ao CreditsService
  CreditsService get _creditsService => Get.find<CreditsService>();

  // Créditos vêm do CreditsService centralizado
  int get credits => _creditsService.credits.value;
  String get lastUpdateText => _creditsService.getLastUpdateText();

  // Form controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Form key
  final formKey = GlobalKey<FormState>();

  // Phone formatter
  final TextInputFormatter phoneFormatter = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length <= 11) {
      if (text.length <= 2) {
        return TextEditingValue(
          text: text.isEmpty ? '' : '($text',
          selection: TextSelection.collapsed(
            offset: text.length + (text.isNotEmpty ? 1 : 0),
          ),
        );
      } else if (text.length <= 7) {
        return TextEditingValue(
          text: '(${text.substring(0, 2)}) ${text.substring(2)}',
          selection: TextSelection.collapsed(offset: text.length + 4),
        );
      } else {
        return TextEditingValue(
          text:
              '(${text.substring(0, 2)}) ${text.substring(2, 7)}-${text.substring(7)}',
          selection: TextSelection.collapsed(offset: text.length + 5),
        );
      }
    }
    return oldValue;
  });

  @override
  void onInit() {
    super.onInit();
    print('🟢 ProfileController.onInit() - Initializing controller');
    _loadUserData();
    _creditsService.loadUserCredits();
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

  /// Refresh credits using the centralized service
  Future<void> refreshCredits() async {
    await _creditsService.refreshCredits();
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
      isSaving.value = true;

      // Monta payload evitando enviar phoneNumber vazio (quebra validação do backend)
      final Map<String, dynamic> payload = {
        'fullName': fullNameController.text.trim(),
      };
      final cleanedPhone = phoneController.text
          .replaceAll(RegExp(r'\D'), '')
          .trim();
      if (cleanedPhone.isNotEmpty) {
        payload['phoneNumber'] = cleanedPhone; // envia apenas se houver dígitos
      }

      final response = await _apiService.put(
        '/Users/${_authController.user?.id}',
        data: payload,
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
      isSaving.value = false;
    }
  }

  /// Logout
  Future<void> logout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirmar Saída',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deseja realmente sair da sua conta?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Você precisará fazer login novamente para acessar o aplicativo.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Sair',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
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
