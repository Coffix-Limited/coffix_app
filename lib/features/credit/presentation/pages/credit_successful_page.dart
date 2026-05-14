import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class CreditSuccessfulPage extends StatelessWidget {
  static String route = 'credit_successful_route';

  const CreditSuccessfulPage({
    super.key,
    required this.amount,
    required this.transactionNumber,
  });

  final double amount;
  final String transactionNumber;

  @override
  Widget build(BuildContext context) {
    return CreditSuccessfulView(
      amount: amount,
      transactionNumber: transactionNumber,
    );
  }
}

class CreditSuccessfulView extends StatelessWidget {
  const CreditSuccessfulView({
    super.key,
    required this.amount,
    required this.transactionNumber,
  });

  final double amount;
  final String transactionNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black.withValues(alpha: 0.7),
      body: SafeArea(
        child: Padding(
          padding: AppSizes.defaultPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SvgPicture.asset(AppImages.nameLogo, width: 124.0, height: 64.0),
              Center(
                child: Container(
                  padding: AppSizes.defaultPadding,
                  decoration: BoxDecoration(
                    color: AppColors.beige,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: AppSizes.iconSizeXLarge,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: AppSizes.xxl),
                      Text(
                        'Credit TopUp Successful',
                        style: AppTypography.headlineXl,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.lg),
                      Text(
                        'Your Coffix Credit balance will be updated shortly.',
                        style: AppTypography.bodyM,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.lg),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.xl,
                          vertical: AppSizes.md,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSizes.md),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Amount Paid: \$${amount.toStringAsFixed(2)}',
                              style: AppTypography.titleM.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSizes.xs),
                            Text(
                              'Transaction #: $transactionNumber',
                              style: AppTypography.bodyM,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSizes.xl),
                      AppButton.primary(
                        onPressed: () {
                          context.goNamed(HomePage.route);
                        },
                        label: "Ok",
                      ),
                      SizedBox(height: AppSizes.xl),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSizes.xl),
              Opacity(
                opacity: 0.6,
                child: Column(
                  children: [
                    AppButton.primary(
                      color: AppColors.lightGrey,
                      onPressed: () {},
                      label: "New Order",
                      disabled: true,
                    ),
                    const SizedBox(height: AppSizes.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.primary(
                            disabled: true,
                            onPressed: () {},
                            label: "ReOrder",
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: AppButton.primary(
                            disabled: true,
                            onPressed: () {},
                            label: "My Drafts",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
