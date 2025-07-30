import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/errors/auth_exceptions.dart';
import '../models/user_model.dart';

/// Firebase implementation of AuthRepository
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((User? user) {
      if (user == null) return null;
      return _mapFirebaseUserToEntity(user);
    });
  }

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user == null) {
        throw const EmailPasswordAuthException(
          'Sign in failed - no user returned',
          'sign-in-failed',
        );
      }
      
      return _mapFirebaseUserToEntity(result.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionMapper.fromFirebaseException(e);
    } catch (e) {
      throw EmailPasswordAuthException(
        'An unexpected error occurred: ${e.toString()}',
        'unexpected-error',
      );
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw const GoogleSignInException(
          'Google sign in was cancelled',
          'sign-in-cancelled',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential result = await _firebaseAuth.signInWithCredential(credential);
      
      if (result.user == null) {
        throw const GoogleSignInException(
          'Google sign in failed - no user returned',
          'sign-in-failed',
        );
      }

      return _mapFirebaseUserToEntity(result.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionMapper.fromFirebaseException(e);
    } catch (e) {
      throw GoogleSignInException(
        'Google sign in failed: ${e.toString()}',
        'google-sign-in-error',
      );
    }
  }

  @override
  Future<UserEntity> signInWithApple() async {
    try {
      // Generate a random nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create an `OAuthCredential` from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Sign in the user with Firebase
      final UserCredential result = await _firebaseAuth.signInWithCredential(oauthCredential);
      
      if (result.user == null) {
        throw const AppleSignInException(
          'Apple sign in failed - no user returned',
          'sign-in-failed',
        );
      }

      // Update display name if provided by Apple and not already set
      if (result.additionalUserInfo?.isNewUser == true && 
          appleCredential.givenName != null && 
          appleCredential.familyName != null) {
        final displayName = '${appleCredential.givenName} ${appleCredential.familyName}';
        await result.user!.updateDisplayName(displayName);
      }

      return _mapFirebaseUserToEntity(result.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionMapper.fromFirebaseException(e);
    } on SignInWithAppleException catch (e) {
      throw AppleSignInException(
        'Apple sign in failed: ${e.toString()}',
        'apple-sign-in-error',
      );
    } catch (e) {
      throw AppleSignInException(
        'Apple sign in failed: ${e.toString()}',
        'apple-sign-in-error',
      );
    }
  }

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user == null) {
        throw const UserRegistrationException(
          'User registration failed - no user returned',
          'registration-failed',
        );
      }

      // Update the user's display name
      await result.user!.updateDisplayName(name);
      
      // Send email verification
      await result.user!.sendEmailVerification();

      return _mapFirebaseUserToEntity(result.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionMapper.fromFirebaseException(e);
    } catch (e) {
      throw UserRegistrationException(
        'User registration failed: ${e.toString()}',
        'registration-error',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Sign out from Firebase
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionMapper.fromFirebaseException(e);
    } catch (e) {
      throw SignOutException(
        'Sign out failed: ${e.toString()}',
        'sign-out-error',
      );
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user == null) return null;
      
      return _mapFirebaseUserToEntity(user);
    } catch (e) {
      throw GenericAuthException(
        'Failed to get current user: ${e.toString()}',
        'get-current-user-error',
      );
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _firebaseAuth.currentUser != null;
  }

  @override
  Future<String> getIdToken({bool forceRefresh = false}) async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const UserNotAuthenticatedException();
      }
      
      final token = await user.getIdToken(forceRefresh);
      if (token == null) {
        throw const TokenRetrievalException(
          'Failed to retrieve ID token',
          'token-null',
        );
      }
      return token;
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionMapper.fromFirebaseException(e);
    } catch (e) {
      if (e is UserNotAuthenticatedException) rethrow;
      throw TokenRetrievalException(
        'Failed to get ID token: ${e.toString()}',
        'token-retrieval-error',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionMapper.fromFirebaseException(e);
    } catch (e) {
      throw PasswordResetException(
        'Failed to send password reset email: ${e.toString()}',
        'password-reset-error',
      );
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const UserNotAuthenticatedException();
      }
      
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionMapper.fromFirebaseException(e);
    } catch (e) {
      if (e is UserNotAuthenticatedException) rethrow;
      throw EmailVerificationException(
        'Failed to send email verification: ${e.toString()}',
        'email-verification-error',
      );
    }
  }

  @override
  Future<UserEntity> updateProfile({
    String? name,
    String? photoUrl,
  }) async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const UserNotAuthenticatedException();
      }

      if (name != null) {
        await user.updateDisplayName(name);
      }
      
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // Reload user to get updated information
      await user.reload();
      final updatedUser = _firebaseAuth.currentUser;
      
      return _mapFirebaseUserToEntity(updatedUser!);
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionMapper.fromFirebaseException(e);
    } catch (e) {
      if (e is UserNotAuthenticatedException) rethrow;
      throw ProfileUpdateException(
        'Failed to update profile: ${e.toString()}',
        'profile-update-error',
      );
    }
  }

  @override
  Future<void> deleteUser() async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const UserNotAuthenticatedException();
      }
      
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionMapper.fromFirebaseException(e);
    } catch (e) {
      if (e is UserNotAuthenticatedException) rethrow;
      throw AccountDeletionException(
        'Failed to delete user account: ${e.toString()}',
        'account-deletion-error',
      );
    }
  }

  /// Map Firebase User to UserEntity
  UserEntity _mapFirebaseUserToEntity(User user) {
    return UserEntity(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      phoneNumber: user.phoneNumber,
      photoUrl: user.photoURL,
      role: 'patient', // Default role - this should be fetched from your backend
      isActive: true,
      isEmailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Generate a cryptographically secure random nonce
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Returns the sha256 hash of [input] in hex notation
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}