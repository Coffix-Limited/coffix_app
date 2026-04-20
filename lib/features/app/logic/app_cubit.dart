import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:coffix_app/data/repositories/app_repository.dart';
import 'package:coffix_app/features/app/data/model/global.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'app_state.dart';
part 'app_cubit.freezed.dart';

class AppCubit extends Cubit<AppState> {
  final AppRepository _appRepository;
  StreamSubscription<AppGlobal>? _globalSubscription;

  AppCubit({required AppRepository appRepository})
    : _appRepository = appRepository,
      super(AppState.initial());

  Future<void> getGlobal() async {
    emit(const AppState.loading());

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      await _globalSubscription?.cancel();
      _globalSubscription = _appRepository.getGlobal().listen(
        (global) =>
            emit(AppState.loaded(global: global, appVersion: appVersion)),
        onError: (e) => emit(AppState.error(message: e.toString())),
      );
    } catch (e) {
      emit(AppState.error(message: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _globalSubscription?.cancel();
    return super.close();
  }
}
