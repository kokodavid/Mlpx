import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';

class LessonStepProgressHeader extends StatelessWidget {
  final int current;
  final int total;
  final String itemLabel;
  final int? score;
  final Color barColor;
  final double barHeight;
  final Color barBackgroundColor;

  const LessonStepProgressHeader({
    super.key,
    required this.current,
    required this.total,
    this.itemLabel = 'Item',
    this.score,
    this.barColor = AppColors.primaryColor,
    this.barHeight = 8,
    this.barBackgroundColor = const Color(0xFFF3E8DD),
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final safeCurrent = current.clamp(1, safeTotal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$itemLabel $safeCurrent of $safeTotal',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (score != null) ...[
              const Spacer(),
              Text(
                'Score: $score/$safeTotal',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: safeCurrent / safeTotal,
            minHeight: barHeight,
            backgroundColor: barBackgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}
