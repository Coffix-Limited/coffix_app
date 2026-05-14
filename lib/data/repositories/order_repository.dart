import 'package:coffix_app/features/order/data/model/order.dart';

abstract class OrderRepository {
  Stream<List<Order>> getOrders();
  Future<Order?> getOrderById(String orderId);
  Future<void> updateOrder({required Map<String, dynamic> data});
  Future<void> sendOrderToEmail({required String transactionNumber});
}
