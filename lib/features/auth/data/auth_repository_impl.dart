import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffix_app/core/api/api_client.dart';
import 'package:coffix_app/core/api/model/endpoints.dart';
import 'package:coffix_app/core/errors/auth_exceptions.dart';
import 'package:coffix_app/core/utils/time_utils.dart';
import 'package:coffix_app/data/repositories/auth_repository.dart';
import 'package:coffix_app/domain/firestore_service.dart';
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

  AuthRepositoryImpl() : super(dio: Dio());

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final isDisabled = await isUserDisabled(credential: credential);
      if (isDisabled) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'user-disabled',
          message: 'User is disabled',
        );
      }
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
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await createUserDoc(
        docId: credential.user!.uid,
        email: credential.user!.email!,
      );
    } on FirebaseAuthException catch (e, st) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Email already in use');
      }
      debugPrint('signUp error: $e\n$st'); // see real error in console
      throw Exception(e.message);
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
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null) {
        throw Exception('Apple Sign In failed: No ID token');
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: idToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final credentialResult = await _auth.signInWithCredential(
        oauthCredential,
      );

      if (credentialResult.user != null) {
        final disabled = await isUserDisabled(credential: credentialResult);
        if (disabled) {
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'user-disabled',
            message: 'User is disabled',
          );
        }
        final email =
            credentialResult.user!.email ??
            appleCredential.email ??
            '${credentialResult.user!.uid}@privaterelay.appleid.com';
        await createUserDoc(docId: credentialResult.user!.uid, email: email);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
          'An account already exists with this email. '
          'Please sign in with your email and password first, then link your Apple account from settings.',
        );
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
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns SHA256 hash as a HEX string (this is what Firebase expects you to
  /// send to Apple as `nonce:`).
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString(); // hex
  }

  @override
  Future<void> signInWithFacebook() {
    // TODO: implement signInWithFacebook
    throw UnimplementedError();
  }

  @override
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize();
      final GoogleSignInAccount account = await _googleSignIn.authenticate(
        scopeHint: ["email"],
      );

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
          throw FirebaseAuthException(
            code: 'user-disabled',
            message: 'User is disabled',
          );
        }
        await createUserDoc(
          docId: credentialResult.user!.uid,
          email: credentialResult.user!.email!,
        );
        return credentialResult;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          throw Exception(
            'An account already exists with this email. '
            'Please sign in with your email and password first, then link your Google account from settings.',
          );
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
  Future<void> createUserDoc({
    required String docId,
    required String email,
  }) async {
    final ref = _firestore.collection('customers').doc(docId);
    final existing = await ref.get();
    if (!existing.exists) {
      await ref.set({
        'docId': docId,
        'email': email,
        'createdAt': TimeUtils.now(),
        'qrId': generateQrId(docId),
      }, SetOptions(merge: true));
    }
  }

  @override
  Stream<AppUser?> getUser() {
    return _firestore
        .collection('customers')
        .doc(_auth.currentUser?.uid)
        .snapshots()
        .map((event) {
          return AppUser.fromJson({
            ...event.data() ?? {},
            "docId": _auth.currentUser?.uid,
          });
        });
  }

  @override
  Future<void> sendEmailVerification({required String email}) async {
    final token = await _auth.currentUser?.getIdToken();
    log(token ?? '');
    if (token == null) {
      throw Exception('No token found');
    }
    final response = await http.post(
      Uri.parse('${ApiEndpoints.v1}/otp/send'),
      headers: {'Authorization': 'Bearer $token'},
      body: {'email': email},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send email verification');
    }
  }

  @override
  Future<void> verifyOtp({required String otp}) async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('No token found');
    }
    final response = await http.post(
      Uri.parse('${ApiEndpoints.v1}/otp/verify'),
      headers: {'Authorization': 'Bearer $token'},
      body: {'otp': otp},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to verify OTP');
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
    final user = await _firestore
        .collection("customers")
        .doc(credential.user?.uid)
        .get();
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
  Future<String> sendPasswordResetEmail({required String email}) async {
    final response = await post(
      '/auth/forgot-password',
      data: {'email': email},
    );
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
