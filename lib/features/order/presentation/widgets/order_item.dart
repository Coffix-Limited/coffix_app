import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/cart/data/model/cart_item.dart';
import 'package:coffix_app/presentation/atoms/app_card.dart';
import 'package:coffix_app/presentation/atoms/app_icon_button.dart';
import 'package:flutter/material.dart';

class OrderItemRow extends StatelessWidget {
  const OrderItemRow({
    super.key,
    required this.cartItem,
    required this.price,
    required this.onRemove,
    required this.onEdit,
  });

  final CartItem cartItem;
  final double price;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.md),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Image.network(cartItem.productImageUrl, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${cartItem.productName} x${cartItem.quantity}",
                style: AppTypography.bodyM600,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cartItem.selectedByGroup.entries.map((entry) {
                  final modifierId = entry.value;
                  final label =
                      cartItem.modifierLabelSnapshot[modifierId] ?? modifierId;
                  final price = cartItem.modifierPriceSnapshot[modifierId];
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: AppTypography.body3XS.copyWith(
                            color: AppColors.textBlackColor,
                          ),
                        ),
                      ),
                      if (price != null && price != 0) ...[
                        const SizedBox(width: AppSizes.xs),
                        Text.rich(
                          TextSpan(
                            children: [
                              price.toCurrencySuperscript(
                                style: AppTypography.body2XS.copyWith(
                                  color: AppColors.textBlackColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                Text.rich(
                  price.toCurrencySuperscript(style: AppTypography.titleS),
                ),
                Row(
                  children: [
                    AppIconButton.withIconData(
                      Icons.edit_outlined,
                      onPressed: onEdit,
                      size: AppSizes.iconSizeSmall,
                      color: AppColors.black,
                      borderColor: Colors.transparent,
                    ),
                    const SizedBox(width: AppSizes.xs),
                    AppIconButton.withIconData(
                      Icons.close,
                      onPressed: onRemove,
                      size: AppSizes.iconSizeSmall,
                      color: AppColors.black,
                      borderColor: Colors.transparent,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
