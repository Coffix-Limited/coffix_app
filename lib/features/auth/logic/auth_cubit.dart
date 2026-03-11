import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:coffix_app/core/errors/auth_exceptions.dart';
import 'package:coffix_app/core/exceptions/auth_exceptions.dart';
import 'package:coffix_app/data/repositories/auth_repository.dart';
import 'package:coffix_app/data/repositories/store_repository.dart';
import 'package:coffix_app/features/auth/data/model/user_with_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        if (user.emailVerified == false) {
          emit(AuthState.emailNotVerified());
        }
      }
    });
  }

  AuthExceptions _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-disabled':
        throw AuthExceptions(message: "User is disabled", code: e.code);
      case 'invalid-credential':
        throw AuthExceptions(message: "Invalid credential", code: e.code);
      case 'invalid-email':
        throw AuthExceptions(message: "Invalid email", code: e.code);
      case 'invalid-password':
        throw AuthExceptions(message: "Invalid password", code: e.code);
    }
    return AuthExceptions(
      message: e.message ?? "Unknown error",
      code: e.code ?? "unknown",
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
      emit(AuthState.initial());
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
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        emit(AuthState.initial());
        return;
      }
      emit(AuthState.error(message: e.toString()));
    } on UserCancelledSignIn catch (_) {
      emit(AuthState.initial());
      return;
    } catch (e) {
      emit(AuthState.error(message: e.toString()));
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
        print("user: ${user?.user.emailVerified}");
        if (user?.user.emailVerified == false) {
          emit(AuthState.emailNotVerified());
          return;
        }
        // emit(
        //   user != null
        //       ? AuthState.authenticated(userWithStore: user)
        //       : AuthState.unauthenticated(),
        // );
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
      final hasAccount = await _authRepository.customerHasAccount(email: email);
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
      // getUserWithStore();
    } catch (e) {
      emit(AuthState.error(message: e.toString()));
    }
  }
}
