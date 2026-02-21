import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/utils/app_colors.dart';
import '../models/question_model.dart';

class QuestionInstructionHeader extends StatelessWidget {
  final AssessmentQuestion question;
  final String sourceId;
  final String audioLabel;
  final Color audioButtonColor;

  const QuestionInstructionHeader({
    super.key,
    required this.question,
    required this.sourceId,
    this.audioLabel = 'Click here to listen',
    this.audioButtonColor = const Color(0xFFE7D8C4),
  });

  @override
  Widget build(BuildContext context) {
    final title = question.questionTitle;
    final prompt = question.prompt.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (prompt.isNotEmpty) ...[
          Text(
            prompt,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (question.audioUrl.isNotEmpty)
          Row(
            children: [
              LessonAudioInlineButton(
                sourceId: sourceId,
                url: question.audioUrl,
                backgroundColor: audioButtonColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  audioLabel,
                  style: const TextStyle(
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textColor,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
