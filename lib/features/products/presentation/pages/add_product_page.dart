import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/cart/data/model/cart_item.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/cart/presentation/pages/cart_page.dart';
import 'package:coffix_app/features/products/data/model/product.dart';
import 'package:coffix_app/features/modifier/logic/modifier_cubit.dart';
import 'package:coffix_app/features/products/logic/product_modifier_cubit.dart';
import 'package:coffix_app/features/modifier/presentation/pages/customize_product_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_cached_network_image.dart';
import 'package:coffix_app/presentation/atoms/app_card.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:coffix_app/presentation/atoms/app_icon.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:coffix_app/presentation/organisms/app_layout_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AddProductPage extends StatelessWidget {
  static String route = 'add_product_route';
  const AddProductPage({
    super.key,
    required this.product,
    required this.storeId,
    this.cartItem,
  });

  final Product product;
  final String storeId;
  final CartItem? cartItem;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<CartCubit>()),
        BlocProvider.value(value: getIt<ProductModifierCubit>()),
        BlocProvider.value(value: getIt<ModifierCubit>()),
      ],
      child: AddProductView(
        product: product,
        storeId: storeId,
        cartItem: cartItem,
      ),
    );
  }
}

class AddProductView extends StatefulWidget {
  const AddProductView({
    super.key,
    required this.product,
    required this.storeId,
    this.cartItem,
  });

  final Product product;
  final String storeId;
  final CartItem? cartItem;
  @override
  State<AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> {
  late int quantity;

  @override
  void initState() {
    super.initState();
    quantity = widget.cartItem?.quantity ?? 1;
    context.read<ModifierCubit>().getModifiers(
      product: widget.product,
      storeId: widget.storeId,
    );
  }

  double calculateTotal() {
    final productModifierState = context.watch<ProductModifierCubit>().state;
    final unitPrice =
        (widget.product.price ?? 0) + productModifierState.totalPrice;
    return unitPrice * quantity;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productModifierState = context.watch<ProductModifierCubit>().state;
    final hasModifiers = widget.product.modifierGroupIds?.isNotEmpty ?? false;

    return BlocListener<ModifierCubit, ModifierState>(
      listenWhen: (prev, curr) =>
          !prev.maybeWhen(loaded: (_) => true, orElse: () => false) &&
          curr.maybeWhen(loaded: (_) => true, orElse: () => false),
      listener: (context, modState) {
        modState.maybeWhen(
          loaded: (modifiersGroups) {
            final allModifiers = modifiersGroups
                .expand((b) => b.modifiers)
                .toList();
            if (widget.cartItem != null) {
              context.read<ProductModifierCubit>().initFromCartItem(
                product: widget.product,
                allModifiers: allModifiers,
                selectedByGroup: widget.cartItem!.selectedByGroup,
              );
            } else {
              context.read<ProductModifierCubit>().initProductModifiers(
                product: widget.product,
                allModifiers: allModifiers,
              );
            }
          },
          orElse: () {},
        );
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBackHeader(title: "${widget.product.name}"),
        body: AppLayoutBody(
          child: Padding(
            padding: AppSizes.defaultPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                widget.product.imageUrl != null &&
                        widget.product.imageUrl!.isNotEmpty
                    ? ClipOval(
                        child: AppCachedNetworkImage(
                          imageUrl: widget.product.imageUrl!,
                          width: 300,
                          height: 300,
                          fit: BoxFit.fill,
                        ),
                      )
                    : Container(
                        color: AppColors.softGrey,
                        child: const Center(
                          child: Icon(
                            Icons.coffee_rounded,
                            size: 80,
                            color: AppColors.lightGrey,
                          ),
                        ),
                      ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSizes.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppClickable(
                          showSplash: false,
                          disabled: !hasModifiers,
                          onPressed: () {
                            context.pushNamed(
                              CustomizeProductPage.route,
                              extra: {
                                'product': widget.product,
                                'storeId': widget.storeId,
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(AppSizes.md),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.settings,
                                color: hasModifiers
                                    ? AppColors.primary
                                    : AppColors.lightGrey,
                                size: AppSizes.iconSizeLarge,
                              ),
                              const SizedBox(height: AppSizes.xs),
                              Text(
                                "Customise",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: hasModifiers
                                      ? null
                                      : AppColors.lightGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Quantity",
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.lightGrey,
                              ),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppClickable(
                                  disabled: quantity <= 1,
                                  onPressed: () {
                                    setState(() {
                                      quantity -= 1;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.sm,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(AppSizes.sm),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: quantity <= 1
                                            ? Colors.transparent
                                            : AppColors.borderColor,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.sm,
                                      ),
                                    ),
                                    child: AppIcon.withIconData(
                                      Icons.remove,
                                      size: AppSizes.iconSizeSmall,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ),
                                Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.md,
                                    vertical: AppSizes.sm,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "$quantity",
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                AppClickable(
                                  onPressed: () {
                                    setState(() {
                                      quantity += 1;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.sm,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(AppSizes.sm),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.borderColor,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.sm,
                                      ),
                                    ),
                                    child: AppIcon.withIconData(
                                      Icons.add,
                                      size: AppSizes.iconSizeSmall,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xxl),
                    // Wrap(
                    //   spacing: AppSizes.sm,
                    //   children: productModifierState.modifiers
                    //       .map((mod) => AppCard(child: Text(mod.label ?? '')))
                    //       .toList(),
                    // ),
                  ],
                ),
                Spacer(),
                Padding(
                  padding: AppSizes.defaultPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text.rich(
                        textAlign: TextAlign.center,
                        widget.product.price != null
                            ? calculateTotal().toCurrencySuperscript()
                            : 0.00.toCurrencySuperscript(),
                        style: AppTypography.bodyL.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppButton(
                        onPressed: () {
                          final modifierState = context
                              .read<ProductModifierCubit>()
                              .state;
                          final storeId = widget.storeId;
                          final newItem = CartItem.fromSelection(
                            product: widget.product,
                            quantity: quantity,
                            storeId: storeId,
                            modifiers: modifierState.modifiers,
                          );
                          if (widget.cartItem != null) {
                            final updated = widget.cartItem!.copyWith(
                              quantity: newItem.quantity,
                              selectedByGroup: newItem.selectedByGroup,
                              basePrice: newItem.basePrice,
                              modifierPriceSnapshot:
                                  newItem.modifierPriceSnapshot,
                              unitTotal: newItem.unitTotal,
                              lineTotal: newItem.lineTotal,
                            );
                            context.read<CartCubit>().updateProduct(
                              cartItemId: widget.cartItem!.id,
                              updatedItem: updated,
                            );
                          } else {
                            context.read<CartCubit>().addProduct(
                              newItem: newItem,
                            );
                          }
                          context.goNamed(CartPage.route);
                        },
                        label: widget.cartItem != null
                            ? "Update Order"
                            : "Add to Order",
                        prefixIcon: AppIcon.withIconData(
                          Icons.add,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
