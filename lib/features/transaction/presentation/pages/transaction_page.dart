import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/extensions/date_extensions.dart';
import 'package:coffix_app/core/extensions/order_extensions.dart';
import 'package:coffix_app/core/extensions/payment_method_extensions.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/core/utils/time_utils.dart';
import 'package:coffix_app/features/cart/data/model/cart_item.dart';
import 'package:coffix_app/features/cart/domain/helper.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/cart/presentation/pages/cart_page.dart';
import 'package:coffix_app/features/modifier/data/model/modifier.dart';
import 'package:coffix_app/features/order/logic/order_cubit.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/features/stores/logic/store_cubit.dart';
import 'package:coffix_app/features/transaction/data/model/transaction.dart';
import 'package:coffix_app/features/transaction/logic/transaction_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:coffix_app/presentation/molecules/empty_state.dart';
import 'package:coffix_app/presentation/molecules/status_chip.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final Transaction transaction;

  Future<void> _reorder(BuildContext context) async {
    final orderId = transaction.orderId;
    if (orderId == null || orderId.isEmpty) {
      AppNotification.error(context, 'No linked order for this transaction');
      return;
    }

    final order = await context.read<OrderCubit>().getOrderById(orderId);
    if (order == null) {
      if (context.mounted) {
        AppNotification.error(context, 'Order not found');
      }
      return;
    }

    if (!context.mounted) return;

    final productCubit = context.read<ProductCubit>();
    final products = productCubit.allProducts;

    if (products.isEmpty || order.items == null || order.items!.isEmpty) {
      AppNotification.error(context, 'Unable to reorder at this time');
      return;
    }

    if (order.storeId == null) {
      AppNotification.error(context, 'Store information missing');
      return;
    }
    context.read<StoreCubit>().updatePreferredStore(storeId: order.storeId!);

    final cartCubit = context.read<CartCubit>();
    cartCubit.resetCart();

    final helper = CartHelper();
    int addedCount = 0;

    for (final item in order.items!) {
      if (item.productId == null) continue;

      final match = products.firstWhereOrNull(
        (p) => p.product.docId == item.productId,
      );

      if (match == null) continue;

      final product = match.product;
      final selectedByGroup = item.selectedModifiers ?? {};
      final modifierMap = <String, Modifier>{
        for (final im in item.modifiers ?? [])
          if (im.modifierId != null)
            im.modifierId!: Modifier(
              docId: im.modifierId,
              priceDelta: im.priceDelta,
            ),
      };
      final modifierPriceSnapshot = helper.buildModifierPriceSnapshot(
        selectedByGroup: selectedByGroup,
        modifierMap: modifierMap,
      );
      final basePrice = product.price ?? 0;
      final unitTotal = helper.computeUnitTotal(
        basePrice: basePrice,
        modifierPriceSnapshot: modifierPriceSnapshot,
      );
      final quantity = item.quantity ?? 1;
      final id = helper.buildCartItemIdHashed(
        storeId: order.storeId!,
        productId: product.docId ?? '',
        selectedByGroup: selectedByGroup,
      );

      final cartItem = CartItem(
        id: id,
        storeId: order.storeId!,
        productId: product.docId ?? '',
        productName: product.name ?? '',
        productImageUrl: product.imageUrl ?? '',
        quantity: quantity,
        selectedByGroup: selectedByGroup,
        basePrice: basePrice,
        modifierPriceSnapshot: modifierPriceSnapshot,
        unitTotal: unitTotal,
        lineTotal: unitTotal * quantity,
        createdAt: TimeUtils.now(),
      );

      try {
        cartCubit.addProduct(newItem: cartItem);
        addedCount++;
      } catch (_) {}
    }

    if (!context.mounted) return;

    if (addedCount == 0) {
      AppNotification.error(context, 'Some items are no longer available');
      return;
    }

    context.goNamed(CartPage.route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (statusLabel, statusColor) = _transactionStatusStyle(
      transaction.status,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${transaction.orderNumber?.last6 ?? '—'}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    if (transaction.createdAt != null)
                      Text(
                        transaction.createdAt?.formatDate() ?? '—',
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
                    transaction.amount?.toCurrencySuperscript(
                          style: AppTypography.titleS,
                        ) ??
                        0.00.toCurrencySuperscript(style: AppTypography.titleS),
                  ),
                  Text(transaction.paymentMethod?.label ?? '—'),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    StatusChip(label: statusLabel, color: statusColor),
                    const SizedBox(width: AppSizes.sm),
                    if (transaction.paymentMethod != null)
                      Text(
                        'via ${transaction.paymentMethod?.label ?? '—'}',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (transaction.orderId != null)
                AppButton(
                  height: 24,
                  width: 56,
                  onPressed: () => _reorder(context),
                  label: 'Reorder',
                  textStyle: AppTypography.body2XS.copyWith(
                    color: AppColors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
