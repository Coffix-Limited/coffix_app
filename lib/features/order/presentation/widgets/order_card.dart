import 'package:coffix_app/core/extensions/order_extensions.dart';
import 'package:coffix_app/core/utils/time_utils.dart';
import 'package:coffix_app/features/cart/data/model/cart_item.dart';
import 'package:coffix_app/features/cart/domain/helper.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/cart/presentation/pages/cart_page.dart';
import 'package:coffix_app/features/modifier/data/model/modifier.dart';
import 'package:coffix_app/presentation/atoms/app_cached_network_image.dart';
import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/extensions/date_extensions.dart';
import 'package:coffix_app/core/extensions/payment_method_extensions.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/order/data/model/order.dart';
import 'package:coffix_app/features/order/logic/order_cubit.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

  final Order order;

  void _reorder(BuildContext context, {required Order order}) {
    final productCubit = context.read<ProductCubit>();
    final products = productCubit.allProducts;

    if (products.isEmpty || order.items == null || order.items!.isEmpty) {
      AppNotification.error(context, 'Unable to reorder at this time');
      return;
    }

    // print(products.length);

    if (order.storeId == null) {
      AppNotification.error(context, 'Store information missing');
      return;
    }

    // 1. update the preferred store
    // context.read<StoreCubit>().updatePreferredStore(storeId: order.storeId!);

    final cartCubit = context.read<CartCubit>();

    // 2. reset the cart
    cartCubit.resetCart();

    final helper = CartHelper();
    int addedCount = 0;

    for (final Item item in order.items!) {
      if (item.productId == null) continue;

      final match = products.firstWhereOrNull(
        (p) => p.product.docId == item.productId,
      );

      if (match == null) {
        continue;
      }

      final product = match.product;
      // print(product.docId);
      final selectedByGroup = item.selectedModifiers ?? {};
      final modifierMap = <String, Modifier>{
        for (final im in item.modifiers ?? [])
          if (im.modifierId != null)
            im.modifierId!: Modifier(
              docId: im.modifierId,
              priceDelta: im.priceDelta,
            ),
      };
      // print(modifierMap);
      final modifierPriceSnapshot = helper.buildModifierPriceSnapshot(
        selectedByGroup: selectedByGroup,
        modifierMap: modifierMap,
      );
      print(modifierPriceSnapshot);
      final basePrice = product.price ?? 0;
      final unitTotal = helper.computeUnitTotal(
        basePrice: basePrice,
        modifierPriceSnapshot: modifierPriceSnapshot,
      );
      print(unitTotal);
      final quantity = item.quantity ?? 1;
      final id = helper.buildCartItemIdHashed(
        storeId: order.storeId!,
        productId: product.docId ?? '',
        selectedByGroup: selectedByGroup,
      );
      print(id);

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

      print(cartItem.toJson());

      try {
        cartCubit.addProduct(newItem: cartItem);
        addedCount++;
      } catch (e) {
        print("error: $e");
      }

      print("addedCount: $addedCount");
    }

    if (addedCount == 0) {
      AppNotification.error(context, 'Some items are no longer available');
      return;
    }

    context.goNamed(CartPage.route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = order.scheduledAt ?? order.createdAt;
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
              AppClickable(
                onPressed: () {
                  context.read<OrderCubit>().sendOrderToEmail(
                    orderId: order.docId ?? '',
                  );
                },
                child: Image.asset(AppImages.email, width: 24, height: 24),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.orderNumber?.substring(order.orderNumber!.length - 6) ?? '—'}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(dateStr, style: theme.textTheme.bodySmall?.copyWith()),
                    const SizedBox(height: AppSizes.sm),
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
                  Text(order.paymentMethod?.label ?? '—'),
                ],
              ),
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
                    final modifiers =
                        item.modifiers?.map((m) => m.modifierId).toList() ?? [];
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
                                  Text(
                                    modifiers.join(', ').toLarge(),
                                    style: AppTypography.body3XS.copyWith(
                                      color: AppColors.textBlackColor,
                                    ),
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
              AppButton(
                height: 24,
                width: 48,
                onPressed: () {
                  _reorder(context, order: order);
                },
                label: "Reorder",
                textStyle: AppTypography.body2XS.copyWith(
                  color: AppColors.white,
                ),
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
