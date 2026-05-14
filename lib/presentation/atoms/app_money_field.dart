import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class AppMoneyField extends StatelessWidget {
  final String name;
  const AppMoneyField({
    super.key,
    required this.name,
    this.validators,
    this.initialValue,
    this.maxLength,
  });
  final List<FormFieldValidator<String>>? validators;

  final String? initialValue;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('\$', style: AppTypography.headlineXxl),
        SizedBox(width: AppSizes.sm),
        SizedBox(
          width: 140,
          child: FormBuilderTextField(
            initialValue: initialValue,
            name: name,
            maxLength: maxLength,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              counterText: maxLength != null ? '' : null,
              hintStyle: AppTypography.headlineXxl.copyWith(
                color: AppColors.lightGrey.withValues(alpha: 0.3),
              ),
              hintText: '0.00',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.md),
              ),
            ),
            style: AppTypography.headlineXxl,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.min(0),
              if (validators != null) ...validators!,
            ]),
          ),
        ),
      ],
    );
  }
}
