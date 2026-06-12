import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:coffix_app/core/errors/auth_exceptions.dart';
import 'package:coffix_app/core/exceptions/auth_exceptions.dart';
import 'package:coffix_app/data/repositories/auth_repository.dart';
import 'package:coffix_app/data/repositories/store_repository.dart';
import 'package:coffix_app/features/auth/data/model/user_with_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

part 'auth_state.dart';
part 'auth_cubit.freezed.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final StoreRepository _storeRepository;
  StreamSubscription<AppUserWithStore?>? _userWithStoreSubscription;
  StreamSubscription<User?>? _userSubscription;

  AuthCubit({
    required AuthRepository authRepository,
    required StoreRepository storeRepository,
  }) : _authRepository = authRepository,
       _storeRepository = storeRepository,
       super(AuthState.initial());

  void listenToUser() {
    _userSubscription?.cancel();
    _userSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        getUserWithStore();
        _authRepository.updateFcmToken();
      } else {
        emit(AuthState.unauthenticated());
        _userWithStoreSubscription?.cancel();
      }
    });
  }

  /// Case 1 copy: the email is registered only via SSO. Routes the user to the
  /// provider they actually signed up with.
  String _ssoOnlyMessage(List<String> providers) {
    if (providers.contains('apple.com')) {
      return 'An account already exists with this email. Please continue '
          'with Apple, then add a password in your account settings.';
    }
    return 'An account already exists with this email. Please continue '
        'with Google, then add a password in your account settings.';
  }

  AuthExceptions _handleAuthException(FirebaseAuthException e) {
    debugPrint('auth exception code: ${e.stackTrace}');
    return AuthExceptions(
      message: getAuthExceptionMessage(e.code),
      code: e.code,
    );
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    emit(AuthState.loading());
    try {
      await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      emit(AuthState.error(message: e.toString()));
    }
  }

  Future<void> signOut() async {
    emit(AuthState.loading());
    try {
      await _authRepository.signOut();
      emit(AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error(message: e.toString()));
    }
  }

  Future<void> createAccountWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    emit(AuthState.loading());
    try {
      await _authRepository.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      emit(AuthState.error(message: e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthState.loading());
    try {
      await _authRepository.signInWithGoogle();
    } on UserCancelledSignIn {
      emit(AuthState.unauthenticated());
      return;
    } on AccountExistsWithDifferentCredential catch (e) {
      emit(AuthState.linkRequired(email: e.email, provider: e.provider));
      return;
    } on GoogleSignInException catch (e) {
      emit(AuthState.error(message: e.code.name));
    } catch (e) {
      emit(AuthState.error(message: e.toString()));
    }
  }

  Future<void> signInWithApple() async {
    emit(AuthState.loading());
    try {
      await _authRepository.signInWithApple();
    } on AccountExistsWithDifferentCredential catch (e) {
      emit(AuthState.linkRequired(email: e.email, provider: e.provider));
      return;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        emit(AuthState.initial());
        return;
      }
      final message = switch (e.code) {
        AuthorizationErrorCode.failed =>
          'Apple Sign In failed. Please try again.',
        AuthorizationErrorCode.invalidResponse =>
          'Apple Sign In returned an invalid response. Please try again.',
        AuthorizationErrorCode.notHandled =>
          'Apple Sign In could not be completed. Please try again.',
        AuthorizationErrorCode.notInteractive =>
          'Apple Sign In requires user interaction. Please try again.',
        _ => 'Apple Sign In failed. Please try again.',
      };
      emit(AuthState.error(message: message));
    } on UserCancelledSignIn catch (_) {
      emit(AuthState.unauthenticated());
      return;
    } catch (e) {
      emit(AuthState.error(message: e.toString()));
    }
  }

  /// Re-authenticates the existing email/password account and links the
  /// pending SSO credential to it, then loads the (unchanged) user.
  Future<void> linkAccountWithPassword({
    required String email,
    required String password,
  }) async {
    emit(AuthState.loading());
    try {
      await _authRepository.linkPendingCredentialWithPassword(
        email: email,
        password: password,
      );
      getUser();
    } on FirebaseAuthException catch (e) {
      emit(AuthState.error(message: _handleAuthException(e).message));
    } catch (e) {
      emit(AuthState.error(message: 'Something went wrong. Please try again.'));
    }
  }

  void updateLastLogin() async {
    await _authRepository.updateLastLogin();
  }

  void getUserWithStore() {
    updateLastLogin();
    final stream = _storeRepository.getUserWithStore();
    _userWithStoreSubscription?.cancel();
    _userWithStoreSubscription = stream.listen(
      (AppUserWithStore? user) {
        emit(AuthState.authenticated(userWithStore: user!));
      },
      onError: (error) {
        emit(AuthState.error(message: error.toString()));
      },
    );
  }

  Future<void> deleteAccount() async {
    emit(AuthState.loading());
    try {
      await _authRepository.deleteAccount();
      emit(AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error(message: e.toString()));
    } finally {
      emit(AuthState.initial());
    }
  }

  Future<void> getUser() async {
    final user = FirebaseAuth.instance;
    if (user.currentUser == null) {
      emit(AuthState.unauthenticated());
      return;
    } else {
      getUserWithStore();
    }
  }

  Future<void> createOrLoginAccount({
    required String email,
    required String password,
  }) async {
    emit(AuthState.loading());
    try {
      final providers = await _authRepository.getProvidersForEmail(
        email: email,
      );
      final hasAccount = providers.isNotEmpty;
      final hasPassword = providers.contains('password');

      // Case 1: the email exists but only via SSO (no password provider).
      // Don't attempt a password sign-in (it would fail) or a sign-up (it
      // would create a duplicate). Instruct the user to continue with SSO.
      if (hasAccount && !hasPassword) {
        emit(AuthState.error(message: _ssoOnlyMessage(providers)));
        return;
      }

      if (hasAccount) {
        await _authRepository.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await _authRepository.signUpWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      getUser();
    } on FirebaseAuthException catch (e) {
      emit(AuthState.error(message: _handleAuthException(e).message));
    } catch (e) {
      debugPrint('create or login account error: $e');
      emit(AuthState.error(message: 'Something went wrong. Please try again.'));
    }
  }

  void forgotPassword() {
    emit(AuthState.forgotPassword());
  }

  Future<void> forgotPasswordWithEmail({required String email}) async {
    emit(AuthState.loading());
    try {
      final message = await _authRepository.sendPasswordResetEmail(
        email: email,
      );
      emit(AuthState.passwordResetEmailSent(message: message));
    } catch (e) {
      emit(AuthState.error(message: e.toString()));
    }
  }

  void goToLogin() {
    emit(AuthState.unauthenticated());
  }
}
