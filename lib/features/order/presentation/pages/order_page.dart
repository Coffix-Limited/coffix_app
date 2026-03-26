import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/order/logic/order_cubit.dart';
import 'package:coffix_app/features/order/presentation/widgets/order_card.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:coffix_app/presentation/molecules/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderPage extends StatelessWidget {
  static String route = 'order_route';
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<OrderCubit>()),
        BlocProvider.value(value: getIt<CartCubit>()),
        BlocProvider.value(value: getIt<ProductCubit>()),
      ],
      child: const OrderView(),
    );
  }
}

class OrderView extends StatefulWidget {
  const OrderView({super.key});

  @override
  State<OrderView> createState() => _OrderViewState();
}

class _OrderViewState extends State<OrderView> {
  @override
  void initState() {
    super.initState();
    context.read<OrderCubit>().getOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBackHeader(title: 'My Orders'),
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          state.whenOrNull(
            emailSent: (_, message) => AppNotification.show(context, message),
            error: (_, message) => AppNotification.error(context, message),
          );
        },
        builder: (context, state) {
          final isLoading = state.maybeWhen(
            initial: (_) => true,
            loading: (_) => true,
            orElse: () => false,
          );

          if (isLoading) {
            return const Center(child: AppLoading());
          }

          final orders = state.orders;

          if (orders.isEmpty) {
            return Padding(
              padding: AppSizes.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: EmptyState(
                      title: 'No orders yet',
                      subtitle: 'Your orders will appear here',
                      icon: Icons.receipt_long_outlined,
                    ),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: ListView.separated(
              padding: AppSizes.defaultPadding,
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
              itemBuilder: (context, index) {
                return OrderCard(order: orders[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
