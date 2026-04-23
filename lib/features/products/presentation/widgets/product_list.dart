import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/products/data/model/product_category.dart';
import 'package:coffix_app/features/products/data/model/product_with_category.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/features/products/logic/product_modifier_cubit.dart';
import 'package:coffix_app/features/products/presentation/pages/add_product_page.dart';
import 'package:coffix_app/presentation/atoms/app_cached_network_image.dart';
import 'package:coffix_app/presentation/atoms/app_card.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:coffix_app/presentation/atoms/app_field.dart';
import 'package:coffix_app/presentation/molecules/app_guest_bottom_sheet.dart';
import 'package:coffix_app/presentation/molecules/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProductList extends StatelessWidget {
  const ProductList({
    super.key,
    required this.products,
    required this.allCategories,
    this.isRoot = false,
    this.categoryFilter,
    required this.storeId,
  });

  final List<ProductWithCategory> products;
  final List<ProductCategory> allCategories;
  final bool isRoot;
  final String? categoryFilter;
  final String storeId;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (user) =>
          user.user.emailVerified == true &&
          user.user.finishedOnboarding == true,
      orElse: () => false,
    );
    return SingleChildScrollView(
      padding: AppSizes.defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: AppField(
                  onChanged: (val) {
                    context.read<ProductCubit>().searchProducts(val ?? "");
                  },
                  hintText: "Product Search",
                  name: "search",
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // product categories
          _CategoryList(
            allCategories: allCategories,
            categoryFilter: categoryFilter,
          ),
          const SizedBox(height: AppSizes.md),
          const SizedBox(height: AppSizes.lg),
          products.isEmpty
              ? const EmptyState(
                  icon: Icons.production_quantity_limits_outlined,
                  title: "No products found",
                  subtitle: "Please try again later",
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return AppClickable(
                      showSplash: false,
                      onPressed: () {
                        if (!isAuthenticated) {
                          AppGuestBottomSheet.show(
                            context,
                            message: "Please sign in to continue",
                          );
                        } else {
                          context.read<ProductModifierCubit>().resetModifiers();
                          context.pushNamed(
                            AddProductPage.route,
                            extra: {
                              "product": product.product,
                              "storeId": storeId,
                            },
                          );
                        }
                      },
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppSizes.md),
                            child: AppCachedNetworkImage(
                              imageUrl: product.product.imageUrl ?? "",
                              width: AppSizes.iconSizeXLarge,
                              height: AppSizes.iconSizeXLarge,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Text(
                              product.product.name ?? "",
                              style: AppTypography.labelS,
                            ),
                          ),
                          Text.rich(
                            product.product.price?.toCurrencySuperscript(
                                  style: AppTypography.labelL.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ) ??
                                0.00.toCurrencySuperscript(
                                  style: AppTypography.labelL.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, _) => const Divider(),
                  itemCount: products.length,
                ),
        ],
      ),
    );
  }
}

class _CategoryList extends StatefulWidget {
  const _CategoryList({
    required this.allCategories,
    required this.categoryFilter,
  });

  final List<ProductCategory> allCategories;
  final String? categoryFilter;

  @override
  State<_CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<_CategoryList> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeft = false;
  bool _showRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Delay to let the list lay out before checking if scrollable
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    setState(() {
      _showLeft = pos.pixels > 0;
      _showRight = pos.pixels < pos.maxScrollExtent;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: AppSizes.chipSizeSmall,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: widget.allCategories.length,
            separatorBuilder: (_, index) => const SizedBox(width: AppSizes.md),
            itemBuilder: (context, index) {
              final category = widget.allCategories[index];
              return AppClickable(
                showSplash: false,
                onPressed: () {
                  context.read<ProductCubit>().filterProductsByCategory(
                    category.name!,
                  );
                },
                child: AppCard(
                  borderColor: widget.categoryFilter == category.name
                      ? AppColors.primary
                      : AppColors.white,
                  color: widget.categoryFilter == category.name
                      ? AppColors.primary
                      : AppColors.lightGrey,
                  child: Text(category.name ?? "", style: AppTypography.labelS),
                ),
              );
            },
          ),
        ),
        // Left fade + arrow
        if (_showLeft)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: AppSizes.xxxl,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor,
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.chevron_left,
                    size: AppSizes.iconSizeMedium,
                  ),
                ),
              ),
            ),
          ),
        // Right fade + arrow
        if (_showRight)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: AppSizes.xxxl,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                  ),
                ),
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.chevron_right,
                    size: AppSizes.iconSizeMedium,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
