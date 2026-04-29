import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_step_widget.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
import '../../providers/lesson_audio_providers.dart';
import '../../services/lesson_audio_controller.dart';
import 'model.dart';

class GuidedReadingStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;
  final VoidCallback onAdvanceRequested;

  const GuidedReadingStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
    required this.onAdvanceRequested,
  });

  @override
  State<GuidedReadingStep> createState() => _GuidedReadingStepState();
}

class _GuidedReadingStepState extends State<GuidedReadingStep> {
  late final GuidedReadingConfig _config;
  int _currentActivityIndex = 0;

  GuidedReadingActivity get _activity => _config.activities[
      _currentActivityIndex.clamp(0, _config.activities.length - 1)];

  bool get _isLastActivity =>
      _currentActivityIndex >= _config.activities.length - 1;

  @override
  void initState() {
    super.initState();
    _config = GuidedReadingConfig.fromMap(widget.step.config);
    WidgetsBinding.instance.addPostFrameCallback((_) => _publishUiState());
  }

  void _publishUiState() {
    widget.onStepStateChanged(
      LessonStepUiState(
        canAdvance: false,
        isPrimaryEnabled: true,
        primaryLabel: 'Continue',
        onPrimaryPressed: _handleContinue,
      ),
    );
  }

  void _handleContinue() {
    if (_isLastActivity) {
      widget.onAdvanceRequested();
      return;
    }
    setState(() => _currentActivityIndex += 1);
    _publishUiState();
  }

  @override
  Widget build(BuildContext context) {
    final activity = _activity;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LessonStepTitle(title: _config.title),
          const SizedBox(height: 14),
          LessonStepCard(
            color: const Color(0xFFF6F6F6),
            elevation: 3,
            borderRadius: 24,
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _InstructionPlayButton(
                  sourceId:
                      '${widget.step.key}-instruction-$_currentActivityIndex',
                  url: activity.instructionAudioUrl,
                ),
                const SizedBox(height: 16),
                Text(
                  activity.instructionText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171B22),
                    height: 1.30,
                  ),
                ),
                const SizedBox(height: 18),
                _SegmentRow(
                  stepKey: widget.step.key,
                  activityIndex: _currentActivityIndex,
                  segments: activity.segments,
                ),
                const SizedBox(height: 18),
                _WordText(
                  word: activity.wordText,
                  segments: activity.segments,
                ),
                const SizedBox(height: 10),
                const LessonStepChevronDown(
                  color: AppColors.primaryColor,
                  size: 28,
                ),
                const SizedBox(height: 14),
                LessonWaveformPlayer(
                  sourceId: '${widget.step.key}-word-$_currentActivityIndex',
                  audioUrl: activity.wordAudioUrl,
                  borderColor: const Color(0xFFE8E8E8),
                  backgroundColor: const Color(0xFFFAFAFA),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionPlayButton extends ConsumerWidget {
  final String sourceId;
  final String url;

  const _InstructionPlayButton({
    required this.sourceId,
    required this.url,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(lessonAudioControllerProvider);

    return ValueListenableBuilder<LessonAudioState>(
      valueListenable: controller.state,
      builder: (context, state, _) {
        final isPlaying = state.sourceId == sourceId &&
            state.status == LessonAudioStatus.playing;

        return GestureDetector(
          onTap: url.isEmpty
              ? null
              : () => controller.playUrl(url, sourceId: sourceId),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        );
      },
    );
  }
}

class _SegmentRow extends StatelessWidget {
  final String stepKey;
  final int activityIndex;
  final List<GuidedReadingSegment> segments;

  const _SegmentRow({
    required this.stepKey,
    required this.activityIndex,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    final hasExplicitFocus = segments.any((s) => s.isFocus);
    final fallbackIndex = segments.length ~/ 2;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFCF9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF2ECE4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < segments.length; index++) ...[
            PhonemeButton.segment(
              sourceId: '$stepKey-segment-$activityIndex-$index',
              label: segments[index].phonemeLabel,
              audioUrl: segments[index].audioUrl,
              highlighted: hasExplicitFocus
                  ? segments[index].isFocus
                  : index == fallbackIndex,
            ),
            if (index < segments.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _WordText extends StatelessWidget {
  final String word;
  final List<GuidedReadingSegment> segments;

  const _WordText({required this.word, required this.segments});

  @override
  Widget build(BuildContext context) {
    final focusSegment =
        segments.cast<GuidedReadingSegment?>().firstWhere(
              (s) => s?.isFocus == true,
              orElse: () => null,
            ) ??
        (segments.isNotEmpty ? segments[segments.length ~/ 2] : null);

    const baseStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: Color(0xFF171B22),
    );

    if (focusSegment == null || focusSegment.grapheme.isEmpty) {
      return Text(word, style: baseStyle);
    }

    final lowerWord = word.toLowerCase();
    final lowerGrapheme = focusSegment.grapheme.toLowerCase();
    final matchIndex = lowerWord.indexOf(lowerGrapheme);

    if (matchIndex < 0) return Text(word, style: baseStyle);

    final before = word.substring(0, matchIndex);
    final match =
        word.substring(matchIndex, matchIndex + focusSegment.grapheme.length);
    final after = word.substring(matchIndex + focusSegment.grapheme.length);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: const TextStyle(color: AppColors.primaryColor),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}