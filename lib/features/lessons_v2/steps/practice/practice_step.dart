import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
import '../../providers/lesson_recording_provider.dart';

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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
          _PracticeTipBanner(
            sourceId: '${widget.step.key}-tip',
            url: tipAudioUrl,
            label: tipText,
          ),
          const SizedBox(height: 8),
          _PracticeRecordingCard(
            sourceId: '${widget.step.key}-recording',
            prompt: _recordingPrompt(),
          ),
        ],
      ),
    );
  }

  String _recordingPrompt() {
    final recordingConfig =
        (widget.step.config['recording'] as Map?)?.cast<String, dynamic>() ??
            {};
    final prompt = recordingConfig['prompt'] as String?;
    if (prompt != null && prompt.trim().isNotEmpty) {
      return prompt.trim();
    }

    final targetSound = recordingConfig['target_sound'] as String? ??
        widget.step.config['target_sound'] as String? ??
        _soundFromItems();
    if (targetSound.trim().isEmpty) {
      return 'Your turn: say the sound';
    }

    final sound = targetSound.trim();
    final formattedSound =
        sound.startsWith('/') && sound.endsWith('/') ? sound : '/$sound/';
    return 'Your turn: say $formattedSound';
  }

  String _soundFromItems() {
    final items = (widget.step.config['items'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
    if (items.isEmpty) {
      return '';
    }

    final highlightedLetters = items.first['highlighted_letters'] as String?;
    if (highlightedLetters != null && highlightedLetters.trim().isNotEmpty) {
      return highlightedLetters.trim();
    }

    final label = items.first['label'] as String? ?? '';
    return label.isNotEmpty ? label[0] : '';
  }
}

class _PracticeTipBanner extends StatelessWidget {
  final String sourceId;
  final String url;
  final String label;

  const _PracticeTipBanner({
    required this.sourceId,
    required this.url,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accentColor,
        border: Border(
          top: BorderSide(
            color: AppColors.accentColor.withOpacity(0.7),
          ),
          bottom: BorderSide(
            color: AppColors.accentColor.withOpacity(0.7),
          ),
        ),
      ),
      child: LessonAudioInlineButton(
        sourceId: sourceId,
        url: url,
        label: label,
        buttonSize: 36,
        backgroundColor: AppColors.accentColor,
      ),
    );
  }
}

class _PracticeRecordingCard extends ConsumerWidget {
  final String sourceId;
  final String prompt;

  const _PracticeRecordingCard({
    required this.sourceId,
    required this.prompt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingState = ref.watch(lessonRecordingProvider(sourceId));
    final recordingController =
        ref.read(lessonRecordingProvider(sourceId).notifier);
    final icon = recordingState.isReadyToPlay || recordingState.isPlaying
        ? Icons.play_arrow
        : Icons.mic;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Text(
            prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: recordingController.handleButtonPress,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.accentColor,
                shape: BoxShape.circle,
                border: recordingState.isRecording || recordingState.isPlaying
                    ? Border.all(color: AppColors.primaryColor, width: 2)
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (recordingState.isRecording)
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  Icon(
                    icon,
                    color: AppColors.primaryColor,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            recordingState.statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              height: 1.25,
              color: AppColors.lightGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (recordingState.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              recordingState.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.errorColor,
              ),
            ),
          ],
          if (recordingState.hasCompletedCycle) ...[
            const SizedBox(height: 8),
            const Text(
              'Good effort! Listen to the model again and try to match the sound.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.25,
                color: AppColors.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
