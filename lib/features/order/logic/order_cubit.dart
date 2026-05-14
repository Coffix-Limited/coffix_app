import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:coffix_app/data/repositories/order_repository.dart';
import 'package:coffix_app/features/order/data/model/order.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_state.dart';
part 'order_cubit.freezed.dart';

class OrderCubit extends Cubit<OrderState> {
  final OrderRepository _orderRepository;
  StreamSubscription<List<Order>>? _ordersSubscription;

  OrderCubit({required OrderRepository orderRepository})
    : _orderRepository = orderRepository,
      super(OrderState.initial());

  void getOrders() {
    _ordersSubscription?.cancel();
    emit(OrderState.loading());
    _ordersSubscription = _orderRepository.getOrders().listen(
      (orders) {
        if (!isClosed) emit(OrderState.loaded(orders: orders));
      },
      onError: (e) {
        if (!isClosed) emit(OrderState.error(message: e.toString()));
      },
    );
  }

  void updateOrderTime({
    required String orderId,
    required DateTime scheduledAt,
  }) async {
    // we are going to call this after the payment was successful
    // not on the webhook
    await _orderRepository.updateOrder(
      data: {"id": orderId, "scheduledAt": scheduledAt},
    );
  }

  Future<Order?> getOrderById(String orderId) {
    return _orderRepository.getOrderById(orderId);
  }

  void sendOrderToEmail({required String transactionNumber}) async {
    emit(OrderState.loading(orders: state.orders));
    try {
      await _orderRepository.sendOrderToEmail(transactionNumber: transactionNumber);
      emit(
        OrderState.emailSent(
          message: 'Order sent to email',
          orders: state.orders,
        ),
      );
    } catch (e) {
      emit(OrderState.error(message: e.toString(), orders: state.orders));
    }
  }

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    return super.close();
  }
}
