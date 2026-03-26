import 'package:bloc/bloc.dart';
import 'package:coffix_app/data/repositories/app_repository.dart';
import 'package:coffix_app/features/app/data/model/global.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'app_state.dart';
part 'app_cubit.freezed.dart';

class AppCubit extends Cubit<AppState> {
  final AppRepository _appRepository;
  AppCubit({required AppRepository appRepository})
    : _appRepository = appRepository,
      super(AppState.initial());

  Future<void> getGlobal() async {
    emit(const AppState.loading());

    try {
      final results = await Future.wait([
        _appRepository.getGlobal(),
        PackageInfo.fromPlatform(),
      ]);

      final global = results[0] as AppGlobal;
      final packageInfo = results[1] as PackageInfo;

      final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      emit(AppState.loaded(global: global, appVersion: appVersion));
    } catch (e) {
      emit(AppState.error(message: e.toString()));
    }
  }
}
