import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = true,
    this.danger = false,
    this.compact = false,
    this.success = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;
  final bool danger;
  final bool compact;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final background = success
        ? AppColors.emerald50
        : danger
        ? AppColors.red600
        : primary
        ? AppColors.blue600
        : Colors.white;
    final foreground = success
        ? AppColors.emerald700
        : primary || danger
        ? Colors.white
        : AppColors.slate700;
    final border = success
        ? AppColors.emerald100
        : primary || danger
        ? Colors.transparent
        : AppColors.slate200;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon == null
          ? const SizedBox.shrink()
          : Icon(icon, size: compact ? 14 : 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        elevation: primary || danger ? 1 : 0,
        shadowColor: AppColors.slate200,
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: Size(0, compact ? 30 : 46),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 20,
          vertical: 0,
        ),
        textStyle: TextStyle(
          fontSize: compact ? 12 : 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: border),
        ),
      ),
    );
  }
}
