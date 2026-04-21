import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/extensions/order_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/core/utils/time_utils.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/cart/data/model/cart.dart';
import 'package:coffix_app/features/cart/data/model/cart_item.dart';
import 'package:coffix_app/features/cart/domain/helper.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/cart/presentation/pages/cart_page.dart';
import 'package:coffix_app/features/drafts/data/model/draft.dart';
import 'package:coffix_app/features/drafts/logic/draft_cubit.dart';
import 'package:coffix_app/features/modifier/data/model/modifier.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_cached_network_image.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DraftCard extends StatelessWidget {
  const DraftCard({super.key, required this.draft});

  final Draft draft;

  void _loadDraftIntoCart(BuildContext context, Cart cart) {
    final authState = context.read<AuthCubit>().state;
    final storeId = authState.maybeWhen(
      authenticated: (u) => u.user.preferredStoreId,
      orElse: () => null,
    );

    if (storeId == null || storeId.isEmpty) {
      AppNotification.error(
        context,
        'No store selected. Please select a store first.',
      );
      return;
    }

    final products = context.read<ProductCubit>().allProducts;
    final cartCubit = context.read<CartCubit>();
    final helper = CartHelper();
    int addedCount = 0;

    cartCubit.resetCart();

    for (final item in cart.items ?? []) {
      if (item.productId == null) continue;

      final match = products.firstWhereOrNull(
        (p) => p.product.docId == item.productId,
      );
      if (match == null) continue;

      final product = match.product;

      final disabledStores = product.disabledStores;
      final availableStores = product.availableToStores;
      if (disabledStores != null && disabledStores.contains(storeId)) continue;
      if (availableStores != null && !availableStores.contains(storeId)) continue;

      final modifierMap = <String, Modifier>{
        for (final entry in item.modifierPriceSnapshot.entries)
          entry.key: Modifier(docId: entry.key, priceDelta: entry.value),
      };
      final selectedByGroup = item.selectedByGroup;
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
        storeId: storeId,
        productId: product.docId ?? '',
        selectedByGroup: selectedByGroup,
      );

      final cartItem = CartItem(
        id: id,
        storeId: storeId,
        productId: product.docId ?? '',
        productName: product.name ?? '',
        productImageUrl: product.imageUrl ?? '',
        quantity: quantity,
        selectedByGroup: selectedByGroup,
        basePrice: basePrice,
        modifierPriceSnapshot: modifierPriceSnapshot,
        modifierLabelSnapshot: item.modifierLabelSnapshot,
        unitTotal: unitTotal,
        lineTotal: unitTotal * quantity,
        createdAt: TimeUtils.now(),
      );

      try {
        cartCubit.addProduct(newItem: cartItem);
        addedCount++;
      } catch (_) {}
    }

    if (addedCount == 0) {
      AppNotification.error(context, 'Some items are no longer available');
      return;
    }

    context.goNamed(CartPage.route);
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    // final items = draft.carts.first.items ?? [];
    final Cart cart = draft.cart ?? Cart();

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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      icon: CircleAvatar(
                        radius: AppSizes.iconSizeXxs,
                        backgroundColor: AppColors.error,
                        child: const Icon(
                          Icons.close,
                          size: AppSizes.iconSizeSmall,
                          color: AppColors.white,
                        ),
                      ),
                      onPressed: () => context.read<DraftCubit>().deleteDraft(
                        draftId: draft.id ?? '',
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: cart.items?.length ?? 0,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final item = cart.items?[index];
                          final imageUrl = item?.productImageUrl ?? '';
                          final modifierEntries =
                              item?.modifierPriceSnapshot.entries.toList() ??
                              [];

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
                                                    "${item?.productName} (x${item?.quantity}) ",
                                                children: [],
                                              ),
                                            ),
                                          ),
                                          // Text.rich(
                                          //   item?.lineTotal
                                          //           .toCurrencySuperscript(
                                          //             style: AppTypography
                                          //                 .body2XS
                                          //                 .copyWith(
                                          //                   color: AppColors
                                          //                       .textBlackColor,
                                          //                 ),
                                          //           ) ??
                                          //       0.00.toCurrencySuperscript(
                                          //         style: AppTypography.body2XS,
                                          //       ),
                                          // ),
                                        ],
                                      ),
                                      if (modifierEntries.isNotEmpty) ...[
                                        const SizedBox(height: AppSizes.xs),

                                        Column(
                                          children: modifierEntries.map((
                                            entry,
                                          ) {
                                            final label =
                                                item?.modifierLabelSnapshot[entry
                                                    .key] ??
                                                entry.key;
                                            return Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    label.toLarge(),
                                                    style: AppTypography.body3XS
                                                        .copyWith(
                                                          color: AppColors
                                                              .textBlackColor,
                                                        ),
                                                  ),
                                                ),
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
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSizes.md),
              Column(
                children: [
                  AppButton(
                    height: 24,
                    width: 56,
                    onPressed: () =>
                        _loadDraftIntoCart(context, draft.cart ?? Cart()),
                    label: 'Order',
                    textStyle: AppTypography.body2XS.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
