import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/core/constants/app_constants.dart';
import 'package:singleclin_mobile/core/errors/api_exceptions.dart';
import 'package:singleclin_mobile/core/errors/auth_exceptions.dart';
import 'package:singleclin_mobile/core/services/storage_service.dart';
import 'package:singleclin_mobile/data/services/auth_service.dart';
import 'package:singleclin_mobile/data/services/firebase_initialization_service.dart';
import 'package:singleclin_mobile/data/services/token_refresh_service.dart';
import 'package:singleclin_mobile/data/services/user_api_service.dart';
import 'package:singleclin_mobile/domain/entities/user_entity.dart';

/// Controller for managing authentication state and UI interactions
class AuthController extends GetxController {
  AuthController({
    AuthService? authService,
    UserApiService? userApiService,
    TokenRefreshService? tokenRefreshService,
    StorageService? storageService,
    FirebaseInitializationService? firebaseInitializationService,
  }) : _authService = authService,
       _userApiService = userApiService ?? UserApiService(),
       _tokenRefreshService = tokenRefreshService,
       _storageService = storageService ?? Get.find<StorageService>(),
       _firebaseInitializationService =
           firebaseInitializationService ??
           Get.find<FirebaseInitializationService>();

  AuthService? _authService;
  final UserApiService _userApiService;
  TokenRefreshService? _tokenRefreshService;
  final StorageService _storageService;
  final FirebaseInitializationService _firebaseInitializationService;

  // Observable states
  final RxBool _isLoading = false.obs;
  final Rxn<UserEntity?> _currentUser = Rxn<UserEntity?>();
  final RxnString _errorMessage = RxnString();

  // Subscriptions
  StreamSubscription<UserEntity?>? _authStateSubscription;
  StreamSubscription<String>? _tokenFailureSubscription;
  StreamSubscription<bool>? _firebaseReadySubscription;

  // Form controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController forgotEmailController = TextEditingController();

  // Form keys
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> registerFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> forgotPasswordFormKey = GlobalKey<FormState>();

  bool _authDependenciesInitialized = false;

  // Getters
  bool get isLoading => _isLoading.value;
  UserEntity? get currentUser => _currentUser.value;
  String? get errorMessage => _errorMessage.value;
  bool get isAuthenticated => currentUser != null;
  bool get isFirebaseReady => _firebaseInitializationService.firebaseReady;

  @override
  void onInit() {
    super.onInit();
    _observeFirebaseReadiness();
    _listenToTokenRefreshFailures();

    if (_firebaseInitializationService.firebaseReady) {
      unawaited(_initializeAuthDependencies());
    }
  }

  /// Observe Firebase readiness to initialize auth dependencies when available.
  void _observeFirebaseReadiness() {
    if (_firebaseInitializationService.firebaseReady) {
      return;
    }

    _firebaseReadySubscription = _firebaseInitializationService
        .firebaseReadyStream
        .listen((isReady) {
          if (!isReady) {
            return;
          }

          _firebaseReadySubscription?.cancel();
          unawaited(_initializeAuthDependencies());
          _listenToTokenRefreshFailures();
        });
  }

  Future<void> _initializeAuthDependencies() async {
    if (_authDependenciesInitialized ||
        !_firebaseInitializationService.firebaseReady) {
      return;
    }

    final authService = _ensureAuthService();
    if (authService == null) {
      if (kDebugMode) {
        print('AuthController: AuthService not registered yet.');
      }
      return;
    }

    _authDependenciesInitialized = true;

    _authStateSubscription?.cancel();
    _authStateSubscription = authService.authStateChanges.listen((user) async {
      _currentUser.value = user;
      if (user != null) {
        await _syncUserWithBackend(user);
        if (Get.currentRoute == '/login') {
          Get.offAllNamed('/discovery');
        }
      }
    });

    await _checkCurrentUser(authService);
  }

  void _listenToTokenRefreshFailures() {
    _tokenFailureSubscription?.cancel();
    final tokenService = _ensureTokenRefreshService();

    if (tokenService == null) {
      return;
    }

    _tokenFailureSubscription = tokenService.onHardFailure.listen(
      _handleTokenHardFailure,
    );
  }

