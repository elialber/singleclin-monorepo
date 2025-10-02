import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:singleclin_mobile/firebase_options.dart';

typedef FirebaseReadyCallback = Future<void> Function();

/// Manages Firebase initialization state and exposes readiness flags.
class FirebaseInitializationService extends GetxService {
  final RxBool _firebaseReady = false.obs;
  final RxBool _isInitializing = false.obs;
  final RxnString _lastErrorMessage = RxnString();
  final Rxn<DateTime> _lastAttemptAt = Rxn<DateTime>();
  final Rxn<DateTime> _lastSuccessAt = Rxn<DateTime>();
  final RxInt _consecutiveFailures = 0.obs;

  final List<FirebaseReadyCallback> _readyCallbacks = <FirebaseReadyCallback>[];
  Future<void>? _inFlightInitialization;

  bool get firebaseReady => _firebaseReady.value;
  bool get isInitializing => _isInitializing.value;
  String? get lastErrorMessage => _lastErrorMessage.value;
  DateTime? get lastAttemptAt => _lastAttemptAt.value;
  DateTime? get lastSuccessAt => _lastSuccessAt.value;
  int get consecutiveFailures => _consecutiveFailures.value;

  Stream<bool> get firebaseReadyStream => _firebaseReady.stream;

  /// Attempts to initialize Firebase if not ready yet.
  Future<void> initialize() {
    if (_firebaseReady.value) {
      return Future<void>.value();
    }

    _inFlightInitialization ??= _initializeInternal();
    return _inFlightInitialization!;
  }

  /// Re-attempts Firebase initialization when previous attempts failed.
  Future<void> retry() {
    if (_isInitializing.value) {
      return _inFlightInitialization ?? Future<void>.value();
    }
    return initialize();
  }

  /// Registers a callback that fires once Firebase becomes ready.
  void addOnReadyCallback(FirebaseReadyCallback callback) {
    if (_firebaseReady.value) {
      unawaited(callback());
      return;
    }
    _readyCallbacks.add(callback);
  }

  Future<void> _initializeInternal() async {
    _isInitializing.value = true;
    _lastAttemptAt.value = DateTime.now();
    _lastErrorMessage.value = null;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firebaseReady.value = true;
      _lastSuccessAt.value = DateTime.now();
      _consecutiveFailures.value = 0;
      await _notifyReadyCallbacks();
    } catch (error, stackTrace) {
      _firebaseReady.value = false;
      _lastErrorMessage.value = error.toString();
      _consecutiveFailures.value++;
      if (kDebugMode) {
        debugPrint('Firebase initialization failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    } finally {
      _isInitializing.value = false;
      _inFlightInitialization = null;
    }
  }

  Future<void> _notifyReadyCallbacks() async {
    if (_readyCallbacks.isEmpty) {
      return;
    }

    final callbacks = List<FirebaseReadyCallback>.from(_readyCallbacks);
    _readyCallbacks.clear();

    for (final FirebaseReadyCallback callback in callbacks) {
      try {
        await callback();
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Firebase ready callback failed: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
    }
  }

  @visibleForTesting
  void debugSetState({
    bool? ready,
    bool? initializing,
    String? errorMessage,
    DateTime? lastAttempt,
    DateTime? lastSuccess,
    int? failureCount,
  }) {
    if (ready != null) {
      _firebaseReady.value = ready;
    }
    if (initializing != null) {
      _isInitializing.value = initializing;
    }
    if (errorMessage != null) {
      _lastErrorMessage.value = errorMessage;
    }
    if (lastAttempt != null) {
      _lastAttemptAt.value = lastAttempt;
    }
    if (lastSuccess != null) {
      _lastSuccessAt.value = lastSuccess;
    }
    if (failureCount != null) {
      _consecutiveFailures.value = failureCount;
    }
  }
}
