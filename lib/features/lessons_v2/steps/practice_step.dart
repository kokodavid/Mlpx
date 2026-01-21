import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';
import '../models/lesson_models.dart';
import '../widgets/lesson_audio_buttons.dart';

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
                sourceId: '${widget.step.key}-item-$index',
              );
            },
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: LessonAudioInlineButton(
              sourceId: '${widget.step.key}-tip',
              url: tipAudioUrl,
              label: tipText,
            ),
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

  const _ExampleCard({
    required this.label,
    required this.imageUrl,
    required this.audioUrl,
    required this.sourceId,
  });

  @override
  Widget build(BuildContext context) {
    final firstLetter = label.isNotEmpty ? label[0] : '';
    final rest = label.length > 1 ? label.substring(1) : '';

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
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: AppColors.accentColor,
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
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: firstLetter,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                TextSpan(
                  text: rest,
                  style: const TextStyle(
                    fontSize: 16,
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