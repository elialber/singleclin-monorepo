/// Base class for authentication exceptions
abstract class AuthException implements Exception {
  const AuthException(this.message, this.code);

  final String message;
  final String code;

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

/// Exception thrown when email/password authentication fails
class EmailPasswordAuthException extends AuthException {
  const EmailPasswordAuthException(super.message, super.code);
}

/// Exception thrown when Google Sign-In fails
class GoogleSignInException extends AuthException {
  const GoogleSignInException(super.message, super.code);
}

/// Exception thrown when Apple Sign-In fails
class AppleSignInException extends AuthException {
  const AppleSignInException(super.message, super.code);
}

/// Exception thrown when user registration fails
class UserRegistrationException extends AuthException {
  const UserRegistrationException(super.message, super.code);
}

/// Exception thrown when user is not authenticated
class UserNotAuthenticatedException extends AuthException {
  const UserNotAuthenticatedException()
      : super('User is not authenticated', 'user-not-authenticated');
}

/// Exception thrown when token retrieval fails
class TokenRetrievalException extends AuthException {
  const TokenRetrievalException(super.message, super.code);
}

/// Generic authentication exception
class GenericAuthException extends AuthException {
  const GenericAuthException(super.message, super.code);
}

/// Exception thrown when sign out fails
class SignOutException extends AuthException {
  const SignOutException(super.message, super.code);
}

/// Exception thrown when password reset fails
class PasswordResetException extends AuthException {
  const PasswordResetException(super.message, super.code);
}

/// Exception thrown when email verification fails
class EmailVerificationException extends AuthException {
  const EmailVerificationException(super.message, super.code);
}

/// Exception thrown when profile update fails
class ProfileUpdateException extends AuthException {
  const ProfileUpdateException(super.message, super.code);
}

/// Exception thrown when account deletion fails
class AccountDeletionException extends AuthException {
  const AccountDeletionException(super.message, super.code);
}

/// Utility class for creating auth exceptions from Firebase error codes
class AuthExceptionMapper {
  static AuthException fromFirebaseException(dynamic exception) {
    final String code = exception?.code ?? 'unknown';
    final String message = exception?.message ?? 'An unknown error occurred';

    switch (code) {
      case 'weak-password':
        return UserRegistrationException(
          'The password provided is too weak',
          code,
        );
      case 'email-already-in-use':
        return UserRegistrationException(
          'The account already exists for that email',
          code,
        );
      case 'user-not-found':
        return EmailPasswordAuthException(
          'No user found for that email',
          code,
        );
      case 'wrong-password':
        return EmailPasswordAuthException(
          'Wrong password provided for that user',
          code,
        );
      case 'invalid-email':
        return EmailPasswordAuthException(
          'The email address is badly formatted',
          code,
        );
      case 'user-disabled':
        return EmailPasswordAuthException(
          'The user account has been disabled',
          code,
        );
      case 'too-many-requests':
        return EmailPasswordAuthException(
          'Too many requests. Try again later',
          code,
        );
      case 'operation-not-allowed':
        return EmailPasswordAuthException(
          'Operation not allowed',
          code,
        );
      case 'account-exists-with-different-credential':
        return GoogleSignInException(
          'Account exists with different credential',
          code,
        );
      case 'invalid-credential':
        return GoogleSignInException(
          'Invalid credential provided',
          code,
        );
      case 'credential-already-in-use':
        return GoogleSignInException(
          'Credential is already associated with another user account',
          code,
        );
      case 'sign_in_canceled':
        return GoogleSignInException(
          'Sign in was canceled by user',
          code,
        );
      case 'network-error':
        return EmailPasswordAuthException(
          'Network error occurred',
          code,
        );
      case 'requires-recent-login':
        return ProfileUpdateException(
          'This operation requires recent authentication',
          code,
        );
      default:
        return EmailPasswordAuthException(message, code);
    }
  }
}