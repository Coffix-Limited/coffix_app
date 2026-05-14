import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:flutter/material.dart';

class ProfileTile extends StatelessWidget {
  const ProfileTile({
    super.key,
    required this.label,
    required this.onTap,
    required this.icon,
    this.textColor,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  final String icon;
  final Widget? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return AppClickable(
      onPressed: onTap,
      borderRadius: BorderRadius.circular(AppSizes.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Image.asset(
                    icon,
                    width: AppSizes.iconSizeMedium,
                    height: AppSizes.iconSizeMedium,
                  ),
                  SizedBox(width: AppSizes.sm),
                  Text(
                    label,
                    style: AppTypography.bodyM.copyWith(
                      color: textColor ?? AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingIcon != null) trailingIcon!,
          ],
        ),
      ),
    );
  }
}
