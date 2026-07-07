import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.background,
    this.foreground,
  });

  final String label;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? AppColors.slate100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground ?? AppColors.slate700,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class StatusDropdown extends StatelessWidget {
  const StatusDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _background(value),
        border: Border.all(color: _border(value)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: TextStyle(
            color: _foreground(value),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  static Color _background(String value) {
    if (value.contains('Progress') || value.contains('progress')) {
      return AppColors.blue50;
    }
    if (value.contains('Ready')) return AppColors.indigo50;
    if (value.contains('Claimed') || value.contains('Completed')) {
      return AppColors.emerald50;
    }
    return AppColors.amber50;
  }

  static Color _border(String value) {
    if (value.contains('Claimed') || value.contains('Completed')) {
      return AppColors.emerald100;
    }
    if (value.contains('Progress') || value.contains('progress')) {
      return AppColors.blue100;
    }
    if (value.contains('Ready')) return AppColors.indigo100;
    return AppColors.amber100;
  }

  static Color _foreground(String value) {
    if (value.contains('Claimed') || value.contains('Completed')) {
      return AppColors.emerald700;
    }
    if (value.contains('Progress') || value.contains('progress')) {
      return AppColors.blue700;
    }
    if (value.contains('Ready')) return AppColors.indigo700;
    return AppColors.amber700;
  }
}
