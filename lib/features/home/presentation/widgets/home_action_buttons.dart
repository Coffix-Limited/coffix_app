import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/features/menu/presentation/pages/menu_page.dart';
import 'package:coffix_app/features/order/presentation/pages/order_page.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeActionButtons extends StatelessWidget {
  const HomeActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton.primary(
          onPressed: () {
            context.goNamed(MenuPage.route);
          },
          label: "New Order",
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            Expanded(
              child: AppButton.primary(
                onPressed: () {
                  context.pushNamed(OrderPage.route);
                },
                label: "ReOrder",
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: AppButton.primary(
                onPressed: () {},
                disabled: true,
                label: "My Drafts",
              ),
            ),
          ],
        ),
      ],
    );
  }
}
