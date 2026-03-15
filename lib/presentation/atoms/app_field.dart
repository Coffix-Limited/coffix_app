import 'dart:async';
import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class AppField<T> extends StatefulWidget {
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool showPasswordToggle;
  final bool autofocus;
  final String name;
  final bool isRequired;
  final List<FormFieldValidator<T>>? validators;
  final Widget? prefixIcon;
  final Function(String?)? onChanged;
  final Duration debounceDuration;
  final String? initialValue;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;
  final int maxLines;
  final String? label;
  final bool filled;
  final bool isHorizontalAlign;

  const AppField({
    super.key,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.showPasswordToggle = false,
    this.autofocus = false,
    required this.name,
    this.isRequired = false,
    this.validators,
    this.prefixIcon,
    this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.initialValue,
    this.readOnly = false,
    this.inputFormatters,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.maxLines = 1,
    this.label,
    this.filled = true,
    this.isHorizontalAlign = false,
  });

  @override
  State<AppField<T>> createState() => _AppFieldState<T>();
}

class _AppFieldState<T> extends State<AppField<T>> {
  bool isPasswordVisible = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String? value) {
    if (widget.onChanged == null) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onChanged!(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget formBuilder = FormBuilderTextField(
      maxLines: widget.maxLines,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      initialValue: widget.initialValue,
      onChanged: _onTextChanged,
      name: widget.name,
      inputFormatters: widget.inputFormatters,
      readOnly: widget.readOnly,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText && !isPasswordVisible,
      autofocus: widget.autofocus,
      style: theme.textTheme.bodyMedium?.copyWith(),
      decoration: InputDecoration(
        fillColor: widget.readOnly ? AppColors.softGrey : Colors.white,
        filled: widget.filled,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSizes.lg),
        hintText: widget.hintText,
        hintStyle: AppTypography.bodyXS.copyWith(color: AppColors.lightGrey),
        border: widget.readOnly
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.lg),
                borderSide: BorderSide.none,
              )
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.lg),
                borderSide: BorderSide(color: AppColors.lightGrey),
              ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.lg),
          borderSide: BorderSide(color: AppColors.lightGrey),
        ),
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.showPasswordToggle
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => isPasswordVisible = !isPasswordVisible),
              )
            : null,
      ),
      validator: FormBuilderValidators.compose([
        if (widget.isRequired) FormBuilderValidators.required(),
        if (widget.validators != null)
          ...widget.validators!.map(
            (validator) => validator as FormFieldValidator<String>,
          ),
      ]),
      errorBuilder: (context, error) => Text(error.toString()),
    );
    return widget.isHorizontalAlign
        ? Row(
            children: [
              if (widget.label != null)
                SizedBox(
                  width: 140,
                  child: Padding(
                    padding: EdgeInsets.only(right: AppSizes.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: RichText(
                            textAlign: TextAlign.left,
                            text: TextSpan(
                              style: AppTypography.bodyXS,
                              children: [
                                TextSpan(text: widget.label!),
                                if (widget.isRequired) TextSpan(text: '*'),
                              ],
                            ),
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
              if (widget.label != null)
                Padding(
                  padding: EdgeInsets.only(bottom: AppSizes.xs),
                  child: Row(
                    children: [
                      Text(widget.label!, style: AppTypography.bodyXS),
                      if (widget.isRequired)
                        Text(
                          '*',
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
