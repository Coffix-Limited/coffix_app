import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/presentation/atoms/app_clickable.dart';
import 'package:coffix_app/presentation/atoms/app_icon.dart';
import 'package:flutter/material.dart';

/// A reusable icon button atom widget.
///
/// Displays a clickable icon that can be either an IconData icon or an SVG asset.
/// Wraps AppIcon with AppClickable for interactive behavior.
/// No padding or margins - parent controls spacing.
///
/// Usage:
/// ```dart
/// // With IconData
/// AppIconButton.withIconData(
///   Icons.search,
///   onPressed: () {},
///   size: AppSizes.iconSizeMedium,
///   color: AppColors.primary,
/// )
///
/// // With SVG path
/// AppIconButton.withSvgPath(
///   AppIcons.check,
///   onPressed: () {},
///   size: AppSizes.iconSizeSmall,
///   color: AppColors.primary,
/// )
/// ```
class AppIconButton extends StatelessWidget {
  /// The icon data (for Material icons).
  final IconData? _iconData;

  /// The SVG asset path.
  final String? _svgPath;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// The size of the icon. Defaults to AppSizes.iconSizeMedium if not provided.
  final double? size;

  /// The color of the icon. If null, inherits from theme.
  final Color? color;

  /// Whether the button is disabled.
  final bool disabled;

  /// Border color. If null, no border is drawn.
  final Color? borderColor;

  /// Border radius. If null, no border radius is applied.
  final BorderRadius? borderRadius;

  /// Background color. If null, no background color is applied.
  final Color? backgroundColor;

  /// Creates an AppIconButton from IconData.
  const AppIconButton.withIconData(
    IconData icon, {
    super.key,
    required this.onPressed,
    this.size,
    this.color,
    this.disabled = false,
    this.borderColor,
    this.borderRadius,
    this.backgroundColor,
  }) : _iconData = icon,
       _svgPath = null;

  /// Creates an AppIconButton from an SVG asset path.
  const AppIconButton.withSvgPath(
    String svgPath, {
    super.key,
    required this.onPressed,
    this.size,
    this.color,
    this.disabled = false,
    this.borderColor,
    this.borderRadius,
    this.backgroundColor,
  }) : _iconData = null,
       _svgPath = svgPath;

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? AppSizes.iconSizeMedium;
    final isDisabled = disabled || onPressed == null;
    final iconColor = isDisabled
        ? (color ?? AppColors.white).withValues(alpha: AppSizes.opacityDisabled)
        : color;

    final Widget iconWidget;
    final iconData = _iconData;
    if (iconData != null) {
      iconWidget = AppIcon.withIconData(
        iconData,
        size: iconSize,
        color: iconColor,
      );
    } else {
      final svgPath = _svgPath;
      iconWidget = AppIcon.withSvgPath(
        svgPath!,
        size: iconSize,
        color: iconColor,
      );
    }

    final content = Padding(
      padding: const EdgeInsets.all(AppSizes.xs),
      child: iconWidget,
    );

    return AppClickable(
      onPressed: isDisabled ? () {} : onPressed!,
      borderRadius: borderRadius ?? BorderRadius.circular(AppSizes.md),
      showSplash: !isDisabled,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.sm),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor ?? AppColors.borderColor),
          borderRadius: borderRadius ?? BorderRadius.circular(AppSizes.md),
          color: backgroundColor,
        ),
        child: content,
      ),
    );
  }
}
