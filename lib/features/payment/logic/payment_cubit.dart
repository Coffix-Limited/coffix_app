import 'package:bloc/bloc.dart';
import 'package:coffix_app/data/repositories/payment_repository.dart';
import 'package:coffix_app/features/order/data/model/order.dart';
import 'package:coffix_app/features/payment/data/model/payment.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_state.dart';
part 'payment_cubit.freezed.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository _paymentRepository;
  PaymentCubit({required PaymentRepository paymentRepository})
    : _paymentRepository = paymentRepository,
      super(PaymentState.initial());

  void resetPayment() => emit(PaymentState.initial());

  void createPayment({required PaymentRequest request}) async {
    emit(PaymentState.loading());
    try {
      final response = await _paymentRepository.createPaymentSession(
        request: request,
      );
      if (request.paymentMethod == PaymentMethod.coffixCredit) {
        final order = Order.fromJson(response["order"]);
        emit(PaymentState.success(order: order));
      } else {
        emit(PaymentState.loaded(paymentUrl: response["paymentSessionUrl"]));
      }
    } catch (e) {
      emit(PaymentState.error(message: e.toString()));
    }
  }
}
