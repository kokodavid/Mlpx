import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/utils/app_colors.dart';
import '../models/lesson_models.dart';
import '../widgets/lesson_audio_tip_banner.dart';

class SoundPronunciationStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const SoundPronunciationStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<SoundPronunciationStep> createState() => _SoundPronunciationStepState();
}

class _SoundPronunciationStepState extends State<SoundPronunciationStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
    });
  }

  String get _centerLetter {
    final explicit = widget.step.config['phoneme_display'] as String?;
    if (explicit != null && explicit.trim().isNotEmpty) {
      return explicit.trim();
    }
    final displayText = widget.step.config['display_text'] as String? ?? '';
    final cleaned = displayText.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (cleaned.isEmpty) return 'a';
    if (cleaned.length == 1) return cleaned.toLowerCase();
    return cleaned[1].toLowerCase();
  }

  String get _phonemeLabel {
    final explicit = widget.step.config['phoneme_label'] as String?;
    if (explicit != null && explicit.trim().isNotEmpty) return explicit.trim();
    switch (_centerLetter) {
      case 'a':
        return '/ae/ as in "apple"';
      case 'e':
        return '/e/ as in "bed"';
      case 'i':
        return '/i/ as in "sit"';
      case 'o':
        return '/o/ as in "hot"';
      case 'u':
        return '/u/ as in "cup"';
      default:
        return '/$_centerLetter/ sound';
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioConfig =
        (widget.step.config['audio'] as Map?)?.cast<String, dynamic>() ?? {};
    final speedVariants =
        (audioConfig['speed_variants'] as Map?)?.cast<String, dynamic>() ?? {};
    final baseAudioUrl = audioConfig['base_url'] as String? ?? '';
    final howToSvgUrl = widget.step.config['how_to_svg_url'] as String? ?? '';
    final howToTitle = widget.step.config['how_to_title'] as String? ??
        'How to make this sound';
    final practiceTipMap =
        (widget.step.config['practice_tip'] as Map?)?.cast<String, dynamic>() ??
            {};
    final practiceTipText = practiceTipMap['text'] as String? ??
        'Tip: You just learned that a, e, i, o, u are vowel letters. In this lesson, we focus on the vowel /a/. We will hear, say, and find the short a sound, like in "apple" and "cat".';
    final practiceTipAudioUrl = practiceTipMap['audio_url'] as String? ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height * 0.7;
        final titleSize = height < 560 ? 24.0 : 28.0;
        final phonemeSize = height < 560 ? 54.0 : 64.0;
        final gap = height < 560 ? 10.0 : 14.0;

        return SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sound Pronunciation',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: gap),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: phonemeSize,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                      children: [
                        const TextSpan(
                          text: '/',
                          style: TextStyle(color: AppColors.copBlue),
                        ),
                        TextSpan(
                          text: _centerLetter,
                          style: const TextStyle(color: AppColors.primaryColor),
                        ),
                        const TextSpan(
                          text: '/',
                          style: TextStyle(color: AppColors.copBlue),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.lightGrey),
                    ),
                    child: _PhonemeChip(label: _phonemeLabel),
                  ),
                ),
                SizedBox(height: gap),
                LessonAudioCardButton(
                  sourceId: '${widget.step.key}-main',
                  url: baseAudioUrl,
                  speedUrls: speedVariants.map(
                    (key, value) => MapEntry(key, value?.toString() ?? ''),
                  ),
                ),
                SizedBox(height: gap),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          howToTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
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
                                child: howToSvgUrl.isEmpty
                                    ? const Center(
                                        child: Icon(
                                          Icons.image_outlined,
                                          size: 42,
                                          color: AppColors.textColor,
                                        ),
                                      )
                                    : SvgPicture.network(
                                        howToSvgUrl,
                                        fit: BoxFit.contain,
                                        placeholderBuilder: (_) => const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: gap),
                LessonAudioTipBanner(
                  sourceId: '${widget.step.key}-tip',
                  url: practiceTipAudioUrl,
                  label: practiceTipText,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PhonemeChip extends StatelessWidget {
  final String label;

  const _PhonemeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final parts = label.split(' as in ');
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        children: [
          TextSpan(
            text: parts.first,
            style: const TextStyle(color: AppColors.primaryColor),
          ),
          if (parts.length > 1)
            TextSpan(
              text: ' as in ${parts.sublist(1).join(' as in ')}',
              style: const TextStyle(color: AppColors.textColor),
            ),
        ],
      ),
    );
  }
}