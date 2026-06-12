import 'package:coffix_app/features/auth/data/model/user.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<void> signInWithGoogle();
  Future<void> signInWithFacebook();
  Future<void> signInWithApple();

  /// Re-authenticates an existing email/password account and links the pending
  /// SSO credential (captured during a failed [signInWithGoogle] /
  /// [signInWithApple]) to it, so both providers share one Firebase UID.
  Future<void> linkPendingCredentialWithPassword({
    required String email,
    required String password,
  });
  Future<void> createUserDoc({required String docId, required String email});
  Future<bool> isUserDisabled({required UserCredential credential});
  Stream<AppUser?> getUser();
  Future<void> sendEmailVerification({required String email});
  Future<void> verifyOtp({required String otp});
  Future<void> updateLastLogin();
  Future<void> deleteAccount();
  Future<String> getFirebaseToken();
  Future<bool> customerHasAccount({required String email});

  /// Returns the sign-in provider IDs linked to the account for [email]
  /// (e.g. `['password', 'google.com']`). Empty when no account exists.
  Future<List<String>> getProvidersForEmail({required String email});
  Future<String> sendPasswordResetEmail({required String email});
  Future<void> updateFcmToken();
  Future<void> updateUser({required String uid});
}
