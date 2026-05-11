import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
import '../../providers/lesson_recording_provider.dart';
import 'dart:math' as math;

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
    final isRecording = recordingState.isRecording;
    final icon = recordingState.isReadyToPlay || recordingState.isPlaying
        ? Icons.play_arrow
        : Icons.mic;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          const Text(
            'Now record yourself:',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF171B22),
            ),
          ),
          if (prompt.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
          ],
          const SizedBox(height: 18),
          GestureDetector(
            onTap: recordingController.handleButtonPress,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isRecording
                    ? AppColors.primaryColor.withOpacity(0.14)
                    : AppColors.accentColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isRecording
                      ? Container(
                          key: const ValueKey('stop-icon'),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.stop,
                            color: Colors.white,
                            size: 20,
                          ),
                        )
                      : Icon(
                          icon,
                          key: const ValueKey('mic-icon'),
                          color: AppColors.primaryColor,
                          size: 36,
                        ),
                ),
              ),
            ),
          ),
          if (recordingState.isRecording || recordingState.isReadyToPlay || recordingState.isPlaying) ...[
            const SizedBox(height: 16),
            _RecordingWaveform(
              isRecording: recordingState.isRecording,
              isPlaying: recordingState.isPlaying,
              onTap: recordingController.handleButtonPress,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            recordingState.statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color.fromARGB(255, 23, 34, 32),
              fontWeight: FontWeight.w700,
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
              'Listen to the model again and try to match the sound.',
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

class _RecordingWaveform extends StatefulWidget {
  final bool isRecording;
  final bool isPlaying;
  final VoidCallback onTap;

  const _RecordingWaveform({
    super.key,
    required this.isRecording,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  State<_RecordingWaveform> createState() => _RecordingWaveformState();
}

class _RecordingWaveformState extends State<_RecordingWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  static const List<double> _heightRatios = [
    0.30, 0.55, 0.75, 0.90, 0.65, 1.00, 0.80, 0.55, 0.95, 0.70,
    0.45, 0.85, 0.60, 1.00, 0.75, 0.50, 0.90, 0.65, 0.40, 0.80,
    0.55, 0.70, 0.95, 0.60, 0.35, 0.75, 0.50, 0.88, 0.65, 0.40,
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAnimating = widget.isRecording || widget.isPlaying;
    final backgroundColor = widget.isRecording ? Colors.white : AppColors.copBlue;
    final barColor = widget.isRecording
        ? AppColors.primaryColor
        : Colors.white.withOpacity(0.85);
    final waveformHeight = widget.isRecording ? 20.0 : 28.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(32),
          border: widget.isRecording
              ? Border.all(color: AppColors.primaryColor.withOpacity(0.2), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(_heightRatios.length, (i) {
                      final scale = isAnimating
                          ? 0.4 +
                              0.6 *
                                  ((0.5 +
                                              0.5 *
                                                  (_animController.value * 2 *
                                                          math.pi +
                                                      i * 0.4)
                                                      .abs()) %
                                              1.0)
                                          .clamp(0.0, 1.0)
                          : 0.35;

                      return Container(
                        width: 2.5,
                        height: waveformHeight * _heightRatios[i] * scale,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            if (!widget.isRecording) ...[
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    widget.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppColors.copBlue,
                    size: 20,
                  ),
                ),
              ),
            ],
          ],
        ),
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
