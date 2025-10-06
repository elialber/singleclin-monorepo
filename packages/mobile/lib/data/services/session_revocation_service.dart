import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:singleclin_mobile/core/constants/app_constants.dart';
import 'package:singleclin_mobile/core/services/storage_service.dart';
import 'package:singleclin_mobile/data/services/auth_service.dart';
import 'package:singleclin_mobile/data/services/token_refresh_service.dart';

/// Listens to server push notifications to revoke sessions immediately.
class SessionRevocationService {
  SessionRevocationService({
    FirebaseMessaging? messaging,
    FirebaseAuth? firebaseAuth,
    Future<void> Function(String message)? onRevocation,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _onRevocation = onRevocation ??
            message {
              if (kDebugMode) {
                print('SessionRevocationService: revocation callback missing -> $message');
              }
            },
        _tokenRefreshService = tokenRefreshService,
        _storageService = storageService,
        _authService = authService;

  final FirebaseMessaging _messaging;
  final FirebaseAuth _firebaseAuth;
  final Future<void> Function(String message) _onRevocation;
  final TokenRefreshService? _tokenRefreshService;
  final StorageService? _storageService;
  final AuthService? _authService;

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

      await _firebaseAuth.signOut();
      await _tokenRefreshService?.dispose();
      await _authService?.signOut();
      if (_storageService != null) {
        await _storageService!.remove(AppConstants.tokenKey);
        await _storageService!.remove(AppConstants.authTokenKey);
        await _storageService!.remove(AppConstants.userDataKey);
      }
      final reason =
          message.data['message'] ?? 'Sua sessão foi encerrada pelo servidor.';
      await _onRevocation(reason);
    }
  }
}
