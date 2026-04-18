import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/extensions/date_extensions.dart';
import 'package:coffix_app/core/extensions/payment_method_extensions.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/order/logic/order_cubit.dart';
import 'package:coffix_app/features/transaction/data/model/transaction.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:coffix_app/presentation/molecules/status_chip.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TopUpTransaction extends StatefulWidget {
  const TopUpTransaction({super.key, required this.transaction});

  final Transaction transaction;

  @override
  State<TopUpTransaction> createState() => TopUpTransactionState();
}

(String, Color) _transactionStatusStyle(TransactionStatus? s) {
  return switch (s) {
    TransactionStatus.paid => ('Paid', AppColors.success),
    TransactionStatus.created => ('Created', AppColors.primary),
    TransactionStatus.approved => ('Approved', AppColors.success),
    TransactionStatus.failed => ('Failed', AppColors.error),
    TransactionStatus.completed => ('Completed', AppColors.success),
    _ => ('—', AppColors.lightGrey),
  };
}

class TopUpTransactionState extends State<TopUpTransaction> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (statusLabel, statusColor) = _transactionStatusStyle(
      widget.transaction.status,
    );
    final order = context.watch<OrderCubit>().state.orders.firstWhereOrNull(
      (order) => order.docId == widget.transaction.orderId,
    );
    final bonus = widget.transaction.totalAmount == null
        ? 0.0
        : (widget.transaction.totalAmount ?? 0.0) -
              (widget.transaction.amount ?? 0.0);

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
                  children: [
                    Text(
                      widget.transaction.status == TransactionStatus.failed
                          ? "We canceled order ${widget.transaction.transactionNumber}"
                          : "You paid",
                      style: AppTypography.body2XS.copyWith(
                        color: AppColors.textBlackColor,
                      ),
                    ),
                    Text.rich(
                      widget.transaction.amount?.toCurrencySuperscript(
                            style: AppTypography.titleS.copyWith(
                              color:
                                  widget.transaction.status ==
                                      TransactionStatus.failed
                                  ? AppColors.error
                                  : AppColors.textBlackColor,
                            ),
                          ) ??
                          0.00.toCurrencySuperscript(
                            style: AppTypography.titleS.copyWith(
                              color:
                                  widget.transaction.status ==
                                      TransactionStatus.failed
                                  ? AppColors.error
                                  : AppColors.textBlackColor,
                            ),
                          ),
                    ),
                    Text(widget.transaction.paymentMethod?.label ?? ''),
                  ],
                ),
              ),
              SizedBox(width: AppSizes.md),
              if (widget.transaction.status != TransactionStatus.failed)
                Text(
                  "${widget.transaction.amount?.toCurrency() ?? "N/A"} + ${bonus.toCurrency()} bonus",
                  style: AppTypography.body2XS.copyWith(
                    color: AppColors.textBlackColor,
                  ),
                ),
              SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "You received",
                      style: AppTypography.body2XS.copyWith(
                        color: AppColors.textBlackColor,
                      ),
                    ),
                    Text.rich(
                      widget.transaction.amount?.toCurrencySuperscript(
                            style: AppTypography.titleS.copyWith(
                              color: AppColors.success,
                            ),
                          ) ??
                          0.00.toCurrencySuperscript(
                            style: AppTypography.titleS.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                    ),
                    Text(widget.transaction.paymentMethod?.label ?? ''),
                  ],
                ),
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
