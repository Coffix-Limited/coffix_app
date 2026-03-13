import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/features/order/data/model/order.dart';
import 'package:coffix_app/features/order/logic/order_cubit.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:coffix_app/presentation/molecules/empty_state.dart';
import 'package:coffix_app/presentation/molecules/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class OrderPage extends StatelessWidget {
  static String route = 'order_route';
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<OrderCubit>(),
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const AppBackHeader(title: 'Orders'),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (msg) => Center(
              child: Padding(
                padding: AppSizes.defaultPadding,
                child: Text(msg, textAlign: TextAlign.center),
              ),
            ),
            loaded: (orders) {
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
                child: Padding(
                  padding: AppSizes.defaultPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppBackHeader(title: 'Orders'),
                      const SizedBox(height: AppSizes.lg),
                      Expanded(
                        child: ListView.separated(
                          itemCount: orders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSizes.sm),
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            final date = order.scheduledAt ?? order.createdAt;
                            final dateStr = date != null
                                ? DateFormat(
                                    'MMM d, yyyy · h:mm a',
                                  ).format(date)
                                : '—';
                            final (statusLabel, statusColor) =
                                _orderStatusStyle(order.orderStatus);

                            return Container(
                              padding: const EdgeInsets.all(AppSizes.md),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.md,
                                ),
                                border: Border.all(
                                  color: AppColors.borderColor,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Order ${order.orderNumber ?? '—'}',
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: AppSizes.xs),
                                            Text(
                                              dateStr,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: AppColors.lightGrey,
                                                  ),
                                            ),
                                            const SizedBox(height: AppSizes.sm),
                                            StatusChip(
                                              label: statusLabel,
                                              color: statusColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '\$${order.total?.toStringAsFixed(2) ?? '0.00'}',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

(String, Color) _orderStatusStyle(OrderStatus? status) {
  const config = [
    (OrderStatus.draft, 'Draft', AppColors.lightGrey),
    (OrderStatus.pendingPayment, 'Pending', AppColors.lightGrey),
    (OrderStatus.confirmed, 'Confirmed', AppColors.primary),
    (OrderStatus.preparing, 'Preparing', AppColors.primary),
    (OrderStatus.ready, 'Ready', AppColors.success),
    (OrderStatus.completed, 'Completed', AppColors.success),
    (OrderStatus.cancelled, 'Cancelled', AppColors.error),
  ];
  if (status == null) return ('—', AppColors.lightGrey);
  for (final e in config) {
    if (e.$1 == status) return (e.$2, e.$3);
  }
  return ('—', AppColors.lightGrey);
}
