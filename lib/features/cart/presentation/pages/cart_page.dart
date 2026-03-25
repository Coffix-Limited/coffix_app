import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/cart/data/model/cart_item.dart';
import 'package:coffix_app/features/cart/logic/cart_cubit.dart';
import 'package:coffix_app/features/drafts/logic/draft_cubit.dart';
import 'package:coffix_app/features/drafts/presentation/pages/drafts_page.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:coffix_app/features/menu/presentation/pages/menu_page.dart';
import 'package:coffix_app/features/order/logic/order_cubit.dart';
import 'package:coffix_app/features/order/presentation/pages/schedule_order_page.dart';
import 'package:coffix_app/features/order/presentation/widgets/order_activity.dart';
import 'package:coffix_app/features/order/presentation/widgets/order_item.dart';
import 'package:coffix_app/features/products/data/model/product.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/features/products/presentation/pages/add_product_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:coffix_app/presentation/molecules/empty_state.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CartPage extends StatelessWidget {
  static String route = 'cart_route';
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<CartCubit>()),
        BlocProvider.value(value: getIt<OrderCubit>()),
        BlocProvider.value(value: getIt<DraftCubit>()),
      ],
      child: const CartView(),
    );
  }
}

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (user) => user.store,
      orElse: () => null,
    );
    final storeIsOpen = store?.isOpenAt() ?? false;

    return Scaffold(
      appBar: AppBackHeader(
        title: "My Order",
        onBack: () {
          context.goNamed(HomePage.route);
        },
        showAddButton: true,
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: state.cart?.items.isEmpty ?? true
                    ? Padding(
                        padding: AppSizes.defaultPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                EmptyState(
                                  title: 'No items in order',
                                  subtitle:
                                      'Add items from the menu to get started',
                                  icon: Icons.shopping_cart_outlined,
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.only(
                          left: AppSizes.defaultPadding.start,
                          right: AppSizes.defaultPadding.end,
                          bottom: AppSizes.defaultPadding.bottom + 100,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final CartItem? cartItem =
                                    state.cart?.items[index];
                                if (cartItem == null)
                                  return const SizedBox.shrink();
                                final Product? selectedProduct = context
                                    .watch<ProductCubit>()
                                    .state
                                    .maybeWhen(
                                      loaded: (products, _, _) => products
                                          .firstWhereOrNull(
                                            (p) =>
                                                p.product.docId ==
                                                cartItem.productId,
                                          )
                                          ?.product,
                                      orElse: () => null,
                                    );
                                return OrderItemRow(
                                  cartItem: cartItem,
                                  price: cartItem.unitTotal,
                                  basePrice: cartItem.basePrice,
                                  onRemove: () {
                                    context.read<CartCubit>().removeProduct(
                                      cartItemId: cartItem.id,
                                    );
                                  },
                                  onEdit: () {
                                    if (selectedProduct == null) return;
                                    context.pushNamed(
                                      AddProductPage.route,
                                      extra: {
                                        'cartItem': cartItem,
                                        'storeId': state.cart?.storeId,
                                        'product': selectedProduct,
                                      },
                                    );
                                  },
                                );
                              },
                              separatorBuilder: (_, _) => const Divider(),
                              itemCount: state.cart?.items.length ?? 0,
                            ),
                          ],
                        ),
                      ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: AppSizes.defaultPadding,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(color: AppColors.borderColor),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: theme.textTheme.titleMedium),
                          Text.rich(
                            (state.cart?.items.fold(
                                      0.0,
                                      (sum, item) => sum + item.lineTotal,
                                    ) ??
                                    0)
                                .toCurrencySuperscript(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.primary(
                              disabled:
                                  (state.cart?.items.isEmpty ?? true) ||
                                  !storeIsOpen,
                              onPressed: () {
                                context.pushNamed(ScheduleOrderPage.route);
                              },
                              label: storeIsOpen ? 'Pay' : 'Store is closed',
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),

                          Expanded(
                            child: AppButton.outlined(
                              disabled: state.cart?.items.isEmpty ?? true,
                              onPressed: () {
                                context.read<DraftCubit>().createDraft(
                                  cart: state.cart!,
                                );
                                context.goNamed(DraftsPage.route);
                              },
                              label: 'Save as draft',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