  void _handleTokenHardFailure(String message) {
    _setError(message);

    if (Get.currentRoute != '/login') {
      Get.offAllNamed('/login');
    }

    Get.closeAllSnackbars();
    Get.snackbar(
      'Sessão expirada',
      message,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  }

  /// Check current user on app start
  Future<void> _checkCurrentUser(AuthService authService) async {
    try {
      final user = await authService.getCurrentUser();
      _currentUser.value = user;
    } catch (e) {
      debugPrint('Error checking current user: $e');
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail() async {
    if (!loginFormKey.currentState!.validate()) {
      return;
    }

    _clearError();

    if (!_ensureFirebaseReadyForAction()) {
      return;
    }

    await _initializeAuthDependencies();
    final authService = _ensureAuthService();
    if (authService == null) {
      _setError('Serviço de autenticação indisponível. Tente novamente.');
      return;
    }

    _setLoading(true);

    try {
      if (kDebugMode) {
        print('🔐 Attempting login with email: ${emailController.text.trim()}');
      }

      await authService.signInWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (kDebugMode) {
        print('✅ Firebase authentication successful');
      }

      _showSuccessMessage('Login realizado com sucesso!');
      _clearLoginForm();
    } on AuthException catch (e) {
      if (kDebugMode) {
        print(
          '❌ Authentication failed - AuthException: ${e.code} - ${e.message}',
        );
      }
      _setError(_getLocalizedErrorMessage(e));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Authentication failed - Unexpected error: $e');
      }
      _setError('Erro inesperado. Tente novamente.');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign up new user
  Future<void> signUp() async {
    if (!registerFormKey.currentState!.validate()) {
      return;
    }

    _clearError();

    if (!_ensureFirebaseReadyForAction()) {
      return;
    }

    await _initializeAuthDependencies();
    final authService = _ensureAuthService();
    if (authService == null) {
      _setError('Serviço de autenticação indisponível. Tente novamente.');
      return;
    }

    _setLoading(true);

    try {
      if (kDebugMode) {
        print('📝 Creating new account for: ${emailController.text.trim()}');
      }

      await authService.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        name: nameController.text.trim(),
      );

      if (kDebugMode) {
        print('✅ Account created successfully');
      }

      _showSuccessMessage('Conta criada com sucesso! Verifique seu email.');
      _clearRegisterForm();
    } on AuthException catch (e) {
      if (kDebugMode) {
        print(
          '❌ Account creation failed - AuthException: ${e.code} - ${e.message}',
        );
      }
      _setError(_getLocalizedErrorMessage(e));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Account creation failed - Unexpected error: $e');
      }
      _setError('Erro inesperado. Tente novamente.');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    _clearError();

    if (!_ensureFirebaseReadyForAction()) {
      return;
    }

    await _initializeAuthDependencies();
    final authService = _ensureAuthService();
    if (authService == null) {
      _setError('Serviço de autenticação indisponível. Tente novamente.');
      return;
    }

    _setLoading(true);

    try {
      await authService.signInWithGoogle();
      _showSuccessMessage('Login com Google realizado com sucesso!');
    } on AuthException catch (e) {
      _setError(_getLocalizedErrorMessage(e));
    } catch (e) {
      _setError('Erro inesperado. Tente novamente.');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    _clearError();

    if (!_ensureFirebaseReadyForAction()) {
      return;
    }

    await _initializeAuthDependencies();
    final authService = _ensureAuthService();
    if (authService == null) {
      _setError('Serviço de autenticação indisponível. Tente novamente.');
      return;
    }

    _setLoading(true);

    try {
      await authService.signInWithApple();
      _showSuccessMessage('Login com Apple realizado com sucesso!');
    } on AuthException catch (e) {
      _setError(_getLocalizedErrorMessage(e));
    } catch (e) {
      _setError('Erro inesperado. Tente novamente.');
    } finally {
      _setLoading(false);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail() async {
    if (!forgotPasswordFormKey.currentState!.validate()) {
      return;
    }

    _clearError();

    if (!_ensureFirebaseReadyForAction()) {
      return;
    }

    await _initializeAuthDependencies();
    final authService = _ensureAuthService();
    if (authService == null) {
      _setError('Serviço de autenticação indisponível. Tente novamente.');
      return;
    }

    _setLoading(true);

    try {
      await authService.sendPasswordResetEmail(
        email: forgotEmailController.text.trim(),
      );
      _showSuccessMessage(
        'Email de recuperação enviado! Verifique sua caixa de entrada.',
      );
      forgotEmailController.clear();
      Get.offAllNamed('/login');
    } on AuthException catch (e) {
      _setError(_getLocalizedErrorMessage(e));
    } catch (e) {
      _setError('Erro inesperado. Tente novamente.');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _initializeAuthDependencies();
      final tokenService = _ensureTokenRefreshService();
      final authService = _ensureAuthService();

      tokenService?.dispose();
      await authService?.signOut();
      await _storageService.remove(AppConstants.tokenKey);
      await _storageService.remove(AppConstants.authTokenKey);
      await _storageService.remove(AppConstants.userDataKey);
      await tokenService?.initialize();
      _clearAllForms();
      Get.offAllNamed('/login');
    } catch (e) {
      _setError('Erro ao fazer logout.');
    }
  }

  /// Navigate to register screen
  void goToRegister() {
    _clearError();
    Get.toNamed('/register');
  }

  /// Navigate to login screen
  void goToLogin() {
    _clearError();
    Get.offAllNamed('/login');
  }

  /// Navigate to forgot password screen
  void goToForgotPassword() {
    _clearError();
    Get.toNamed('/forgot-password');
  }

  /// Get current user's ID token with automatic refresh
  Future<String?> getCurrentToken() async {
    try {
      final tokenService = _ensureTokenRefreshService();
      return await tokenService?.getCurrentToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current token: $e');
      }
      return null;
    }
  }

  /// Force refresh the current user's token
  Future<String?> refreshToken() async {
    try {
      final tokenService = _ensureTokenRefreshService();
      return await tokenService?.refreshToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing token: $e');
      }
      return null;
    }
  }

  /// Check if token is expiring soon
  Future<bool> isTokenExpiringSoon() async {
    try {
      final tokenService = _ensureTokenRefreshService();
      return await tokenService?.isTokenExpiringSoon() ?? true;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking token expiration: $e');
      }
      return true; // Assume expiring on error
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage.value = message;
  }

  /// Clear error message
  void _clearError() {
    _errorMessage.value = null;
  }

  bool _ensureFirebaseReadyForAction() {
    if (_firebaseInitializationService.firebaseReady) {
      return true;
    }

    _setError(
      'Não foi possível conectar ao serviço de autenticação. Verifique sua conexão ou tente novamente mais tarde.',
    );
    return false;
  }

  AuthService? _ensureAuthService() {
    if (_authService != null) {
      return _authService;
    }

    if (Get.isRegistered<AuthService>()) {
      _authService = Get.find<AuthService>();
      return _authService;
    }

    return null;
  }

  TokenRefreshService? _ensureTokenRefreshService() {
    if (_tokenRefreshService != null) {
      return _tokenRefreshService;
    }

    if (Get.isRegistered<TokenRefreshService>()) {
      _tokenRefreshService = Get.find<TokenRefreshService>();
      return _tokenRefreshService;
    }

    return null;
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    Get.snackbar(
      'Sucesso',
      message,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
    );
  }

  /// Clear login form
  void _clearLoginForm() {
    emailController.clear();
    passwordController.clear();
  }

  /// Clear register form
  void _clearRegisterForm() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
  }

  /// Clear all forms
  void _clearAllForms() {
    _clearLoginForm();
    _clearRegisterForm();
    forgotEmailController.clear();
  }

  /// Get localized error message
  String _getLocalizedErrorMessage(AuthException exception) {
    switch (exception.code) {
      case 'weak-password':
        return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      case 'email-already-in-use':
        return 'Este email já está sendo usado por outra conta.';
      case 'user-not-found':
        return 'Nenhum usuário encontrado com este email.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      case 'account-exists-with-different-credential':
        return 'Já existe uma conta com esse email usando outro método de login.';
      case 'invalid-credential':
        return 'Credenciais inválidas.';
      case 'sign-in-cancelled':
      case 'sign_in_canceled':
        return 'Login cancelado pelo usuário.';
      case 'network-error':
        return 'Erro de conexão. Verifique sua internet.';
      case 'requires-recent-login':
        return 'Esta operação requer autenticação recente.';
      default:
        return exception.message;
    }
  }

  /// Sync user data with backend after Firebase authentication
  Future<void> _syncUserWithBackend(UserEntity user) async {
    try {
      await _userApiService.syncUserWithBackend(
        firebaseUid: user.id,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
        isEmailVerified: user.isEmailVerified,
      );

      if (kDebugMode) {
        print('✅ User synced with backend successfully');
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to sync user with backend: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Unexpected error syncing user with backend: $e');
      }
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    forgotEmailController.dispose();
    _authStateSubscription?.cancel();
    _tokenFailureSubscription?.cancel();
    _firebaseReadySubscription?.cancel();
    _authService?.dispose();
    super.onClose();
  }
}
