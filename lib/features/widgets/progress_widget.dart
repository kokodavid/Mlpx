import 'package:flutter/material.dart';
import 'package:milpress/features/widgets/custom_progress_indicator.dart';
import 'package:milpress/utils/app_colors.dart';

class ProgressSection extends StatelessWidget {
  final double progress;
  final String questionNumber;

  ProgressSection({required this.progress, required this.questionNumber});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your progress',
          style: TextStyle(fontSize: 12, color: AppColors.textColor),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toInt()}% complete',
              style: const TextStyle(fontSize: 17, color: AppColors.primaryColor),
            ),
            Text(
              'Question $questionNumber',
              style: const TextStyle(fontSize: 13, color: AppColors.textColor),
            ),
          ],
        ),
        const SizedBox(height: 5),
        CustomProgressIndicator(progress: progress),
        const SizedBox(height: 15),
      ],
    );
  }
}
