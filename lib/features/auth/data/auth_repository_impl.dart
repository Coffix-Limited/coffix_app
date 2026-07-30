import 'dart:convert';
import 'dart:math' hide log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffix_app/core/api/api_client.dart';
import 'package:coffix_app/core/api/model/endpoints.dart';
import 'package:coffix_app/core/constants/constants.dart';
import 'package:coffix_app/core/errors/auth_exceptions.dart'
    show UserCancelledSignIn, AccountExistsWithDifferentCredential;
import 'package:coffix_app/core/utils/time_utils.dart';
import 'package:coffix_app/data/repositories/auth_repository.dart';
import 'package:coffix_app/domain/firestore_service.dart';
import 'package:coffix_app/features/app/data/model/global.dart';
import 'package:coffix_app/features/auth/data/model/user.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthRepositoryImpl extends ApiClient implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirestoreService.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Holds the SSO credential (Google/Apple) that could not be signed in
  /// because the email already belongs to an existing email/password account.
  /// It is consumed by [linkPendingCredentialWithPassword] after the user
  /// re-authenticates with their password.
  AuthCredential? _pendingCredential;

  AuthRepositoryImpl() : super(dio: Dio());

  @override
  Future<void> signInWithEmailAndPassword({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final isDisabled = await isUserDisabled(credential: credential);
      if (isDisabled) {
        await _auth.signOut();
        throw FirebaseAuthException(code: 'user-disabled', message: 'User is disabled');
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<void> signUpWithEmailAndPassword({required String email, required String password}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await createUserDoc(docId: credential.user!.uid, email: credential.user!.email!);
    } on FirebaseAuthException catch (e, st) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Email already in use');
      }
      debugPrint('signUp error: $e\n$st'); // see real error in console
      rethrow;
    } catch (e, st) {
      debugPrint('signUp error: $e\n$st'); // see real error in console
      throw Exception(e);
    }
  }

  @override
  Future<void> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: hashedNonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null) {
        throw Exception('Apple Sign In failed: No ID token');
      }

      final oauthCredential = OAuthProvider(
        'apple.com',
      ).credential(idToken: idToken, rawNonce: rawNonce, accessToken: appleCredential.authorizationCode);

      final credentialResult = await _auth.signInWithCredential(oauthCredential);

      if (credentialResult.user != null) {
        final disabled = await isUserDisabled(credential: credentialResult);
        if (disabled) {
          await _auth.signOut();
          throw FirebaseAuthException(code: 'user-disabled', message: 'User is disabled');
        }
        final email =
            credentialResult.user!.email ??
            appleCredential.email ??
            '${credentialResult.user!.uid}@privaterelay.appleid.com';
        await createUserDoc(docId: credentialResult.user!.uid, email: email);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        // An email/password account already exists for this email. Hold the
        // pending Apple credential so it can be linked once the user
        // re-authenticates with their password.
        _pendingCredential = e.credential;
        throw AccountExistsWithDifferentCredential(email: e.email ?? '', provider: 'apple.com');
      }
      rethrow;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw UserCancelledSignIn();
      }
      rethrow;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Returns SHA256 hash as a HEX string (this is what Firebase expects you to
  /// send to Apple as `nonce:`).
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString(); // hex
  }

  @override
  Future<void> linkPendingCredentialWithPassword({required String email, required String password}) async {
    final pending = _pendingCredential;
    if (pending == null) {
      throw Exception('No pending credential to link.');
    }
    try {
      final userCred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final isDisabled = await isUserDisabled(credential: userCred);
      if (isDisabled) {
        await _auth.signOut();
        throw FirebaseAuthException(code: 'user-disabled', message: 'User is disabled');
      }
      // Attach the SSO provider to the existing UID. The customer doc already
      // exists, so we intentionally do NOT call createUserDoc here.
      await userCred.user!.linkWithCredential(pending);
      _pendingCredential = null;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<void> signInWithFacebook() {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize();
      final GoogleSignInAccount account = await _googleSignIn.authenticate(scopeHint: ["email"]);

      final authClient = _googleSignIn.authorizationClient;
      final authorization = await authClient.authorizationForScopes(['email']);

      if (authorization == null) {
        throw Exception("Google Sign In failed: No authorization found");
      }

      final GoogleSignInAuthentication authentication = account.authentication;

      if (authentication.idToken == null) {
        throw Exception("Google Sign In failed: No ID token found");
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: authentication.idToken,
      );

      try {
        final credentialResult = await _auth.signInWithCredential(credential);
        final disabled = await isUserDisabled(credential: credentialResult);
        if (disabled) {
          await _auth.signOut();
          throw FirebaseAuthException(code: 'user-disabled', message: 'User is disabled');
        }
        await createUserDoc(docId: credentialResult.user!.uid, email: credentialResult.user!.email!);
        return credentialResult;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          // An email/password account already exists for this email. Hold the
          // pending Google credential so it can be linked once the user
          // re-authenticates with their password.
          _pendingCredential = e.credential;
          throw AccountExistsWithDifferentCredential(email: e.email ?? '', provider: 'google.com');
        }
        rethrow;
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw UserCancelledSignIn();
      }
      rethrow;
    } catch (error) {
      rethrow;
    }
  }

  String generateQrId(String docId) {
    final random = Random();

    // First group based on docId hash
    final first = (docId.hashCode.abs() % 10000).toString().padLeft(4, '0');

    // Random groups
    String randomGroup() => List.generate(4, (_) => random.nextInt(10)).join();

    final second = randomGroup();
    final third = randomGroup();

    // Last group based on timestamp
    final now = TimeUtils.now().millisecondsSinceEpoch;
    final fourth = (now % 10000).toString().padLeft(4, '0');

    return '$first-$second-$third-$fourth';
  }

  @override
  Future<void> createUserDoc({required String docId, required String email}) async {
    final globalSnap = await _firestore.collection('global').doc(AppConstants.globalCollectionDocId).get();
    final global = AppGlobal.fromJson(globalSnap.data() ?? {});

    final ref = _firestore.collection('customers').doc(docId);
    // Create-only: never overwrite an existing customer's data on a repeat
    // login. Returning users keep their onboarding/credit/qrId state.
    //
    // A stub doc may already exist because `updateLastLogin`/`updateFcmToken`
    // (triggered by the authStateChanges listener that fires the moment the
    // auth user is created) merge-write `lastLogin`/`fcmToken`/`appVersion`
    // before this method runs. Those writes never set `createdAt`, so we use
    // its presence — not mere document existence — to detect an already
    // provisioned customer.
    final existing = await ref.get();
    if (existing.exists && existing.data()?['createdAt'] != null) {
      return;
    }

    final user = AppUser(
      docId: docId,
      email: email,
      createdAt: TimeUtils.now(),
      qrId: generateQrId(docId),
      fcmToken: await _firebaseMessaging.getToken(),
      finishedOnboarding: false,
      disabled: false,
      emailVerified: false,
      lastLogin: TimeUtils.now(),
      creditAvailable: 0,
      scheduleOrder: global.defScheduleOrder ?? true,
      shareCredit: global.defShareCredit ?? true,
      withdrawBalance: global.defWithdrawBalance ?? true,
      coffixCreditAvailable: global.defCoffixCreditAvailable ?? true,
      getPurchaseInfoByMail: global.defGetPurchaseInfoByMail ?? true,
      getPromotions: global.defGetPromotions ?? true,
      allowWinACoffee: global.defAllowWinACoffee ?? true,
      allowWithdrawBalance: global.defWithdrawBalance ?? true,
      allowCoffeeForHome: global.defAllowCoffeeForHome ?? true,
      allowNotifications: global.defAllowNotifications ?? true,
    );

    // Merge so a concurrent lastLogin/fcmToken merge-write that may have created
    // a stub doc first is not clobbered, while the full profile is still written.
    await ref.set(user.toJson(), SetOptions(merge: true));
  }

  @override
  Stream<AppUser?> getUser() {
    return _firestore.collection('customers').doc(_auth.currentUser?.uid).snapshots().map((event) {
      return AppUser.fromJson({...event.data() ?? {}, "docId": _auth.currentUser?.uid});
    });
  }

  @override
  Future<void> sendEmailVerification({required String email}) async {
    try {
      await post('/otp/send', data: {'email': email});
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<void> verifyOtp({required String otp}) async {
    try {
      await post('/otp/verify', data: {'otp': otp});
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<void> updateLastLogin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('No user found');
    }
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    await _firestore.collection("customers").doc(_auth.currentUser?.uid).set({
      "lastLogin": TimeUtils.now(),
      "appVersion": appVersion,
    }, SetOptions(merge: true));
  }

  @override
  Future<bool> isUserDisabled({required UserCredential credential}) async {
    final user = await _firestore.collection("customers").doc(credential.user?.uid).get();
    return user.exists && user.data()?["disabled"] == true;
  }

  @override
  Future<void> deleteAccount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('No user found');
    }
    final response = await delete("/auth/account");
    if (response.statusCode != 200) {
      throw Exception('Failed to delete account');
    }
    await signOut();
  }

  @override
  Future<String> getFirebaseToken() async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('No token found');
    }
    return token;
  }

  @override
  Future<bool> customerHasAccount({required String email}) async {
    final response = await post('/auth/verify', data: {'email': email});
    return response.data["hasAccount"] as bool;
  }

  @override
  Future<List<String>> getProvidersForEmail({required String email}) async {
    final response = await post('/auth/verify', data: {'email': email});
    final providers = response.data["providers"] as List?;
    return providers?.cast<String>() ?? <String>[];
  }

  @override
  Future<String> sendPasswordResetEmail({required String email}) async {
    final response = await post('/auth/forgot-password', data: {'email': email});
    if (response.statusCode != 200) {
      throw Exception('Failed to send password reset email');
    }
    return response.message as String;
  }

  @override
  Future<void> updateFcmToken() async {
    final fcmToken = await _firebaseMessaging.getToken();

    if (fcmToken == null) {
      throw Exception('No FCM token found');
    }

    await _firestore.collection("customers").doc(_auth.currentUser?.uid).set({
      "fcmToken": fcmToken,
      "updatedAt": TimeUtils.now(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateUser({required String uid}) async {
    final user = _auth.currentUser;
    await _firestore.collection("customers").doc(uid).set({
      "docId": uid,
      "email": user?.email,
      "qrId": generateQrId(uid),
      "updatedAt": TimeUtils.now(),
      "createdAt": TimeUtils.now(),
    }, SetOptions(merge: true));
  }
}
