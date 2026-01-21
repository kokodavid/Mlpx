import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';

class LessonProgressHeader extends StatelessWidget {
  final String label;
  final int percent;

  const LessonProgressHeader({
    super.key,
    required this.label,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final clampedPercent = percent.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textColor,
              ),
            ),
            const Spacer(),
            Text(
              '$clampedPercent%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: clampedPercent / 100,
            minHeight: 10,
            backgroundColor: AppColors.accentColor,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
