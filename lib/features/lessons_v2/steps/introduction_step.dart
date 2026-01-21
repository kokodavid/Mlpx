import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/utils/app_colors.dart';
import '../models/lesson_models.dart';
import '../widgets/lesson_audio_tip_banner.dart';

class IntroductionStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const IntroductionStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<IntroductionStep> createState() => _IntroductionStepState();
}

class _IntroductionStepState extends State<IntroductionStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.step.config['title'] as String? ?? 'Introduction';
    final displayText = widget.step.config['display_text'] as String? ?? '';
    debugPrint(
      'IntroductionStep: config=${widget.step.config}',
    );
    final audioConfig =
        (widget.step.config['audio'] as Map?)?.cast<String, dynamic>() ?? {};
    final speedVariants =
        (audioConfig['speed_variants'] as Map?)?.cast<String, dynamic>() ?? {};
    final baseAudioUrl = audioConfig['base_url'] as String? ?? '';
    final practiceTipMap =
        (widget.step.config['practice_tip'] as Map?)?.cast<String, dynamic>() ??
            {};
    final practiceTipText = practiceTipMap['text'] as String? ??
        'Practice: Say the sound out loud.';
    final practiceTipAudioUrl = practiceTipMap['audio_url'] as String? ?? '';
    final howToSvgUrl =
        widget.step.config['how_to_svg_url'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              displayText,
              style: const TextStyle(
                fontSize: 96,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 20),
          LessonAudioCardButton(
            sourceId: '${widget.step.key}-main',
            url: baseAudioUrl,
            speedUrls: speedVariants.map(
              (key, value) => MapEntry(
                key,
                value?.toString() ?? '',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'How to make this sound',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: SvgPicture.network(
                        howToSvgUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
          const SizedBox(height: 12),
          LessonAudioTipBanner(
            sourceId: '${widget.step.key}-tip',
            url: practiceTipAudioUrl,
            label: practiceTipText,
          ),

        ],
      ),
    );
  }
}
