import 'package:get/get.dart';
import 'package:singleclin_mobile/data/services/auth_service.dart';
import 'package:singleclin_mobile/data/services/user_api_service.dart';
import 'package:singleclin_mobile/domain/entities/user_entity.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final UserApiService _userApiService = UserApiService();
  final StorageService _storageService = Get.find<StorageService>();

  // Observable properties
  final Rx<UserModel?> _user = Rx<UserModel?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _isAuthenticated = false.obs;
  final RxString _error = ''.obs;

  // Getters
  UserModel? get user => _user.value;
  bool get isLoading => _isLoading.value;
  bool get isAuthenticated => _isAuthenticated.value;
  String get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    _checkAuthStatus();
  }

  /// Verifica o status de autenticação ao inicializar
  Future<void> _checkAuthStatus() async {
    try {
      _isLoading.value = true;

      // Check if user is authenticated with Firebase
      final UserEntity? currentUser = await _authService.getCurrentUser();

      if (currentUser != null) {
        try {
          // Try to get user profile from backend
          final userProfile = await _userApiService.getCurrentUserProfile();
          final String idToken = await _authService.getIdToken();

          // Store data locally
          await _storageService.setString(AppConstants.tokenKey, idToken);
          await _storageService.setString(
            AppConstants.userKey,
            userProfile.toJson().toString(),
          );

          // Update controller state
          _user.value = UserModel.fromUserModel(userProfile);
          _isAuthenticated.value = true;
        } catch (backendError) {
          // If backend fails but Firebase is authenticated, logout completely
          await logout();
        }
      } else {
        // No Firebase user, clear any local data
        await _storageService.remove(AppConstants.tokenKey);
        await _storageService.remove(AppConstants.userKey);
        _isAuthenticated.value = false;
      }
    } catch (e) {
      _error.value = 'Erro ao verificar autenticação: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  /// Login com email e senha
  Future<bool> loginWithEmail(String email, String password) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      // Step 1: Authenticate with Firebase
      final UserEntity firebaseUser = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      // Step 2: Get Firebase ID token
      final String idToken = await _authService.getIdToken(forceRefresh: true);

      // Step 3: Get user profile from backend (this will sync with Firebase token via interceptor)
      final userProfile = await _userApiService.getCurrentUserProfile();

      // Step 4: Store user data locally
      await _storageService.setString(AppConstants.tokenKey, idToken);
      await _storageService.setString(
        AppConstants.userKey,
        userProfile.toJson().toString(),
      );

      // Step 5: Update controller state
      _user.value = UserModel.fromUserModel(userProfile);
      _isAuthenticated.value = true;

      // Step 6: Navigate to appropriate screen
      final onboardingCompleted = await isOnboardingCompleted();
      if (onboardingCompleted) {
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        Get.offAllNamed(AppRoutes.onboarding);
      }

      return true;
    } catch (e) {
      _error.value = 'Erro no login: $e';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Login com Google
  Future<bool> loginWithGoogle() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      // Step 1: Authenticate with Firebase via Google
      final UserEntity firebaseUser = await _authService.signInWithGoogle();

      // Step 2: Get Firebase ID token
      final String idToken = await _authService.getIdToken(forceRefresh: true);

      // Step 3: Get user profile from backend
      final userProfile = await _userApiService.getCurrentUserProfile();

      // Step 4: Store user data locally
      await _storageService.setString(AppConstants.tokenKey, idToken);
      await _storageService.setString(
        AppConstants.userKey,
        userProfile.toJson().toString(),
      );

      // Step 5: Update controller state
      _user.value = UserModel.fromUserModel(userProfile);
      _isAuthenticated.value = true;

      // Step 6: Navigate to appropriate screen
      final onboardingCompleted = await isOnboardingCompleted();
      if (onboardingCompleted) {
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        Get.offAllNamed(AppRoutes.onboarding);
      }

      return true;
    } catch (e) {
      _error.value = 'Erro no login com Google: $e';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Login com Apple
  Future<bool> loginWithApple() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _authService.loginWithApple();
      
      if (response['success']) {
        await _handleSuccessfulAuth(response['data']);
        return true;
      } else {
        _error.value = response['message'] ?? 'Erro no login com Apple';
        return false;
      }
    } catch (e) {
      _error.value = 'Erro no login com Apple: $e';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Registro de novo usuário
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      );
      
      if (response['success']) {
        await _handleSuccessfulAuth(response['data']);
        return true;
      } else {
        _error.value = response['message'] ?? 'Erro no registro';
        return false;
      }
    } catch (e) {
      _error.value = 'Erro no registro: $e';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Recuperação de senha
  Future<bool> forgotPassword(String email) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _authService.forgotPassword(email);
      
      if (response['success']) {
        Get.snackbar(
          'Sucesso',
          'Email de recuperação enviado!',
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      } else {
        _error.value = response['message'] ?? 'Erro ao enviar email';
        return false;
      }
    } catch (e) {
      _error.value = 'Erro na recuperação: $e';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      _isLoading.value = true;

      // Logout from Firebase
      await _authService.signOut();

      // Clear local data
      await _storageService.remove(AppConstants.tokenKey);
      await _storageService.remove(AppConstants.userKey);
      await _storageService.remove(AppConstants.creditsKey);

      // Reset controller state
      _user.value = null;
      _isAuthenticated.value = false;
      _error.value = '';

      // Navigate to login
      Get.offAllNamed(AppRoutes.login);

    } catch (e) {
      _error.value = 'Erro no logout: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  /// Atualizar dados do usuário
  Future<bool> updateUser(UserModel updatedUser) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _authService.updateUser(updatedUser);
      
      if (response['success']) {
        _user.value = UserModel.fromJson(response['data']);
        await _storageService.setString(
          AppConstants.userKey,
          _user.value!.toJson().toString(),
        );
        
        Get.snackbar(
          'Sucesso',
          'Perfil atualizado com sucesso!',
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      } else {
        _error.value = response['message'] ?? 'Erro ao atualizar perfil';
        return false;
      }
    } catch (e) {
      _error.value = 'Erro na atualização: $e';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Atualizar créditos do usuário
  void updateCredits(int newCredits) {
    if (_user.value != null) {
      _user.value = _user.value!.copyWith(sgCredits: newCredits);
      _storageService.setString(
        AppConstants.userKey,
        _user.value!.toJson().toString(),
      );
    }
  }

  /// Verificar se onboarding foi concluído
  Future<bool> isOnboardingCompleted() async {
    return await _storageService.getBool(AppConstants.onboardingKey) ?? false;
  }

  /// Marcar onboarding como concluído
  Future<void> completeOnboarding() async {
    await _storageService.setBool(AppConstants.onboardingKey, true);
  }

  /// Manipular autenticação bem-sucedida
  Future<void> _handleSuccessfulAuth(Map<String, dynamic> data) async {
    final token = data['token'];
    final userData = data['user'];
    
    // Salvar token e dados do usuário
    await _storageService.setString(AppConstants.tokenKey, token);
    await _storageService.setString(AppConstants.userKey, userData.toString());
    
    // Atualizar estado
    _user.value = UserModel.fromJson(userData);
    _isAuthenticated.value = true;
    
    // Navegar para dashboard ou onboarding
    final onboardingCompleted = await isOnboardingCompleted();
    if (onboardingCompleted) {
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.offAllNamed(AppRoutes.onboarding);
    }
  }

  /// Limpar erro
  void clearError() {
    _error.value = '';
  }

  /// Validar email
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validar senha
  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Validar telefone
  bool isValidPhone(String phone) {
    return RegExp(r'^\(\d{2}\) \d{4,5}-\d{4}$').hasMatch(phone);
  }
}