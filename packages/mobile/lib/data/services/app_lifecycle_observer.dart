import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:singleclin_mobile/data/services/token_refresh_service.dart';

/// Observer for app lifecycle events to manage token refresh service
///
/// This class implements WidgetsBindingObserver to listen for app lifecycle
/// changes and pause/resume the token refresh service accordingly to optimize
/// battery usage and prevent unnecessary network calls in the background.
class AppLifecycleObserver with WidgetsBindingObserver {
  AppLifecycleObserver(this._tokenRefreshService);
  final TokenRefreshService _tokenRefreshService;

  /// Initialize the lifecycle observer
  ///
  /// This method registers the observer with WidgetsBinding to start
  /// listening for app lifecycle events.
  void initialize() {
    WidgetsBinding.instance.addObserver(this);

    if (kDebugMode) {
      print('🔄 AppLifecycleObserver: Initialized');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (kDebugMode) {
      print('🔄 AppLifecycleObserver: App state changed to $state');
    }

    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground and active
        unawaited(_tokenRefreshService.resume(forceRefresh: true));
        break;

      case AppLifecycleState.paused:
        // App is in background but still running
        _tokenRefreshService.pause();
        break;

      case AppLifecycleState.detached:
        // App process is being destroyed
        _tokenRefreshService.pause();
        break;

      case AppLifecycleState.inactive:
        // App is transitioning between states (e.g., incoming call)
        // Pause timers to avoid unnecessary work while the app is not active
        _tokenRefreshService.pause();
        break;

      case AppLifecycleState.hidden:
        // App is hidden (iOS specific)
        _tokenRefreshService.pause();
        break;
    }
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();

    if (kDebugMode) {
      print('⚠️ AppLifecycleObserver: Memory pressure detected');
    }

    // Could pause token refresh temporarily during memory pressure
    // For now, we'll just log it for debugging
  }

  /// Dispose the observer and clean up resources
  ///
  /// This method removes the observer from WidgetsBinding and should
  /// be called when the observer is no longer needed.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    if (kDebugMode) {
      print('🔄 AppLifecycleObserver: Disposed');
    }
  }
}
