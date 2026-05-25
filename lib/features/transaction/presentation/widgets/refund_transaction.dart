import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/services/log_service.dart';
import 'package:coffix_app/core/extensions/date_extensions.dart';
import 'package:coffix_app/core/extensions/payment_method_extensions.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/order/data/model/order.dart';
import 'package:coffix_app/features/order/logic/order_cubit.dart';
import 'package:coffix_app/features/transaction/data/model/transaction.dart';
import 'package:coffix_app/features/transaction/logic/transaction_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:coffix_app/presentation/molecules/status_chip.dart';
import 'package:collection/collection.dart';
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

    final originalNum = widget.transaction.originalTransactionNumber;
    final originalTxn = context.watch<TransactionCubit>().state.whenOrNull(
      loaded: (_, originals) =>
          originalNum != null ? originals[originalNum] : null,
    );
    final resolvedOrderId = originalTxn?.orderId ?? widget.transaction.orderId;
    final order = context.watch<OrderCubit>().state.orders.firstWhereOrNull(
      (order) => order.docId == resolvedOrderId,
    );

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
              order?.items != null && order!.items!.isNotEmpty
                  ? Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: order.items!.length,
                        itemBuilder: (context, index) {
                          final Item item = order.items![index];
                          final imageUrl = item.productImageUrl ?? '';
                          final List<ItemModifier> modifiers =
                              item.modifiers ?? [];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSizes.sm),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (imageUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.sm,
                                    ),
                                    child: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.softGrey,
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.sm,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.coffee,
                                      color: AppColors.lightGrey,
                                      size: AppSizes.iconSizeSmall,
                                    ),
                                  ),
                                const SizedBox(width: AppSizes.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                style: AppTypography.bodyM600
                                                    .copyWith(
                                                      color: AppColors
                                                          .textBlackColor,
                                                    ),
                                                text:
                                                    "${item.productName} (x${item.quantity}) ",
                                                children: [],
                                              ),
                                            ),
                                          ),
                                          Text.rich(
                                            item.basePrice
                                                    ?.toCurrencySuperscript(
                                                      style: AppTypography
                                                          .body2XS
                                                          .copyWith(
                                                            color: AppColors
                                                                .textBlackColor,
                                                          ),
                                                    ) ??
                                                0.00.toCurrencySuperscript(
                                                  style: AppTypography.body2XS
                                                      .copyWith(
                                                        color: AppColors
                                                            .textBlackColor,
                                                      ),
                                                ),
                                          ),
                                        ],
                                      ),
                                      if (modifiers.isNotEmpty) ...[
                                        const SizedBox(height: AppSizes.xs),

                                        Column(
                                          children: modifiers.asMap().entries.map((
                                            entry,
                                          ) {
                                            return Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    entry.value.name ?? '—',
                                                    style: AppTypography.body3XS
                                                        .copyWith(
                                                          color: AppColors
                                                              .textBlackColor,
                                                        ),
                                                  ),
                                                ),

                                                if (entry.value.priceDelta !=
                                                        null &&
                                                    entry.value.priceDelta !=
                                                        0) ...[
                                                  const SizedBox(
                                                    width: AppSizes.xs,
                                                  ),
                                                  Text.rich(
                                                    entry.value.priceDelta!
                                                        .toCurrencySuperscript(
                                                          style: AppTypography
                                                              .body3XS,
                                                        ),
                                                  ),
                                                ],
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : const Expanded(child: Text('No items')),

              SizedBox(width: AppSizes.md),
              Column(
                children: [
                  Text.rich(
                    widget.transaction.amount?.toCurrencySuperscript(
                          style: AppTypography.titleS.copyWith(
                            color: AppColors.success,
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
