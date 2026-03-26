import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/features/order/data/model/order.dart';
import 'package:coffix_app/features/order/presentation/widgets/order_activity_card.dart';
import 'package:flutter/material.dart';

class OrderActivity extends StatelessWidget {
  const OrderActivity({super.key, required this.orders, this.maxItems = 3});

  final List<Order> orders;
  final int maxItems;

  static List<Order> _filterNeeded(List<Order> orders, int max) {
    return orders
        .where((o) => o.status != OrderStatus.cancelled)
        .take(max)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final needed = _filterNeeded(orders, maxItems);
    if (needed.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Order activity',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: needed.length > maxItems ? maxItems : needed.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
          itemBuilder: (context, index) =>
              OrderActivityCard(order: needed[index]),
        ),
      ],
    );
  }
}
