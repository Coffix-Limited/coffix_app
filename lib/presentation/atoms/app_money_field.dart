import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class AppMoneyField extends StatelessWidget {
  final String name;
  const AppMoneyField({super.key, required this.name});

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
            name: name,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintStyle: AppTypography.headlineXxl.copyWith(
                color: AppColors.lightGrey,
              ),
              hintText: '50',
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
            ]),
          ),
        ),
      ],
    );
  }
}
