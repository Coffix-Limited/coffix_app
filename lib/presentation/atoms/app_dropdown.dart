import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class AppDropdown<T, V> extends StatelessWidget {
  final String name;
  final List<T> options;
  final String Function(T) itemLabel;
  final V Function(T) itemValue; // <-- extract the value from the option
  final V? initialValue;
  final String? label;
  final String hintText;
  final bool isRequired;
  final List<FormFieldValidator<V>>? validators;
  final ValueChanged<V?>? onChanged;
  final bool isHorizontalAlign;

  const AppDropdown({
    super.key,
    required this.name,
    required this.options,
    required this.itemLabel,
    required this.itemValue,
    this.initialValue,
    this.label,
    this.hintText = 'Select',
    this.isRequired = false,
    this.validators,
    this.onChanged,
    this.isHorizontalAlign = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formBuilder = FormBuilderField<V>(
      name: name,
      initialValue: initialValue,
      validator: FormBuilderValidators.compose([
        if (isRequired) (value) => value == null ? 'Required' : null,
        ...?validators,
      ]),
      builder: (state) {
        final borderRadius = BorderRadius.circular(AppSizes.sm);

        return DropdownButtonFormField<V>(
          initialValue: state.value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.black),
          dropdownColor: Colors.white,
          menuMaxHeight: 280,
          borderRadius: borderRadius,
          style: AppTypography.bodyS.copyWith(color: AppColors.black),
          selectedItemBuilder: (_) {
            return options.map((option) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  itemLabel(option),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyS.copyWith(color: AppColors.black),
                ),
              );
            }).toList();
          },
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.lightGrey,
            ),
            border: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: AppColors.lightGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: AppColors.lightGrey),
            ),
            errorText: state.errorText,
          ),
          items: options.map((option) {
            return DropdownMenuItem<V>(
              value: itemValue(option), // <-- use extracted value
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.xs,
                  vertical: AppSizes.xs,
                ),
                child: Text(
                  itemLabel(option),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyS.copyWith(color: AppColors.black),
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            state.didChange(value);
            onChanged?.call(value);
          },
        );
      },
    );

    return isHorizontalAlign
        ? Row(
            children: [
              if (label != null)
                SizedBox(
                  width: 120,
                  child: Padding(
                    padding: EdgeInsets.only(right: AppSizes.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(label!, style: AppTypography.bodyXS),
                        ),
                        if (isRequired)
                          Text(
                            '*',
                            style: AppTypography.bodyXS.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              Expanded(child: formBuilder),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (label != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.xs),
                  child: Row(
                    children: [
                      Text(
                        label!,
                        style: AppTypography.bodyXS.copyWith(
                          color: AppColors.black,
                        ),
                      ),
                      if (isRequired)
                        Text(
                          ' *',
                          style: AppTypography.bodyXS.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                    ],
                  ),
                ),
              formBuilder,
            ],
          );
  }
}
