import 'package:bloc/bloc.dart';
import 'package:coffix_app/data/repositories/profile_repository.dart';
import 'package:coffix_app/features/profile/domain/usecase/update_profile.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_state.dart';
part 'profile_cubit.freezed.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UpdateProfileUseCase _updateProfileUseCase;
  final ProfileRepository _profileRepository;

  ProfileCubit({
    required UpdateProfileUseCase updateProfileUseCase,
    required ProfileRepository profileRepository,
  }) : _updateProfileUseCase = updateProfileUseCase,
       _profileRepository = profileRepository,
       super(ProfileState.initial());

  void updateProfile({
    String? firstName,
    String? lastName,
    String? nickName,
    String? mobile,
    DateTime? birthday,
    String? suburb,
    String? city,
    String? preferredStoreId,
  }) async {
    emit(ProfileState.loading());
    try {
      await _updateProfileUseCase.call(
        UpdateProfileParams(
          firstName: firstName,
          lastName: lastName,
          nickName: nickName,
          mobile: mobile,
          birthday: birthday,
          suburb: suburb,
          city: city,
          preferredStoreId: preferredStoreId,
        ),
      );
      emit(ProfileState.success());
    } catch (e) {
      emit(ProfileState.error(message: e.toString()));
    }
  }

  void sendCoffeeOnUs({required List<Map<String, dynamic>> datas}) async {
    emit(ProfileState.loading());
    try {
      await _profileRepository.sendCoffeeOnUs(datas: datas);
      emit(ProfileState.success());
    } catch (e) {
      emit(ProfileState.error(message: e.toString()));
    }
  }
}
