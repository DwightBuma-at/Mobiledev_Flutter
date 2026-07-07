import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.eyebrow,
    this.bottomSpacing = 32,
  });

  final String title;
  final String subtitle;
  final String? eyebrow;
  final List<Widget> actions;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              eyebrow!.toUpperCase(),
              style: const TextStyle(
                color: AppColors.blue600,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
        Text(title, style: AppTextStyles.h1),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTextStyles.body.copyWith(fontSize: 16)),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(spacing: 12, runSpacing: 12, children: actions),
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleBlock),
              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(spacing: 12, runSpacing: 12, children: actions),
                ),
            ],
          );
        },
      ),
    );
  }
}
