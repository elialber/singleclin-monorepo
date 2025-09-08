import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:singleclin_mobile/data/services/auth_service.dart';
import 'package:singleclin_mobile/domain/entities/user_entity.dart';

/// Service for managing automatic token refresh and session persistence
///
/// This service ensures that JWT tokens are refreshed before expiration
/// and handles app lifecycle events to optimize battery usage and performance.
class TokenRefreshService {
  TokenRefreshService({AuthService? authService, FirebaseAuth? firebaseAuth})
    : _authService = authService ?? AuthService(),
      _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;
  final AuthService _authService;
  final FirebaseAuth _firebaseAuth;

  Timer? _refreshTimer;
  StreamSubscription<UserEntity?>? _authStateSubscription;
  UserEntity? _currentUser;

  // Token refresh interval (50 minutes - tokens expire in 60 minutes)
  static const Duration _refreshInterval = Duration(minutes: 50);

  // Check if service is active
  bool _isActive = false;

  /// Initialize the token refresh service
  ///
  /// This method should be called when the app starts to begin
  /// monitoring auth state changes and managing token refresh.
  Future<void> initialize() async {
    if (_isActive) {
      return;
    }

    _isActive = true;

    if (kDebugMode) {
      print('🔄 TokenRefreshService: Initializing...');
    }

    // Listen to auth state changes
    _authStateSubscription = _authService.authStateChanges.listen(
      _onAuthStateChanged,
    );

    // Check current auth state
    final currentUser = await _authService.getCurrentUser();
    _onAuthStateChanged(currentUser);
  }

  /// Handle authentication state changes
  void _onAuthStateChanged(UserEntity? user) {
    _currentUser = user;

    if (user != null) {
      _startTokenRefresh();
      if (kDebugMode) {
        print(
          '🔄 TokenRefreshService: User authenticated, starting token refresh',
        );
      }
    } else {
      _stopTokenRefresh();
      if (kDebugMode) {
        print(
          '🔄 TokenRefreshService: User signed out, stopping token refresh',
        );
      }
    }
  }

  /// Start the automatic token refresh timer
  void _startTokenRefresh() {
    _stopTokenRefresh(); // Cancel any existing timer

    _refreshTimer = Timer.periodic(_refreshInterval, (timer) async {
      await _refreshToken();
    });

    if (kDebugMode) {
      print(
        '🔄 TokenRefreshService: Token refresh timer started (${_refreshInterval.inMinutes} min intervals)',
      );
    }
  }

  /// Stop the automatic token refresh timer
  void _stopTokenRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;

    if (kDebugMode) {
      print('🔄 TokenRefreshService: Token refresh timer stopped');
    }
  }

  /// Manually refresh the current user's token
  ///
  /// This method forces a token refresh and can be called manually
  /// when needed (e.g., before making critical API calls).
  Future<String?> refreshToken() async {
    return _refreshToken();
  }

  /// Internal method to perform token refresh
  Future<String?> _refreshToken() async {
    try {
      if (_currentUser == null) {
        if (kDebugMode) {
          print(
            '⚠️ TokenRefreshService: No authenticated user, skipping token refresh',
          );
        }
        return null;
      }

      final user = _firebaseAuth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print(
            '⚠️ TokenRefreshService: Firebase user is null, stopping token refresh',
          );
        }
        _stopTokenRefresh();
        return null;
      }

      // Force refresh the token
      final String? token = await user.getIdToken(true);

      if (kDebugMode) {
        print('✅ TokenRefreshService: Token refreshed successfully');
      }

      return token;
    } catch (e) {
      if (kDebugMode) {
        print('❌ TokenRefreshService: Token refresh failed: $e');
      }

      // If token refresh fails due to network issues, continue trying
      // If it fails due to auth issues, the auth state listener will handle it
      if (e is PlatformException && e.code == 'network_error') {
        // Continue with timer for network errors
        return null;
      }

      // For other errors, let auth state handle the cleanup
      return null;
    }
  }

  /// Pause the token refresh service
  ///
  /// This method should be called when the app goes to background
  /// to preserve battery and avoid unnecessary network calls.
  void pause() {
    if (!_isActive) {
      return;
    }

    _stopTokenRefresh();

    if (kDebugMode) {
      print('⏸️ TokenRefreshService: Paused (app in background)');
    }
  }

  /// Resume the token refresh service
  ///
  /// This method should be called when the app comes back to foreground
  /// to resume automatic token management.
  void resume() {
    if (!_isActive || _currentUser == null) {
      return;
    }

    _startTokenRefresh();

    if (kDebugMode) {
      print('▶️ TokenRefreshService: Resumed (app in foreground)');
    }
  }

  /// Check if the current token is close to expiration
  ///
  /// Firebase ID tokens expire after 1 hour. This method can be used
  /// to proactively check if a refresh is needed.
  Future<bool> isTokenExpiringSoon() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return true;
      }

      final IdTokenResult tokenResult = await user.getIdTokenResult();
      final DateTime? expirationTime = tokenResult.expirationTime;

      if (expirationTime == null) {
        return true;
      }

      final DateTime now = DateTime.now();
      final Duration timeUntilExpiration = expirationTime.difference(now);

      // Consider token as expiring soon if less than 10 minutes left
      return timeUntilExpiration.inMinutes < 10;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ TokenRefreshService: Error checking token expiration: $e');
      }
      return true; // Assume expiring on error
    }
  }

  /// Get the current token, refreshing if necessary
  ///
  /// This method checks if the token is close to expiration and
  /// refreshes it if needed before returning.
  Future<String?> getCurrentToken() async {
    try {
      final bool needsRefresh = await isTokenExpiringSoon();

      if (needsRefresh) {
        if (kDebugMode) {
          print('🔄 TokenRefreshService: Token expiring soon, refreshing...');
        }
        return await _refreshToken();
      }

      // Token is still valid, get it without forcing refresh
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return null;
      }

      return await user.getIdToken();
    } catch (e) {
      if (kDebugMode) {
        print('❌ TokenRefreshService: Error getting current token: $e');
      }
      return null;
    }
  }

  /// Dispose the service and clean up resources
  ///
  /// This method should be called when the service is no longer needed
  /// to prevent memory leaks and background processing.
  void dispose() {
    _isActive = false;
    _stopTokenRefresh();
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
    _currentUser = null;

    if (kDebugMode) {
      print('🔄 TokenRefreshService: Disposed');
    }
  }

  /// Get service status information for debugging
  Map<String, dynamic> getStatus() {
    return {
      'isActive': _isActive,
      'hasUser': _currentUser != null,
      'hasTimer': _refreshTimer != null,
      'timerActive': _refreshTimer?.isActive ?? false,
      'refreshIntervalMinutes': _refreshInterval.inMinutes,
    };
  }
}
