part of 'otp_cubit.dart';

@freezed
class OtpState with _$OtpState {
  const factory OtpState.initial() = _Initial;

  // user called the api to send the otp
  const factory OtpState.sending() = _Sending;

  const factory OtpState.error({required String message}) = _Error;

  const factory OtpState.otpSent({required String email}) = _OtpSent;

  // user called the api to verify the otp
  const factory OtpState.verifying() = _Verifying;

  const factory OtpState.verified() = _Verified;
}
