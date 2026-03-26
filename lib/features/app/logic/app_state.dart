part of 'app_cubit.dart';

@freezed
class AppState with _$AppState {
  const factory AppState.initial() = _Initial;
  const factory AppState.loading() = _Loading;
  const factory AppState.loaded({required AppGlobal global, required String appVersion}) = _Loaded;
  const factory AppState.error({required String message}) = _Error;
}
