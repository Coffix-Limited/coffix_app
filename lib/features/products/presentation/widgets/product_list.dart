import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/products/data/model/product_category.dart';
import 'package:coffix_app/features/products/data/model/product_with_category.dart';
import 'package:coffix_app/features/products/logic/product_cubit.dart';
import 'package:coffix_app/features/products/logic/product_modifier_cubit.dart';
import 'package:coffix_app/features/products/presentation/pages/add_product_page.dart';
import 'package:coffix_app/presentation/atoms/app_card.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:coffix_app/presentation/atoms/app_field.dart';
import 'package:coffix_app/presentation/atoms/app_text_button.dart';
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: AppSizes.chipSizeSmall,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: allCategories.length,
                  separatorBuilder: (_, index) =>
                      const SizedBox(width: AppSizes.md),
                  itemBuilder: (context, index) {
                    final category = allCategories[index];
                    return AppClickable(
                      showSplash: false,
                      onPressed: () {
                        context.read<ProductCubit>().filterProductsByCategory(
                          category.name!,
                        );
                      },
                      child: AppCard(
                        borderColor: categoryFilter == category.name
                            ? AppColors.primary
                            : AppColors.white,
                        color: AppColors.lightGrey,
                        child: Text(
                          category.name ?? "",
                          style: AppTypography.labelS,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSizes.md),
              if (categoryFilter != null) ...[
                AppTextButton(
                  textStyle: AppTypography.labelS.copyWith(
                    color: AppColors.primary,
                  ),
                  text: "Clear Filter",
                  onPressed: () {
                    context.read<ProductCubit>().clearFilter();
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final product = products[index];
              return AppClickable(
                showSplash: false,
                onPressed: () {
                  context.read<ProductModifierCubit>().resetModifiers();
                  context.pushNamed(
                    AddProductPage.route,
                    extra: {"product": product.product, "storeId": storeId},
                  );
                },
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.md),
                      child: Image.network(
                        product.product.imageUrl ?? "",
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
