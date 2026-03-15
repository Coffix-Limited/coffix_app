import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/images.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/features/menu/presentation/pages/menu_page.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:coffix_app/presentation/atoms/app_location.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBackHeader extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;
  final String title;
  final bool showLocation;
  final bool showBackButton;

  const AppBackHeader({
    super.key,
    this.onBack,
    required this.title,
    this.showLocation = true,
    this.showBackButton = true,
  });

  @override
  State<AppBackHeader> createState() => _AppBackHeaderState();

  @override
  Size get preferredSize => Size.fromHeight(showLocation ? 90 : 56);
}

class _AppBackHeaderState extends State<AppBackHeader> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.sm,
                  horizontal: AppSizes.xs,
                ),
                child: Row(
                  children: [
                    if (widget.showBackButton)
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: AppClickable(
                          showSplash: false,
                          onPressed: () {
                            if (widget.onBack != null) {
                              widget.onBack!();
                            } else {
                              context.pop();
                            }
                          },
                          child: Image.asset(
                            AppImages.backButton,
                            width: AppSizes.iconSizeMedium,
                            height: AppSizes.iconSizeMedium,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: AppSizes.iconSizeMedium + 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppTypography.headlineXxl.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: AppSizes.iconSizeMedium + 12),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.borderColor),
          if (widget.showLocation) AppLocation(),
        ],
      ),
    );
  }
}
