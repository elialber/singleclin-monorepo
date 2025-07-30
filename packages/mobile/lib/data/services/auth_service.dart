import 'dart:async';

import 'package:mobile/data/repositories/firebase_auth_repository.dart';
import 'package:mobile/domain/entities/user_entity.dart';
import 'package:mobile/domain/repositories/auth_repository.dart';

/// Service class to wrap AuthRepository for dependency injection
///
/// This service acts as a single source of truth for authentication
/// operations across the app, providing a clean interface for
/// the presentation layer to interact with authentication logic.
class AuthService {
  AuthService({AuthRepository? authRepository})
    : _authRepository = authRepository ?? FirebaseAuthRepository() {
    // Listen to auth state changes and broadcast them
    _authRepository.authStateChanges.listen((user) {
      _authStateController.add(user);
    });
  }
  final AuthRepository _authRepository;

  // Stream controller to manage auth state across the app
  final StreamController<UserEntity?> _authStateController =
      StreamController<UserEntity?>.broadcast();

  /// Stream of authentication state changes
  Stream<UserEntity?> get authStateChanges => _authStateController.stream;

  /// Sign in with email and password
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _authRepository.signInWithEmail(email: email, password: password);
  }

  /// Sign in with Google account
  Future<UserEntity> signInWithGoogle() async {
    return _authRepository.signInWithGoogle();
  }

  /// Sign in with Apple ID
  Future<UserEntity> signInWithApple() async {
    return _authRepository.signInWithApple();
  }

  /// Create a new user account
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return _authRepository.signUp(email: email, password: password, name: name);
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  /// Get the currently authenticated user
  Future<UserEntity?> getCurrentUser() async {
    return _authRepository.getCurrentUser();
  }

  /// Check if a user is currently authenticated
  Future<bool> isAuthenticated() async {
    return _authRepository.isAuthenticated();
  }

  /// Get the current user's ID token
  Future<String> getIdToken({bool forceRefresh = false}) async {
    return _authRepository.getIdToken(forceRefresh: forceRefresh);
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _authRepository.sendPasswordResetEmail(email: email);
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    await _authRepository.sendEmailVerification();
  }

  /// Update user profile information
  Future<UserEntity> updateProfile({String? name, String? photoUrl}) async {
    return _authRepository.updateProfile(name: name, photoUrl: photoUrl);
  }

  /// Delete the current user account
  Future<void> deleteUser() async {
    await _authRepository.deleteUser();
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
