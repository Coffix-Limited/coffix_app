class UserCancelledSignIn implements Exception {}

/// Thrown when a user tries to sign in with an SSO provider (Google/Apple)
/// using an email that already belongs to an existing email/password account.
/// The pending SSO credential is held on the repository so it can be linked
/// to the existing account once the user re-authenticates with their password.
class AccountExistsWithDifferentCredential implements Exception {
  AccountExistsWithDifferentCredential({
    required this.email,
    required this.provider,
  });

  /// The email of the existing account.
  final String email;

  /// The SSO provider the user attempted to use, e.g. 'google.com' or
  /// 'apple.com'.
  final String provider;
}

String getAuthExceptionMessage(String code) {
  switch (code) {
    case 'user-disabled':
      return 'Your account has been disabled. Please contact support.';
    case 'invalid-credential':
      return 'Incorrect email or password. Please try again.';
    case 'invalid-email':
      return 'The email address is not valid.';
    case 'invalid-password':
    case 'wrong-password':
      return 'Incorrect password. Please try again.';
    case 'user-not-found':
      return 'No account found with this email.';
    case 'email-already-in-use':
      return 'An account already exists with this email.';
    case 'weak-password':
      return 'Password is too weak. Use at least 6 characters.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
      return 'Network error. Please check your connection and try again.';
    case 'requires-recent-login':
      return 'Please sign out and sign in again to continue.';
    case 'account-exists-with-different-credential':
      return 'An account already exists with a different sign-in method.';
    case 'operation-not-allowed':
      return 'This sign-in method is not enabled.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
