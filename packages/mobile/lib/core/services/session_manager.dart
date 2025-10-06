import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/core/constants/app_constants.dart';
import 'package:singleclin_mobile/core/services/storage_service.dart';
import 'package:singleclin_mobile/data/services/app_lifecycle_observer.dart';
import 'package:singleclin_mobile/data/services/auth_service.dart';
import 'package:singleclin_mobile/data/services/session_revocation_service.dart';
import 'package:singleclin_mobile/data/services/token_refresh_service.dart';
import 'package:singleclin_mobile/shared/controllers/bottom_nav_controller.dart';

class SessionManager extends GetxService {
  SessionManager({
    required AuthService authService,
    required StorageService storageService,
    FirebaseAuth? firebaseAuth,
  })  : _authService = authService,
        _storageService = storageService,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final AuthService _authService;
  final StorageService _storageService;
  final FirebaseAuth _firebaseAuth;

  bool get isSessionActive => Get.isRegistered<TokenRefreshService>();

  TokenRefreshService? get tokenRefreshService =>
      Get.isRegistered<TokenRefreshService>()
          ? Get.find<TokenRefreshService>()
          : null;

  Future<void> startSession() async {
    if (isSessionActive) {
      return;
    }

    if (kDebugMode) {
      print('🟢 SessionManager: starting session');
    }

    final tokenService = TokenRefreshService(
      authService: _authService,
      storageService: _storageService,
    );
    Get.put<TokenRefreshService>(tokenService);
    await tokenService.initialize();

    final lifecycleObserver = AppLifecycleObserver(tokenService)
      ..initialize();
    Get.put<AppLifecycleObserver>(lifecycleObserver);

    final revocationService = SessionRevocationService(
      onRevocation: (reason) => forceLogout(
        reason ?? 'Sua sessão foi encerrada pelo servidor.',
      ),
    );
    await revocationService.initialize();
    Get.put<SessionRevocationService>(revocationService);

    if (!Get.isRegistered<BottomNavController>()) {
      Get.put(BottomNavController());
    }
  }

  Future<void> endSession({
    bool signOut = false,
    bool redirectToLogin = false,
    String? message,
  }) async {
    if (kDebugMode) {
      print('🔴 SessionManager: ending session');
    }

    if (Get.isRegistered<SessionRevocationService>()) {
      final revocationService = Get.find<SessionRevocationService>();
      revocationService.dispose();
      Get.delete<SessionRevocationService>();
    }

    if (Get.isRegistered<AppLifecycleObserver>()) {
      final lifecycleObserver = Get.find<AppLifecycleObserver>();
      lifecycleObserver.dispose();
      Get.delete<AppLifecycleObserver>();
    }

    if (Get.isRegistered<BottomNavController>()) {
      Get.delete<BottomNavController>();
    }

    if (Get.isRegistered<TokenRefreshService>()) {
      final tokenService = Get.find<TokenRefreshService>();
      tokenService.dispose();
      Get.delete<TokenRefreshService>();
    }

    if (signOut) {
      await _authService.signOut();
      await _firebaseAuth.signOut();
      await _storageService.remove(AppConstants.tokenKey);
      await _storageService.remove(AppConstants.authTokenKey);
      await _storageService.remove(AppConstants.userDataKey);
    }

    if (redirectToLogin && Get.currentRoute != '/login' && Get.currentRoute != '/splash') {
      await Get.offAllNamed('/login');
      if (message != null) {
        Get.snackbar(
          'Sessão Encerrada',
          message,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      }
    } else if (message != null) {
      Get.snackbar(
        'Sessão Encerrada',
        message,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> forceLogout(String message) async {
    await endSession(
      signOut: true,
      redirectToLogin: true,
      message: message,
    );
  }
}
