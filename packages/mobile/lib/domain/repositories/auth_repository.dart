import 'dart:async';
import '../entities/user_entity.dart';

/// Repository interface for authentication operations
/// 
/// This abstract class defines the contract for authentication operations
/// that can be implemented using different authentication providers (Firebase, etc.)
abstract class AuthRepository {
  /// Stream that emits the current authentication state changes
  /// Returns null when user is not authenticated
  Stream<UserEntity?> get authStateChanges;

  /// Sign in with email and password
  /// 
  /// [email] User's email address
  /// [password] User's password
  /// 
  /// Returns [UserEntity] if authentication is successful
  /// Throws [AuthException] if authentication fails
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with Google account
  /// 
  /// Returns [UserEntity] if authentication is successful
  /// Throws [AuthException] if authentication fails
  Future<UserEntity> signInWithGoogle();

  /// Sign in with Apple ID
  /// 
  /// Returns [UserEntity] if authentication is successful
  /// Throws [AuthException] if authentication fails
  Future<UserEntity> signInWithApple();

  /// Create a new user account with email and password
  /// 
  /// [email] User's email address
  /// [password] User's password
  /// [name] User's display name
  /// 
  /// Returns [UserEntity] if account creation is successful
  /// Throws [AuthException] if account creation fails
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String name,
  });

  /// Sign out the current user
  /// 
  /// Throws [AuthException] if sign out fails
  Future<void> signOut();

  /// Get the currently authenticated user
  /// 
  /// Returns [UserEntity] if user is authenticated, null otherwise
  Future<UserEntity?> getCurrentUser();

  /// Check if a user is currently authenticated
  /// 
  /// Returns true if user is authenticated, false otherwise
  Future<bool> isAuthenticated();

  /// Get the current user's ID token
  /// 
  /// [forceRefresh] Whether to force token refresh
  /// 
  /// Returns the ID token string if user is authenticated
  /// Throws [AuthException] if user is not authenticated or token retrieval fails
  Future<String> getIdToken({bool forceRefresh = false});

  /// Send password reset email
  /// 
  /// [email] User's email address
  /// 
  /// Throws [AuthException] if email sending fails
  Future<void> sendPasswordResetEmail({required String email});

  /// Verify email address
  /// 
  /// Sends a verification email to the current user
  /// Throws [AuthException] if user is not authenticated or email sending fails
  Future<void> sendEmailVerification();

  /// Update user profile information
  /// 
  /// [name] New display name (optional)
  /// [photoUrl] New photo URL (optional)
  /// 
  /// Returns updated [UserEntity]
  /// Throws [AuthException] if update fails
  Future<UserEntity> updateProfile({
    String? name,
    String? photoUrl,
  });

  /// Delete the current user account
  /// 
  /// Throws [AuthException] if deletion fails
  Future<void> deleteUser();
}