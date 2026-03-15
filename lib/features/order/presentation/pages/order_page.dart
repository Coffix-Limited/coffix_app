import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/extensions/date_extensions.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/cart/data/model/cart_item.dart';
import 'package:coffix_app/features/cart/domain/helper.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/cart/presentation/pages/cart_page.dart';
import 'package:coffix_app/features/order/data/model/order.dart';
import 'package:coffix_app/features/order/logic/order_cubit.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:coffix_app/presentation/molecules/empty_state.dart';
import 'package:coffix_app/presentation/molecules/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
              final filtered = orders
                  .where(
                    (o) => ![
                      OrderStatus.draft,
                      OrderStatus.pendingPayment,
                      OrderStatus.pending,
                    ].contains(o.status),
                  )
                  .toList();
              if (filtered.isEmpty) {
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
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSizes.sm),
                  itemBuilder: (context, index) {
                    return _OrderCard(order: filtered[index]);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  void _reorder(BuildContext context) {
    final productState = context.read<ProductCubit>().state;
    final products = productState.maybeWhen(
      loaded: (products, _, _) => products,
      orElse: () => null,
    );

    if (products == null || order.items == null || order.items!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to reorder at this time')),
      );
      return;
    }

    if (order.storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store information missing')),
      );
      return;
    }

    final cartCubit = context.read<CartCubit>();
    cartCubit.resetCart();

    final helper = CartHelper();

    for (final item in order.items!) {
      if (item.productId == null) continue;

      final match = products.firstWhere(
        (p) => p.product.docId == item.productId,
        orElse: () => products.first,
      );

      if (match.product.docId != item.productId) continue;

      final product = match.product;
      final selectedByGroup = item.selectedModifiers ?? {};
      final modifierPriceSnapshot = helper.buildModifierPriceSnapshot(
        selectedByGroup: selectedByGroup,
        modifierMap: {},
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
        createdAt: DateTime.now(),
      );

      try {
        cartCubit.addProduct(newItem: cartItem);
      } catch (_) {}
    }

    context.goNamed(CartPage.route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = order.scheduledAt ?? order.createdAt;
    final dateStr = date != null ? date.formatDate() : '—';
    final (statusLabel, statusColor) = _orderStatusStyle(order.status);
    final items = order.items ?? [];

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.md),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(AppImages.email, width: 24, height: 24),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderNumber?.substring(order.orderNumber!.length - 6) ?? '—'}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(dateStr, style: theme.textTheme.bodySmall?.copyWith()),
                    const SizedBox(height: AppSizes.sm),
                    // StatusChip(label: statusLabel, color: statusColor),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text.rich(
                    order.amount?.toCurrencySuperscript(
                          style: AppTypography.titleS,
                        ) ??
                        0.00.toCurrencySuperscript(style: AppTypography.titleS),
                  ),
                  Text(order.paymentMethod ?? '—'),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    if (items.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.md),
                      const SizedBox(height: AppSizes.md),
                      ...items.map((item) => _OrderItemRow(item: item)),
                    ],
                  ],
                ),
              ),
              AppButton(
                height: 24,
                width: 48,
                onPressed: () {
                  _reorder(context);
                },
                label: "Reorder",
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

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final productState = context.watch<ProductCubit>().state;
    final product = productState.maybeWhen(
      loaded: (products, _, _) => products
          .firstWhere(
            (p) => p.product.docId == item.productId,
            orElse: () => products.first,
          )
          .product,
      orElse: () => null,
    );

    final hasValidProduct = product?.docId == item.productId;
    final imageUrl = hasValidProduct ? (product?.imageUrl ?? '') : '';
    final name = hasValidProduct
        ? (product?.name ?? '—')
        : (item.productId ?? '—');
    final modifiers = item.selectedModifiers?.values.toList() ?? [];

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
                Text(
                  '$name x${item.quantity ?? 1}',
                  style: AppTypography.bodyM600,
                ),
                if (modifiers.isNotEmpty)
                  Text(
                    modifiers.join(', '),
                    style: AppTypography.body2XS.copyWith(
                      color: AppColors.lightGrey,
                    ),
                  ),
              ],
            ),
          ),
        ],
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
    (OrderStatus.paid, 'Paid', AppColors.success),
    (OrderStatus.completed, 'Completed', AppColors.success),
    (OrderStatus.cancelled, 'Cancelled', AppColors.error),
  ];
  if (status == null) return ('—', AppColors.lightGrey);
  for (final e in config) {
    if (e.$1 == status) return (e.$2, e.$3);
  }
  return ('—', AppColors.lightGrey);
}
