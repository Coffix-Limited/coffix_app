import 'package:bloc/bloc.dart';
import 'package:coffix_app/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'otp_state.dart';
part 'otp_cubit.freezed.dart';

class OtpCubit extends Cubit<OtpState> {
  final AuthRepository _authRepository;
  OtpCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(OtpState.initial());

  Future<void> sendEmailVerification() async {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    emit(OtpState.sending());
    try {
      await _authRepository.sendEmailVerification(email: email);
      emit(OtpState.otpSent(email: email));
    } catch (e) {
      emit(OtpState.error(message: e.toString()));
    }
  }

  Future<void> verifyOtp({required String otp}) async {
    emit(OtpState.verifying());
    try {
      await _authRepository.verifyOtp(otp: otp);
      emit(OtpState.verified());
    } catch (e) {
      emit(OtpState.error(message: e.toString()));
    }
  }
}
