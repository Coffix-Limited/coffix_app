import 'package:coffix_app/core/extensions/order_extensions.dart';
import 'package:coffix_app/core/services/log_service.dart';
import 'package:coffix_app/core/utils/reorder.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/cart/presentation/pages/cart_page.dart';
import 'package:coffix_app/presentation/atoms/app_cached_network_image.dart';
import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/extensions/date_extensions.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/order/data/model/order.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/molecules/notifications/items_unavailable_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class OrderCard extends StatefulWidget {
  const OrderCard({super.key, required this.order});

  final Order order;

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _reordering = false;

  Future<void> _reorder() async {
    if (_reordering) return;

    final order = widget.order;
    final products = context.read<ProductCubit>().allProducts;

    if (products.isEmpty || order.items == null || order.items!.isEmpty) {
      AppNotification.error(context, 'Unable to reorder at this time');
      return;
    }

    final authState = context.read<AuthCubit>().state;
    final storeId = authState.maybeWhen(
      authenticated: (userWithStore) => userWithStore.user.preferredStoreId,
      orElse: () => null,
    );

    if (storeId == null || storeId.isEmpty) {
      AppNotification.error(
        context,
        'No store selected. Please select a store first.',
      );
      return;
    }

    final cartCubit = context.read<CartCubit>();

    setState(() => _reordering = true);

    ReorderResult result;
    try {
      result = await Reorder().fromOrder(
        order: order,
        storeId: storeId,
        catalog: products,
      );
    } finally {
      if (mounted) setState(() => _reordering = false);
    }

    if (!mounted) return;

    // Nothing survived — leave the existing cart untouched.
    if (result.isEmpty) {
      await ItemsUnavailableDialog.show(
        context,
        message:
            'The items in this order are no longer available at your selected store.',
      );
      return;
    }

    cartCubit.resetCart();

    for (final item in result.items) {
      try {
        cartCubit.addProduct(newItem: item);
      } catch (_) {
        continue;
      }
    }

    if (result.skippedItems > 0 || result.droppedModifiers > 0) {
      AppNotification.error(context, 'Some items are no longer available');
    }

    LogService().reOrder();
    context.goNamed(CartPage.route);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final theme = Theme.of(context);
    final date = order.createdAt;
    final dateStr = date != null ? date.formatDate() : '—';
    final items = order.items ?? [];

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
                child: Row(
                  children: [
                    Text(
                      '#${order.transactionNumber ?? 'N/A'}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(dateStr, style: theme.textTheme.bodySmall?.copyWith()),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final List<String> modifiers =
                        item.modifiers?.map((m) => m.name ?? "").toList() ?? [];
                    final imageUrl = item.productImageUrl ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppSizes.sm),
                              child: AppCachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.productName} x${item.quantity ?? 1}',
                                  style: AppTypography.bodyM600,
                                ),
                                if (modifiers.isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: modifiers
                                        .map(
                                          (m) => Text(
                                            m.toLarge(),
                                            style: AppTypography.body3XS
                                                .copyWith(
                                                  color:
                                                      AppColors.textBlackColor,
                                                ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text.rich(
                        order.amount?.toCurrencySuperscript(
                              style: AppTypography.titleS,
                            ) ??
                            0.00.toCurrencySuperscript(
                              style: AppTypography.titleS,
                            ),
                      ),
                    ],
                  ),
                  AppButton(
                    height: 24,
                    width: 48,
                    onPressed: _reorder,
                    disabled: _reordering,
                    label: "Reorder",
                    textStyle: AppTypography.body2XS.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // add store name
          Text(order.storeName ?? '—', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
