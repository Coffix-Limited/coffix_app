part of 'auth_cubit.dart';

@freezed
class AuthState with _$AuthState {
  // Initial state when app starts (checking auth status).
  const factory AuthState.initial() = _Initial;

  // Loading state (e.g., checking tokens, fetching user profile).
  const factory AuthState.loading() = _Loading;

  // User is authenticated but email is not verified
  const factory AuthState.emailNotVerified() = _EmailNotVerified;

  // User is authenticated and has completed onboarding
  const factory AuthState.authenticated({
    required AppUserWithStore userWithStore,
  }) = _Authenticated;

  // User has account
  const factory AuthState.hasAccount({required bool hasAccount}) = _HasAccount;

  // User is not authenticated (logged out or no valid tokens).
  const factory AuthState.unauthenticated() = _Unauthenticated;

  // OTP sent to email
  const factory AuthState.otpSent({required String email}) = _OtpSent;

  // Authentication failed with an error message.
  const factory AuthState.error({required String message}) = _Error;

  // Forgot password
  const factory AuthState.forgotPassword() = _ForgotPassword;

  // Password reset email sent
  const factory AuthState.passwordResetEmailSent({required String message}) = _PasswordResetEmailSent;
}
