import 'package:bloc/bloc.dart';
import 'package:coffix_app/data/repositories/payment_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'credit_state.dart';
part 'credit_cubit.freezed.dart';

class CreditCubit extends Cubit<CreditState> {
  final PaymentRepository _paymentRepository;

  CreditCubit({required PaymentRepository paymentRepository})
    : _paymentRepository = paymentRepository,
      super(CreditState.initial());

  void topup({required double amount}) async {
    emit(CreditState.loading(showTopUpField: state.showTopUpField));
    try {
      final url = await _paymentRepository.topupCredit(amount: amount);
      emit(CreditState.loaded(paymentSessionUrl: url));
    } catch (e) {
      emit(
        CreditState.error(
          message: e.toString(),
          showTopUpField: state.showTopUpField,
        ),
      );
    }
  }

  void showTopUpField(bool value) {
    state.when(
      initial: (_) => emit(CreditState.initial(showTopUpField: value)),
      loading: (_) => emit(CreditState.loading(showTopUpField: value)),
      loaded: (url, _) => emit(
        CreditState.loaded(paymentSessionUrl: url, showTopUpField: value),
      ),
      error: (msg, _) =>
          emit(CreditState.error(message: msg, showTopUpField: value)),
    );
  }
}
