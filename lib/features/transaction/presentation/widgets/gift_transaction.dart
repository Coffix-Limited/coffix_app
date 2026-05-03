import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/extensions/date_extensions.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/order/logic/order_cubit.dart';
import 'package:coffix_app/features/transaction/data/model/transaction.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:coffix_app/presentation/molecules/status_chip.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GiftTransaction extends StatefulWidget {
  const GiftTransaction({super.key, required this.transaction});

  final Transaction transaction;

  @override
  State<GiftTransaction> createState() => GiftTransactionState();
}

(String, Color) _transactionStatusStyle(TransactionStatus? s) {
  return switch (s) {
    TransactionStatus.paid => ('Paid', AppColors.success),
    TransactionStatus.created => ('Created', AppColors.primary),
    TransactionStatus.approved => ('Approved', AppColors.success),
    TransactionStatus.failed => ('Failed', AppColors.error),
    TransactionStatus.completed => ('Completed', AppColors.success),
    TransactionStatus.sent => ('Sent', AppColors.success),
    TransactionStatus.claimed => ('Claimed', AppColors.success),
    _ => ('—', AppColors.lightGrey),
  };
}

class GiftTransactionState extends State<GiftTransaction> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (statusLabel, statusColor) = _transactionStatusStyle(
      widget.transaction.status,
    );
    final order = context.watch<OrderCubit>().state.orders.firstWhereOrNull(
      (order) => order.docId == widget.transaction.orderId,
    );

    Color amountColor() {
      if (widget.transaction.status == TransactionStatus.sent) {
        return AppColors.error;
      } else if (widget.transaction.status == TransactionStatus.claimed) {
        return AppColors.success;
      }
      return AppColors.textBlackColor;
    }

    String label() {
      if (widget.transaction.status == TransactionStatus.sent) {
        return "Gift to: ${widget.transaction.recipientEmail ?? 'N/A'} (${widget.transaction.recipientEmail ?? 'N/A'})";
      } else if (widget.transaction.status == TransactionStatus.claimed) {
        return "Gift from: ${widget.transaction.senderFullName ?? 'N/A'} (${widget.transaction.senderEmail ?? 'N/A'})";
      }
      return "Gift from: ${widget.transaction.senderFullName ?? 'N/A'} (${widget.transaction.senderEmail ?? 'N/A'})";
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.md),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    AppClickable(
                      onPressed: () {
                        context.read<OrderCubit>().sendOrderToEmail(
                          transactionNumber:
                              widget.transaction.transactionNumber ?? '',
                        );
                      },
                      child: Image.asset(
                        AppImages.email,
                        width: 24,
                        height: 24,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      "#${widget.transaction.transactionNumber ?? 'N/A'}",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                  ],
                ),
              ),

              if (widget.transaction.createdAt != null)
                Text(
                  widget.transaction.createdAt?.formatDate() ?? '—',
                  style: AppTypography.body2XS.copyWith(
                    color: AppColors.textBlackColor,
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(label())],
                ),
              ),

              SizedBox(width: AppSizes.md),
              Column(
                children: [
                  Text.rich(
                    widget.transaction.amount?.toCurrencySuperscript(
                          style: AppTypography.titleS.copyWith(
                            color: amountColor(),
                          ),
                        ) ??
                        0.00.toCurrencySuperscript(style: AppTypography.titleS),
                  ),

                  Text("Coffix Credit"),
                  StatusChip(label: statusLabel, color: statusColor),
                ],
              ),
            ],
          ),
          Text(
            order?.storeName ?? '',
            style: AppTypography.body2XS.copyWith(
              color: AppColors.textBlackColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
