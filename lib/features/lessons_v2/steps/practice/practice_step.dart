import 'package:flutter/material.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
import '../../widgets/lesson_audio_tip_banner.dart';

class PracticeStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const PracticeStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<PracticeStep> createState() => _PracticeStepState();
}

class _PracticeStepState extends State<PracticeStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.step.config['title'] as String? ?? 'Practice';
    final tipMap =
        (widget.step.config['tip'] as Map?)?.cast<String, dynamic>() ?? {};
    final tipText = tipMap['text'] as String? ??
        'Tip: Say each word out loud after hearing it.\nFocus on the highlighted letter sound.';
    final tipAudioUrl = tipMap['sound_url'] as String? ?? '';
    final items = (widget.step.config['items'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.79,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _ExampleCard(
                label: item['label'] as String? ?? '',
                imageUrl: item['image_url'] as String? ?? '',
                audioUrl: item['sound_url'] as String? ?? '',
                highlightedLetters: item['highlighted_letters'] as String? ?? '',
                sourceId: '${widget.step.key}-item-$index',
              );
            },
          ),
          const SizedBox(height: 15),
          LessonAudioTipBanner(
            sourceId: '${widget.step.key}-tip',
            url: tipAudioUrl,
            label: tipText,
          ),
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final String label;
  final String imageUrl;
  final String audioUrl;
  final String sourceId;
  final String highlightedLetters;

  const _ExampleCard({
    required this.label,
    required this.imageUrl,
    required this.audioUrl,
    required this.sourceId,
    this.highlightedLetters = '',
  });

  @override
  Widget build(BuildContext context) {
    final highlight = highlightedLetters.trim().isNotEmpty
        ? highlightedLetters.trim()
        : (label.isNotEmpty ? label[0] : '');

    final idx = label.toLowerCase().indexOf(highlight.toLowerCase());

    final String before, focused, after;
    if (idx == -1 || highlight.isEmpty) {
      before = label;
      focused = '';
      after = '';
    } else {
      before = label.substring(0, idx);
      focused = label.substring(idx, idx + highlight.length);
      after = label.substring(idx + highlight.length);
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 32,
                        color: AppColors.textColor,
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      width: 120,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                if (before.isNotEmpty)
                  TextSpan(
                    text: before,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor,
                    ),
                  ),
                if (focused.isNotEmpty)
                  TextSpan(
                    text: focused,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                if (after.isNotEmpty)
                  TextSpan(
                    text: after,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor,
                    ),
                  ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 30,
            child: LessonAudioInlineButton(
              sourceId: sourceId,
              url: audioUrl,
            ),
          ),
        ],
      ),
    );
  }
}