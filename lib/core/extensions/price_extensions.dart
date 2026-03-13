import 'package:coffix_app/core/theme/typography.dart';
import 'package:flutter/material.dart';

extension PriceExtensions on double {
  String toCurrency() => '\$${toStringAsFixed(2)}';

  InlineSpan toCurrencySuperscript({TextStyle? style}) {
    final parts = toStringAsFixed(2).split('.');
    final whole = parts[0];
    final decimal = parts[1];
    final baseStyle = style ?? AppTypography.titleXL;
    final fontSize = baseStyle.fontSize ?? 14;
    return TextSpan(
      children: [
        TextSpan(text: '\$$whole', style: baseStyle),
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Transform.translate(
            offset: Offset(0, -fontSize * 0.35),
            child: Text(
              decimal,
              style: baseStyle.copyWith(fontSize: fontSize * 0.65),
            ),
          ),
        ),
      ],
    );
  }
}
