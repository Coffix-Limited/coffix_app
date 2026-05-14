import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/features/order/data/model/order.dart';
import 'package:coffix_app/presentation/atoms/app_card.dart';
import 'package:coffix_app/presentation/molecules/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderActivityCard extends StatelessWidget {
  const OrderActivityCard({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    const orderStatusConfig = [
      (OrderStatus.draft, 'Draft', AppColors.lightGrey),
      (OrderStatus.pendingPayment, 'Pending', AppColors.lightGrey),
      (OrderStatus.confirmed, 'Confirmed', AppColors.primary),
      (OrderStatus.preparing, 'Preparing', AppColors.primary),
      (OrderStatus.ready, 'Ready', AppColors.success),
      (OrderStatus.completed, 'Completed', AppColors.success),
      (OrderStatus.cancelled, 'Cancelled', AppColors.error),
    ];

    (String, Color) orderStatusStyle(OrderStatus? status) {
      if (status == null) return ('—', AppColors.lightGrey);
      for (final e in orderStatusConfig) {
        if (e.$1 == status) return (e.$2, e.$3);
      }
      return ('—', AppColors.lightGrey);
    }

    final theme = Theme.of(context);
    final date = order.scheduledAt ?? order.createdAt;
    final dateStr = date != null
        ? DateFormat('MMM d, h:mm a').format(date)
        : '—';
    final (statusLabel, statusColor) = orderStatusStyle(order.status);

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order: ${order.transactionNumber ?? '—'}",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                StatusChip(label: statusLabel, color: statusColor),
                const SizedBox(height: AppSizes.xs),
                Text(
                  dateStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.lightGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${order.amount?.toStringAsFixed(2) ?? '0.00'}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
