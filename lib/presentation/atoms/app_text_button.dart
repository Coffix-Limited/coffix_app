import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:coffix_app/presentation/atoms/app_icon.dart';
import 'package:flutter/material.dart';

/// A text-only button that appears as clickable text with optional underline.
///
/// This is a simple text button with no padding or background, designed to be
/// placed inline with other text. It supports optional underline decoration
/// and an optional trailing icon.
///
/// Usage:
/// ```dart
/// AppTextButton(
///   text: AppLocalizations.of(context).learnMore,
///   onPressed: () {},
/// )
///
/// AppTextButton(
///   text: AppLocalizations.of(context).terms,
///   onPressed: () {},
///   underline: true,
/// )
///
/// AppTextButton.withTrailingIcon(
///   text: AppLocalizations.of(context).goToGiftsPage,
///   onPressed: () {},
///   iconPath: AppIcons.forwardArrow,
/// )
/// ```
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? textColor;
  final bool underline;
  final bool disabled;
  final TextStyle? textStyle;
  final String? trailingIconPath;
  final double? iconSize;
  final double? iconGap;
  final bool? showUnderline;

  const AppTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textColor,
    this.underline = false,
    this.disabled = false,
    this.textStyle,
    this.trailingIconPath,
    this.iconSize = AppSizes.iconSizeXxs,
    this.iconGap,
    this.showUnderline = false,
  });

  const AppTextButton.withTrailingIcon({
    super.key,
    required this.text,
    required this.onPressed,
    required String this.trailingIconPath,
    this.textColor,
    this.underline = false,
    this.disabled = false,
    this.textStyle,
    this.iconSize = AppSizes.iconSizeXxs,
    this.iconGap = AppSizes.xs,
    this.showUnderline = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onPressed == null;
    final finalTextColor = textColor ?? AppColors.black;
    final hasTrailingIcon = trailingIconPath != null;
    final defaultStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      decoration: showUnderline == true ? TextDecoration.underline : null,
      decorationColor: textColor ?? AppColors.black,
    );
    final finalStyle = textStyle ?? defaultStyle;

    Widget content;
    if (hasTrailingIcon) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(text, style: finalStyle),
          SizedBox(width: iconGap),
          AppIcon.withSvgPath(
            trailingIconPath!,
            size: iconSize ?? AppSizes.iconSizeXxs,
            color: finalTextColor.withValues(
              alpha: isDisabled ? AppSizes.opacityDisabledText : 1.0,
            ),
          ),
        ],
      );
    } else {
      content = Text(text, style: finalStyle);
    }

    return AppClickable(
      onPressed: isDisabled ? () {} : onPressed!,
      showSplash: false,
      child: content,
    );
  }
}
