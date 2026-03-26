import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/extensions/price_extensions.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:flutter/material.dart';

class TierCard extends StatelessWidget {
  const TierCard({super.key, required this.amount, required this.percent});

  final double amount;
  final String percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'TopUp '),
              amount.toCurrencySuperscript(
                style: AppTypography.bodyM500.copyWith(
                  color: AppColors.textBlackColor,
                ),
              ),
              TextSpan(text: "+"),
            ],
          ),
        ),
        Text(
          'and get $percent more credit',
          style: AppTypography.labelS.copyWith(),
        ),
      ],
    );
  }
}
