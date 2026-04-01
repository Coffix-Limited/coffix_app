import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/extensions/date_extensions.dart';
import 'package:coffix_app/core/extensions/order_extensions.dart';
import 'package:coffix_app/core/extensions/payment_method_extensions.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/modifier/logic/modifier_cubit.dart';
import 'package:coffix_app/features/order/data/model/order.dart';
import 'package:coffix_app/features/order/logic/order_cubit.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/features/stores/logic/store_cubit.dart';
import 'package:coffix_app/features/transaction/data/model/transaction.dart';
import 'package:coffix_app/features/transaction/logic/transaction_cubit.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:coffix_app/presentation/molecules/empty_state.dart';
import 'package:coffix_app/presentation/molecules/status_chip.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

(String, Color) _transactionStatusStyle(TransactionStatus? s) {
  return switch (s) {
    TransactionStatus.paid => ('Paid', AppColors.success),
    TransactionStatus.created => ('Created', AppColors.primary),
    TransactionStatus.approved => ('Approved', AppColors.success),
    TransactionStatus.failed => ('Failed', AppColors.error),
    _ => ('—', AppColors.lightGrey),
  };
}

class TransactionPage extends StatelessWidget {
  static String route = 'transaction_route';
  const TransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<TransactionCubit>()),
        BlocProvider.value(value: getIt<OrderCubit>()),
        BlocProvider.value(value: getIt<CartCubit>()),
        BlocProvider.value(value: getIt<ProductCubit>()),
        BlocProvider.value(value: getIt<StoreCubit>()),
      ],
      child: const TransactionView(),
    );
  }
}

class TransactionView extends StatefulWidget {
  const TransactionView({super.key});

  @override
  State<TransactionView> createState() => _TransactionViewState();
}

class _TransactionViewState extends State<TransactionView> {
  @override
  void initState() {
    super.initState();
    context.read<TransactionCubit>().getTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBackHeader(title: "My Transactions"),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: Text('Pull to load')),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (transactions) {
              if (transactions.isEmpty) {
                return EmptyState(
                  title: "No transactions yet",
                  subtitle: "Your transactions will appear here",
                  icon: Icons.receipt_long_outlined,
                );
              }
              return ListView.builder(
                padding: AppSizes.defaultPadding,
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: _TransactionCard(transaction: transactions[index]),
                  );
                },
              );
            },
            error: (message) => Center(
              child: Padding(
                padding: AppSizes.defaultPadding,
                child: Text(message, textAlign: TextAlign.center),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TransactionCard extends StatefulWidget {
  const _TransactionCard({required this.transaction});

  final Transaction transaction;

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (statusLabel, statusColor) = _transactionStatusStyle(
      widget.transaction.status,
    );
    final order = context.watch<OrderCubit>().state.orders.firstWhereOrNull(
      (order) => order.docId == widget.transaction.orderId,
    );
    // final modifiers = context.read<ModifierCubit>().state.when(
    //   initial: () => [],
    //   loading: () => [],
    //   loaded: (modifiers) => modifiers,
    //   error: (error) => [],
    // );

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.transaction.type == "topup"
                              ? "TopUp"
                              : "#${widget.transaction.orderNumber?.last6 ?? "N/A"}",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        StatusChip(label: statusLabel, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xs),
                    if (widget.transaction.createdAt != null)
                      Text(
                        widget.transaction.createdAt?.formatDate() ?? '—',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.lightGrey,
                        ),
                      ),
                    const SizedBox(height: AppSizes.sm),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text.rich(
                    widget.transaction.amount?.toCurrencySuperscript(
                          style: AppTypography.titleS,
                        ) ??
                        0.00.toCurrencySuperscript(style: AppTypography.titleS),
                  ),
                  if (widget.transaction.paymentMethod != null)
                    Text(
                      'via ${widget.transaction.paymentMethod?.label ?? '—'}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),

          if (order?.items != null && order!.items!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.sm),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items!.length,
              itemBuilder: (context, index) {
                final Item item = order.items![index];
                final imageUrl = item.productImageUrl ?? '';
                final List<ItemModifier> modifiers = item.modifiers ?? [];

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppSizes.sm),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Image.network(imageUrl, fit: BoxFit.cover),
                          ),
                        )
                      else
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.softGrey,
                            borderRadius: BorderRadius.circular(AppSizes.sm),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: AppTypography.bodyM600.copyWith(
                                        color: AppColors.textBlackColor,
                                      ),
                                      text:
                                          "${item.productName} (x${item.quantity}) ",
                                      children: [],
                                    ),
                                  ),
                                ),
                                Text.rich(
                                  item.price?.toCurrencySuperscript(
                                        style: AppTypography.body2XS.copyWith(
                                          color: AppColors.textBlackColor,
                                        ),
                                      ) ??
                                      0.00.toCurrencySuperscript(
                                        style: AppTypography.body2XS,
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
                                          entry.value.modifierId?.toLarge() ??
                                              '—',
                                          style: AppTypography.body3XS.copyWith(
                                            color: AppColors.textBlackColor,
                                          ),
                                        ),
                                      ),

                                      if (entry.value.priceDelta != null &&
                                          entry.value.priceDelta != 0) ...[
                                        const SizedBox(width: AppSizes.xs),
                                        Text.rich(
                                          entry.value.priceDelta!
                                              .toCurrencySuperscript(
                                                style: AppTypography.body3XS,
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
          ],
        ],
      ),
    );
  }
}
