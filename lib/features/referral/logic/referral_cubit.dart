import 'package:bloc/bloc.dart';
import 'package:coffix_app/core/api/model/api_exceptions.dart';
import 'package:coffix_app/data/repositories/referral_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'referral_state.dart';
part 'referral_cubit.freezed.dart';

class ReferralCubit extends Cubit<ReferralState> {
  final ReferralRepository _referralRepository;
  ReferralCubit({required ReferralRepository referralRepository})
    : _referralRepository = referralRepository,
      super(ReferralState.initial());

  void createReferral(List<Map<String, dynamic>> recipients) async {
    emit(ReferralState.loading());
    try {
      final message = await _referralRepository.createReferral(
        recipients: recipients,
      );
      emit(ReferralState.success(message: message));
    } on ApiExceptions catch (e) {
      emit(ReferralState.error(message: e.message));
    } catch (e) {
      emit(ReferralState.error(message: e.toString()));
    }
  }
}
