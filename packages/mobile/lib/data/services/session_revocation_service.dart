import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:singleclin_mobile/core/constants/app_constants.dart';
import 'package:singleclin_mobile/core/services/storage_service.dart';
import 'package:singleclin_mobile/data/services/auth_service.dart';
import 'package:singleclin_mobile/data/services/token_refresh_service.dart';

/// Listens to server push notifications to revoke sessions immediately.
class SessionRevocationService {
  SessionRevocationService({
    FirebaseMessaging? messaging,
    AuthService? authService,
    TokenRefreshService? tokenRefreshService,
    StorageService? storageService,
    FirebaseAuth? firebaseAuth,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _authService = authService ?? Get.find<AuthService>(),
        _tokenRefreshService = tokenRefreshService ?? Get.find<TokenRefreshService>(),
        _storageService = storageService ?? Get.find<StorageService>(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseMessaging _messaging;
  final AuthService _authService;
  final TokenRefreshService _tokenRefreshService;
  final StorageService _storageService;
  final FirebaseAuth _firebaseAuth;

  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;

  Future<void> initialize() async {
    try {
      await _messaging.requestPermission();

      _messageSubscription =
          FirebaseMessaging.onMessage.listen(_handleRemoteMessage);
      _openedAppSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);

      if (kDebugMode) {
        print('🔔 SessionRevocationService: Listening for revocation events');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ SessionRevocationService init error: $e');
      }
    }
  }

  void dispose() {
    _messageSubscription?.cancel();
    _openedAppSubscription?.cancel();
  }

  Future<void> _handleRemoteMessage(RemoteMessage message) async {
    final action = message.data['action'] ?? message.data['type'];

    if (action == null) {
      return;
    }

    if (action == 'session_revoked' || action == 'logout') {
      if (kDebugMode) {
        print('⛔ SessionRevocationService: Revocation message received');
      }

      await _tokenRefreshService.dispose();
      await _authService.signOut();
      await _storageService.remove(AppConstants.tokenKey);
      await _firebaseAuth.signOut();
      await _tokenRefreshService.initialize();

      if (Get.currentRoute != '/login' && Get.currentRoute != '/splash') {
        await Get.offAllNamed('/login');
        Get.snackbar(
          'Sessão encerrada',
          'Sua sessão foi encerrada pelo servidor.',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }
}
