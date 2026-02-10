import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';
import '../widgets/lesson_audio_buttons.dart';

class LessonAudioTipBanner extends StatelessWidget {
  final String sourceId;
  final String url;
  final String label;

  const LessonAudioTipBanner({
    super.key,
    required this.sourceId,
    required this.url,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentColor,
        border: Border(
          top: BorderSide(
            color: AppColors.accentColor.withOpacity(0.6),
            width: 1,
          ),
          bottom: BorderSide(
            color: AppColors.accentColor.withOpacity(0.6),
            width: 1,
          ),
        ),
      ),
      child: LessonAudioInlineButton(
        sourceId: sourceId,
        url: url,
        label: label,
      ),
    );
  }
}
