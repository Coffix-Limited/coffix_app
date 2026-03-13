import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';

class AppDateField extends StatefulWidget {
  final String? label;
  final String hintText;
  final String name;
  final bool isRequired;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateFormat? format;
  final SelectableDayPredicate? selectableDayPredicate;
  final bool isHorizontalAlign;

  const AppDateField({
    super.key,
    required this.label,
    required this.hintText,
    required this.name,
    this.isRequired = false,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.format,
    this.selectableDayPredicate,
    this.isHorizontalAlign = false,
  });

  @override
  State<AppDateField> createState() => _AppDateFieldState();
}

class _AppDateFieldState extends State<AppDateField> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final format = widget.format ?? DateFormat('dd/MM/yyyy');
    return format.format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formBuilder = FormBuilderField<DateTime>(
      name: widget.name,
      validator: widget.isRequired ? FormBuilderValidators.required() : null,
      builder: (FormFieldState<DateTime> field) {
        return GestureDetector(
          onTap: () async {
            final result = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: widget.firstDate ?? DateTime.now(),
              lastDate: widget.lastDate ?? DateTime.now(),
              initialDatePickerMode: DatePickerMode.day,
              initialEntryMode: DatePickerEntryMode.calendarOnly,
            );
            if (result != null) {
              setState(() {
                _selectedDate = result;
              });
              field.didChange(result);
            }
          },
          child: AbsorbPointer(
            absorbing: true,
            child: TextFormField(
              readOnly: true,
              controller: TextEditingController(
                text: _formatDate(_selectedDate),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF9CA4AB),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.sm),
                  borderSide: BorderSide(color: AppColors.lightGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.sm),
                  borderSide: BorderSide(color: AppColors.lightGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.sm),
                  borderSide: BorderSide(color: AppColors.lightGrey),
                ),
                prefixIcon: widget.prefixIcon,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon:
                    widget.suffixIcon ??
                    const Icon(Icons.calendar_today, size: 20),
                suffixIconConstraints: widget.suffixIconConstraints,
                errorText: field.errorText,
              ),
            ),
          ),
        );
      },
    );
    return widget.isHorizontalAlign
        ? Row(
            children: [
              if (widget.label != null)
                SizedBox(
                  width: 120,
                  child: Padding(
                    padding: EdgeInsets.only(right: AppSizes.md),
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
                ),
              Expanded(child: formBuilder),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
