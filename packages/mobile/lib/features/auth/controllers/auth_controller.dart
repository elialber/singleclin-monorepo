import 'package:get/get.dart';
import 'package:singleclin_mobile/core/constants/app_constants.dart';
import 'package:singleclin_mobile/core/services/storage_service.dart';
import 'package:singleclin_mobile/data/models/user_model.dart';
import 'package:singleclin_mobile/data/services/auth_service.dart';
import 'package:singleclin_mobile/data/services/user_api_service.dart';
import 'package:singleclin_mobile/domain/entities/user_entity.dart';
import 'package:singleclin_mobile/routes/app_routes.dart';

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
          // Get Firebase ID token
          final String idToken = await _authService.getIdToken();

          // Sync Firebase user with backend database
          final userProfile = await _userApiService.syncUserWithBackend(
            firebaseUid: currentUser.id,
            email: currentUser.email,
            displayName: currentUser.displayName,
            photoUrl: currentUser.photoUrl,
            isEmailVerified: currentUser.isEmailVerified,
          );

          // Store data locally
          await _storageService.setString(AppConstants.tokenKey, idToken);
          await _storageService.setString(
            AppConstants.userKey,
            userProfile.toJson().toString(),
          );

          // Update controller state
          _user.value = userProfile;
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

      // Step 3: Sync Firebase user with backend database
      final userProfile = await _userApiService.syncUserWithBackend(
        firebaseUid: firebaseUser.id,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoUrl,
        isEmailVerified: firebaseUser.isEmailVerified,
      );

      // Step 4: Store user data locally
      await _storageService.setString(AppConstants.tokenKey, idToken);
      await _storageService.setString(
        AppConstants.userKey,
        userProfile.toJson().toString(),
      );

      // Step 5: Update controller state
      _user.value = UserModel.fromEntity(userProfile);
      _isAuthenticated.value = true;

      // Step 6: Navigate to appropriate screen
      // TEMP: Dashboard está comentado, ir para clinic services
      Get.offAllNamed(AppRoutes.clinicsList);

      // final onboardingCompleted = await isOnboardingCompleted();
      // if (onboardingCompleted) {
      //   Get.offAllNamed(AppRoutes.dashboard);
      // } else {
      //   Get.offAllNamed(AppRoutes.onboarding);
      // }

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

      // Step 3: Sync Firebase user with backend database
      final userProfile = await _userApiService.syncUserWithBackend(
        firebaseUid: firebaseUser.id,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoUrl,
        isEmailVerified: firebaseUser.isEmailVerified,
      );

      // Step 4: Store user data locally
      await _storageService.setString(AppConstants.tokenKey, idToken);
      await _storageService.setString(
        AppConstants.userKey,
        userProfile.toJson().toString(),
      );

      // Step 5: Update controller state
      _user.value = UserModel.fromEntity(userProfile);
      _isAuthenticated.value = true;

      // Step 6: Navigate to appropriate screen
      // TEMP: Dashboard está comentado, ir para clinic services
      Get.offAllNamed(AppRoutes.clinicsList);

      // final onboardingCompleted = await isOnboardingCompleted();
      // if (onboardingCompleted) {
      //   Get.offAllNamed(AppRoutes.dashboard);
      // } else {
      //   Get.offAllNamed(AppRoutes.onboarding);
      // }

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

      final userEntity = await _authService.signInWithApple();
      await _handleSuccessfulAuth(userEntity);
      return true;
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

      final userEntity = await _authService.signUp(
        name: fullName,
        email: email,
        password: password,
      );

      await _handleSuccessfulAuth(userEntity);
      return true;
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

      await _authService.sendPasswordResetEmail(email: email);

      Get.snackbar(
        'Sucesso',
        'Email de recuperação enviado!',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
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

      final response = await _authService.updateProfile(
        name: updatedUser.displayName,
        photoUrl: updatedUser.photoUrl,
      );

      _user.value = UserModel.fromEntity(response);
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
      // TODO: Implement credits update when UserModel supports it
      // _user.value = _user.value!.copyWith(sgCredits: newCredits);
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
  Future<void> _handleSuccessfulAuth(UserEntity userEntity) async {
    // Get Firebase ID token
    final String idToken = await _authService.getIdToken(forceRefresh: true);

    // Sync Firebase user with backend database
    final userProfile = await _userApiService.syncUserWithBackend(
      firebaseUid: userEntity.id,
      email: userEntity.email,
      displayName: userEntity.displayName,
      photoUrl: userEntity.photoUrl,
      isEmailVerified: userEntity.isEmailVerified,
    );

    // Store user data locally
    await _storageService.setString(AppConstants.tokenKey, idToken);
    await _storageService.setString(
      AppConstants.userKey,
      userProfile.toJson().toString(),
    );

    // Update controller state
    _user.value = userProfile;
    _isAuthenticated.value = true;

    // Navigate to home screen (dashboard está comentado)
    Get.offAllNamed(AppRoutes.clinicsList);

    // final onboardingCompleted = await isOnboardingCompleted();
    // if (onboardingCompleted) {
    //   Get.offAllNamed(AppRoutes.dashboard);
    // } else {
    //   Get.offAllNamed(AppRoutes.onboarding);
    // }
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

  /// Get current token for API requests (prioritizes JWT from sync endpoint)
  Future<String?> getCurrentToken() async {
    try {
      if (_isAuthenticated.value) {
        // First try to get JWT token from storage (from sync endpoint)
        final jwtToken = await _storageService.getString(AppConstants.tokenKey);
        print(
          'DEBUG: Checking for JWT token in storage with key: ${AppConstants.tokenKey}',
        );
        print(
          'DEBUG: JWT token found: ${jwtToken != null ? "YES (length: ${jwtToken.length})" : "NO"}',
        );

        if (jwtToken != null && jwtToken.isNotEmpty) {
          print('DEBUG: Using JWT token from sync endpoint');
          return jwtToken;
        }

        // Fallback to Firebase token
        print('DEBUG: No JWT token found, using Firebase token');
        return await _authService.getIdToken();
      }
      return null;
    } catch (e) {
      print('Error getting current token: $e');
      return null;
    }
  }
}
