part of 'credit_cubit.dart';

@freezed
abstract class CreditState with _$CreditState {
  const factory CreditState.initial({@Default(false) bool showTopUpField}) =
      _Initial;
  const factory CreditState.loading({@Default(false) bool showTopUpField}) =
      _Loading;
  const factory CreditState.loaded({
    required String paymentSessionUrl,
    @Default(false) bool showTopUpField,
  }) = _Loaded;
  const factory CreditState.error({
    required String message,
    @Default(false) bool showTopUpField,
  }) = _Error;
}
