import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile/core/errors/api_exceptions.dart';
import 'package:mobile/core/errors/auth_exceptions.dart';
import 'package:mobile/core/routes/routes.dart';
import 'package:mobile/data/services/auth_service.dart';
import 'package:mobile/data/services/token_refresh_service.dart';
import 'package:mobile/data/services/user_api_service.dart';
import 'package:mobile/domain/entities/user_entity.dart';

/// Controller for managing authentication state and UI interactions
class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final UserApiService _userApiService = UserApiService();
  final TokenRefreshService _tokenRefreshService =
      Get.find<TokenRefreshService>();

  // Observable states
  final _isLoading = false.obs;
  final _currentUser = Rxn<UserEntity?>();
  final _errorMessage = RxnString();

  // Form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final forgotEmailController = TextEditingController();

  // Form keys
  final loginFormKey = GlobalKey<FormState>();
  final registerFormKey = GlobalKey<FormState>();
  final forgotPasswordFormKey = GlobalKey<FormState>();

  // Getters
  bool get isLoading => _isLoading.value;
  UserEntity? get currentUser => _currentUser.value;
  String? get errorMessage => _errorMessage.value;
  bool get isAuthenticated => currentUser != null;

  @override
  void onInit() {
    super.onInit();
    _initAuthStateListener();
    _checkCurrentUser();
  }

  /// Initialize auth state listener
  void _initAuthStateListener() {
    _authService.authStateChanges.listen((user) async {
      _currentUser.value = user;
      if (user != null) {
        // Update AppRouter authentication state
        AppRouter.authenticated = true;
        // Sync user with backend after authentication
        await _syncUserWithBackend(user);
        // Navigate to home screen when authenticated
        final context = AppRouter.navigatorKey.currentContext;
        if (context != null) {
          context.go(AppRoutes.home);
        }
      } else {
        // Update AppRouter authentication state
        AppRouter.authenticated = false;
      }
    });
  }

  /// Check current user on app start
  Future<void> _checkCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
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

    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      _showSuccessMessage('Login realizado com sucesso!');
      _clearLoginForm();
    } on AuthException catch (e) {
      _setError(_getLocalizedErrorMessage(e));
    } catch (e) {
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

    _setLoading(true);
    _clearError();

    try {
      await _authService.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        name: nameController.text.trim(),
      );
      _showSuccessMessage('Conta criada com sucesso! Verifique seu email.');
      _clearRegisterForm();
    } on AuthException catch (e) {
      _setError(_getLocalizedErrorMessage(e));
    } catch (e) {
      _setError('Erro inesperado. Tente novamente.');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithGoogle();
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
    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithApple();
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

    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(
        email: forgotEmailController.text.trim(),
      );
      _showSuccessMessage(
        'Email de recuperação enviado! Verifique sua caixa de entrada.',
      );
      forgotEmailController.clear();
      final context = AppRouter.navigatorKey.currentContext;
      if (context != null) {
        context.go(AppRoutes.login);
      }
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
      await _authService.signOut();
      _clearAllForms();
      // Update AppRouter authentication state
      AppRouter.authenticated = false;
      // Navigate to login screen
      final context = AppRouter.navigatorKey.currentContext;
      if (context != null) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      _setError('Erro ao fazer logout.');
    }
  }

  /// Navigate to register screen
  void goToRegister() {
    _clearError();
    final context = AppRouter.navigatorKey.currentContext;
    if (context != null) {
      context.go(AppRoutes.register);
    }
  }

  /// Navigate to login screen
  void goToLogin() {
    _clearError();
    final context = AppRouter.navigatorKey.currentContext;
    if (context != null) {
      context.go(AppRoutes.login);
    }
  }

  /// Navigate to forgot password screen
  void goToForgotPassword() {
    _clearError();
    final context = AppRouter.navigatorKey.currentContext;
    if (context != null) {
      context.go(AppRoutes.forgotPassword);
    }
  }

  /// Get current user's ID token with automatic refresh
  Future<String?> getCurrentToken() async {
    try {
      return await _tokenRefreshService.getCurrentToken();
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
      return await _tokenRefreshService.refreshToken();
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
      return await _tokenRefreshService.isTokenExpiringSoon();
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
      // Log API errors but don't block authentication flow
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
    _authService.dispose();
    super.onClose();
  }
}
