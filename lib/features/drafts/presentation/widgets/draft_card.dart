import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/services/log_service.dart';
import 'package:coffix_app/core/extensions/order_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/core/utils/reorder.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/cart/data/model/cart.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/cart/presentation/pages/cart_page.dart';
import 'package:coffix_app/features/drafts/data/model/draft.dart';
import 'package:coffix_app/features/drafts/logic/draft_cubit.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_cached_network_image.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/molecules/notifications/items_unavailable_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DraftCard extends StatefulWidget {
  const DraftCard({super.key, required this.draft});

  final Draft draft;

  @override
  State<DraftCard> createState() => _DraftCardState();
}

class _DraftCardState extends State<DraftCard> {
  bool _loading = false;

  Future<void> _loadDraftIntoCart(Cart cart) async {
    if (_loading) return;

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

    setState(() => _loading = true);

    ReorderResult result;
    try {
      result = await Reorder().fromCart(
        cart: cart,
        storeId: storeId,
        catalog: products,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    if (!mounted) return;

    // Nothing survived — leave the existing cart untouched.
    if (result.isEmpty) {
      await ItemsUnavailableDialog.show(
        context,
        message:
            'The items in this draft are no longer available at your selected store.',
      );
      return;
    }

    cartCubit.resetCart();

    for (final item in result.items) {
      try {
        cartCubit.addProduct(newItem: item);
      } catch (_) {}
    }

    if (result.skippedItems > 0 || result.droppedModifiers > 0) {
      AppNotification.error(context, 'Some items are no longer available');
    }

    context.goNamed(CartPage.route);
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    // final items = draft.carts.first.items ?? [];
    final Draft draft = widget.draft;
    final Cart cart = draft.cart ?? Cart();

    return BlocListener<DraftCubit, DraftState>(
      listener: (context, draftState) {
        if (draftState.maybeWhen(
          deleted: (drafts) => true,
          orElse: () => false,
        )) {
          AppNotification.show(context, 'Draft removed');
        }
      },
      child: Container(
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                        onPressed: () {
                          LogService().removeProductFromDraft();
                          context.read<DraftCubit>().deleteDraft(
                            draftId: draft.id ?? '',
                          );
                        },
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

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (imageUrl.isNotEmpty)
                                  AppCachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
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
                      onPressed: () => _loadDraftIntoCart(cart),
                      disabled: _loading,
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
      ),
    );
  }
}
