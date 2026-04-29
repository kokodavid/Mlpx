import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/utils/app_colors.dart';

class LessonStepInstructionSection extends StatelessWidget {
  final String stepKey;
  final String title;
  final String audioUrl;
  final Color audioBackgroundColor;
  final bool audioButtonIsCircular;
  final IconData? audioButtonDefaultIcon;
  final double buttonSize;

  const LessonStepInstructionSection({
    super.key,
    required this.stepKey,
    required this.title,
    required this.audioUrl,
    this.audioBackgroundColor = AppColors.primaryColor,
    this.audioButtonIsCircular = false,
    this.audioButtonDefaultIcon,
    this.buttonSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (audioUrl.isNotEmpty)
          LessonAudioInlineButton(
            sourceId: '$stepKey-instruction',
            url: audioUrl,
            backgroundColor: audioBackgroundColor,
            iconColor: Colors.white,
            isCircular: audioButtonIsCircular,
            defaultIcon: audioButtonDefaultIcon,
          )
        else
          Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: audioBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: buttonSize * 0.55,
            ),
          ),
        if (title.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF171B22),
            ),
          ),
        ],
      ],
    );
  }
}
