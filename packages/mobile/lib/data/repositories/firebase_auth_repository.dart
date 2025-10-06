import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:singleclin_mobile/core/errors/auth_exceptions.dart'
    as local_auth;
import 'package:singleclin_mobile/domain/entities/user_entity.dart';
import 'package:singleclin_mobile/domain/repositories/auth_repository.dart';

/// Firebase implementation of AuthRepository
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((User? user) {
      if (user == null) {
        return null;
      }
      return _mapFirebaseUserToEntity(user);
    });
  }

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔑 Firebase Auth: Attempting signInWithEmailAndPassword');
      print('📧 Email: $email');
      print('🔒 Password length: ${password.length}');

      final UserCredential result = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      print('✅ Firebase Auth: signInWithEmailAndPassword completed');

      if (result.user == null) {
        print('❌ Firebase Auth: No user returned from successful auth');
        throw const local_auth.EmailPasswordAuthException(
          'Sign in failed - no user returned',
          'sign-in-failed',
        );
      }

      print('👤 Firebase Auth: User authenticated - UID: ${result.user!.uid}');
      return _mapFirebaseUserToEntity(result.user!);
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Exception:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      print('   Plugin: ${e.plugin}');
      throw local_auth.AuthExceptionMapper.fromFirebaseException(e);
    } catch (e) {
      print('❌ Unexpected error in Firebase Auth: $e');
      throw local_auth.EmailPasswordAuthException(
        'An unexpected error occurred: ${e.toString()}',
        'unexpected-error',
      );
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      // Check if authentication is supported
      if (!_googleSignIn.supportsAuthenticate()) {
        throw const local_auth.GoogleSignInException(
          'Google sign in is not supported on this platform',
          'not-supported',
        );
      }

      // Trigger the authentication flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential firebaseResult = await _firebaseAuth
          .signInWithCredential(credential);

      if (firebaseResult.user == null) {
        throw const local_auth.GoogleSignInException(
          'Google sign in failed - no user returned',
          'sign-in-failed',
        );
      }

      return _mapFirebaseUserToEntity(firebaseResult.user!);
    } on FirebaseAuthException catch (e) {
      throw local_auth.AuthExceptionMapper.fromFirebaseException(e);
    } catch (e) {
      throw local_auth.GoogleSignInException(
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
      final oauthCredential = OAuthProvider(
        'apple.com',
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

      // Sign in the user with Firebase
      final UserCredential result = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );

      if (result.user == null) {
        throw const local_auth.AppleSignInException(
          'Apple sign in failed - no user returned',
          'sign-in-failed',
        );
      }

      // Update display name if provided by Apple and not already set
      if ((result.additionalUserInfo?.isNewUser ?? false) &&
          appleCredential.givenName != null &&
          appleCredential.familyName != null) {
        final displayName =
            '${appleCredential.givenName} ${appleCredential.familyName}';
        await result.user!.updateDisplayName(displayName);
      }

      return _mapFirebaseUserToEntity(result.user!);
    } on FirebaseAuthException catch (e) {
      throw local_auth.AuthExceptionMapper.fromFirebaseException(e);
    } on SignInWithAppleException catch (e) {
      throw local_auth.AppleSignInException(
        'Apple sign in failed: ${e.toString()}',
        'apple-sign-in-error',
      );
    } catch (e) {
      throw local_auth.AppleSignInException(
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
      final UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (result.user == null) {
        throw const local_auth.UserRegistrationException(
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
      throw local_auth.AuthExceptionMapper.fromFirebaseException(e);
    } catch (e) {
      throw local_auth.UserRegistrationException(
        'User registration failed: ${e.toString()}',
        'registration-error',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in
      await _googleSignIn.signOut();

      // Sign out from Firebase
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw local_auth.AuthExceptionMapper.fromFirebaseException(e);
    } catch (e) {
      throw local_auth.SignOutException(
        'Sign out failed: ${e.toString()}',
        'sign-out-error',
      );
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user == null) {
        return null;
      }

      return _mapFirebaseUserToEntity(user);
    } catch (e) {
      throw local_auth.GenericAuthException(
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
        throw const local_auth.UserNotAuthenticatedException();
      }

      final token = await user.getIdToken(forceRefresh);
      if (token == null) {
        throw const local_auth.TokenRetrievalException(
          'Failed to retrieve ID token',
          'token-null',
        );
      }
      return token;
    } on FirebaseAuthException catch (e) {
      throw local_auth.AuthExceptionMapper.fromFirebaseException(e);
    } catch (e) {
      if (e is local_auth.UserNotAuthenticatedException) {
        rethrow;
      }
      throw local_auth.TokenRetrievalException(
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
      throw local_auth.AuthExceptionMapper.fromFirebaseException(e);
    } catch (e) {
      throw local_auth.PasswordResetException(
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
        throw const local_auth.UserNotAuthenticatedException();
      }

      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw local_auth.AuthExceptionMapper.fromFirebaseException(e);
    } catch (e) {
      if (e is local_auth.UserNotAuthenticatedException) {
        rethrow;
      }
      throw local_auth.EmailVerificationException(
        'Failed to send email verification: ${e.toString()}',
        'email-verification-error',
      );
    }
  }

  @override
  Future<UserEntity> updateProfile({String? name, String? photoUrl}) async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const local_auth.UserNotAuthenticatedException();
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
      throw local_auth.AuthExceptionMapper.fromFirebaseException(e);
    } catch (e) {
      if (e is local_auth.UserNotAuthenticatedException) {
        rethrow;
      }
      throw local_auth.ProfileUpdateException(
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
        throw const local_auth.UserNotAuthenticatedException();
      }

      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw local_auth.AuthExceptionMapper.fromFirebaseException(e);
    } catch (e) {
      if (e is local_auth.UserNotAuthenticatedException) {
        rethrow;
      }
      throw local_auth.AccountDeletionException(
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
      role:
          'patient', // Default role - this should be fetched from your backend
      isActive: true,
      isEmailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Generate a cryptographically secure random nonce
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns the sha256 hash of [input] in hex notation
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
