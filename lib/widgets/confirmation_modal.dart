import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'custom_button.dart';

Future<bool> showConfirmationModal(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Confirm',
  bool danger = false,
  IconData? icon,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.slate900.withValues(alpha: .5),
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: danger ? AppColors.red100 : AppColors.emerald100,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                icon ??
                    (danger
                        ? Icons.delete_outline
                        : Icons.check_circle_outline),
                color: danger ? AppColors.red600 : AppColors.emerald600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.slate900,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate500, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'Cancel',
                    primary: false,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    label: confirmText,
                    danger: danger,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  return result ?? false;
}
