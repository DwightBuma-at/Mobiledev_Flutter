import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'custom_button.dart';

InputDecoration appInputDecoration(String? hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: AppColors.slate400),
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: AppColors.slate300),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: AppColors.blue600),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: AppColors.red600),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: AppColors.red600),
  ),
);

class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.requiredField = false,
    this.hint,
    this.maxLines = 1,
    this.readOnly = false,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.helperText,
  });

  final String label;
  final TextEditingController controller;
  final bool requiredField;
  final String? hint;
  final int maxLines;
  final bool readOnly;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? suffixIcon;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label: label, requiredField: requiredField),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          obscureText: obscureText,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: requiredField
              ? (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null
              : null,
          decoration: appInputDecoration(hint).copyWith(
            fillColor: readOnly ? AppColors.slate50 : null,
            filled: readOnly,
            suffixIcon: suffixIcon == null
                ? null
                : Icon(suffixIcon, color: AppColors.slate700, size: 18),
            helperText: helperText,
            helperStyle: const TextStyle(color: AppColors.slate400),
          ),
          style: const TextStyle(fontSize: 14, color: AppColors.slate800),
        ),
      ],
    );
  }
}

class LabeledDropdown extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.requiredField = false,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    final normalizedValue = items.contains(value) ? value : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label: label, requiredField: requiredField),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: normalizedValue,
          isExpanded: true,
          validator: requiredField
              ? (value) => value == null || value.isEmpty ? 'Required' : null
              : null,
          decoration: appInputDecoration(null),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item.isEmpty ? 'Select' : item),
                ),
              )
              .toList(),
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: AppColors.slate800),
        ),
      ],
    );
  }
}

class FormSectionTitle extends StatelessWidget {
  const FormSectionTitle(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.slate100)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.blue600,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: .8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ModalScaffold extends StatelessWidget {
  const ModalScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.onCancel,
    required this.onSave,
    this.saveText = 'Save',
    this.width = 720,
  });

  final String title;
  final Widget child;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String saveText;
  final double width;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final modalWidth = width > screenWidth - 48 ? screenWidth - 48 : width;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: modalWidth,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .95,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x330f172a), blurRadius: 24),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.slate800,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close, color: AppColors.slate400),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.slate200),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: child,
              ),
            ),
            const Divider(height: 1, color: AppColors.slate200),
            Container(
              color: AppColors.slate50,
              padding: const EdgeInsets.all(24),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 12,
                children: [
                  CustomButton(
                    label: 'Cancel',
                    primary: false,
                    onPressed: onCancel,
                  ),
                  CustomButton(label: saveText, onPressed: onSave),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.label, required this.requiredField});
  final String label;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: AppColors.slate700,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        children: [
          if (requiredField)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.red600),
            ),
        ],
      ),
    );
  }
}
