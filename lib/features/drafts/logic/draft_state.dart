part of 'draft_cubit.dart';

@freezed
abstract class DraftState with _$DraftState {
  const factory DraftState.initial({@Default([]) List<Draft> drafts}) =
      _Initial;
  const factory DraftState.loading({@Default([]) List<Draft> drafts}) =
      _Loading;
  const factory DraftState.loaded({@Default([]) List<Draft> drafts}) = _Loaded;
  const factory DraftState.error({
    required String message,
    @Default([]) List<Draft> drafts,
  }) = _Error;
}
