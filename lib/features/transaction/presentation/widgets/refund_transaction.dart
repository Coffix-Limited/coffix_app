import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/services/log_service.dart';
import 'package:coffix_app/core/extensions/date_extensions.dart';
import 'package:coffix_app/core/extensions/payment_method_extensions.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/order/logic/order_cubit.dart';
import 'package:coffix_app/features/payment/data/model/payment.dart';
import 'package:coffix_app/features/transaction/data/model/transaction.dart';
import 'package:coffix_app/features/transaction/logic/transaction_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:coffix_app/presentation/molecules/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RefundTransaction extends StatefulWidget {
  const RefundTransaction({super.key, required this.transaction});

  final Transaction transaction;

  @override
  State<RefundTransaction> createState() => RefundTransactionState();
}

class RefundTransactionState extends State<RefundTransaction> {
  @override
  void initState() {
    super.initState();
    final originalNum = widget.transaction.originalTransactionNumber;
    if (originalNum != null) {
      context.read<TransactionCubit>().fetchOriginalTransaction(originalNum);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    if (widget.transaction.isManual != true)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSizes.sm),
                        child: AppClickable(
                          onPressed: () {
                            LogService().emailTransaction(
                              transactionNumber:
                                  widget.transaction.transactionNumber ?? '',
                            );
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
                      ),
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
                child: widget.transaction.isManual == true
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Manual transaction:"),
                          Text(widget.transaction.notes ?? ''),
                        ],
                      )
                    : Text(
                        "Order #${widget.transaction.originalTransactionNumber ?? 'N/A'} has been credited",
                      ),
              ),
              SizedBox(width: AppSizes.md),
              Column(
                children: [
                  Text.rich(
                    widget.transaction.amount?.toCurrencySuperscript(
                          style: AppTypography.titleS.copyWith(
                            color:
                                widget.transaction.paymentMethod ==
                                    PaymentMethod.cash
                                ? AppColors.textBlackColor
                                : AppColors.success,
                          ),
                        ) ??
                        0.00.toCurrencySuperscript(
                          style: AppTypography.titleS.copyWith(),
                        ),
                  ),
                  Text(widget.transaction.paymentMethod?.label ?? ''),
                  StatusChip(label: "Refunded", color: AppColors.success),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
