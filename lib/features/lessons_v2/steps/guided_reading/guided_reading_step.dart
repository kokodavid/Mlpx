import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_audio_buttons.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _publishUiState();
    });
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
    setState(() {
      _currentActivityIndex += 1;
    });
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
          _Header(title: _config.title),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFF2ECE4)),
            ),
            child: Column(
              children: [
                LessonAudioInlineButton(
                  sourceId:
                      '${widget.step.key}-instruction-$_currentActivityIndex',
                  url: activity.instructionAudioUrl,
                  backgroundColor: const Color(0xFFF8F8F8),
                ),
                const SizedBox(height: 18),
                Text(
                  activity.instructionText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171B22),
                    height: 1.25,
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
                const Icon(
                  Icons.keyboard_double_arrow_down_rounded,
                  color: AppColors.copBlue,
                  size: 28,
                ),
                const SizedBox(height: 14),
                _WordAudioCard(
                  sourceId: '${widget.step.key}-word-$_currentActivityIndex',
                  audioUrl: activity.wordAudioUrl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;

  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFFC08BF8),
      ),
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
            _SegmentChip(
              stepKey: stepKey,
              activityIndex: activityIndex,
              segmentIndex: index,
              segment: segments[index],
            ),
            if (index < segments.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _SegmentChip extends ConsumerWidget {
  final String stepKey;
  final int activityIndex;
  final int segmentIndex;
  final GuidedReadingSegment segment;

  const _SegmentChip({
    required this.stepKey,
    required this.activityIndex,
    required this.segmentIndex,
    required this.segment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(lessonAudioControllerProvider);

    return ValueListenableBuilder<LessonAudioState>(
      valueListenable: controller.state,
      builder: (context, state, _) {
        final sourceId = '$stepKey-segment-$activityIndex-$segmentIndex';
        final isPlaying = state.sourceId == sourceId &&
            state.status == LessonAudioStatus.playing;

        return GestureDetector(
          onTap: segment.audioUrl.isEmpty
              ? null
              : () => controller.playUrl(segment.audioUrl, sourceId: sourceId),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isPlaying
                  ? AppColors.primaryColor.withValues(alpha: 0.12)
                  : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: segment.isFocus
                    ? AppColors.primaryColor
                    : const Color(0xFFF2ECE4),
                width: segment.isFocus ? 1.4 : 1,
              ),
            ),
            child: Center(
              child: Text(
                segment.phonemeLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: segment.isFocus
                      ? AppColors.primaryColor
                      : AppColors.copBlue,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WordText extends StatelessWidget {
  final String word;
  final List<GuidedReadingSegment> segments;

  const _WordText({
    required this.word,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    final focusSegment = segments.cast<GuidedReadingSegment?>().firstWhere(
          (segment) => segment?.isFocus == true,
          orElse: () => null,
        );
    if (focusSegment == null || focusSegment.grapheme.isEmpty) {
      return Text(
        word,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Color(0xFF171B22),
        ),
      );
    }

    final lowerWord = word.toLowerCase();
    final lowerGrapheme = focusSegment.grapheme.toLowerCase();
    final matchIndex = lowerWord.indexOf(lowerGrapheme);
    if (matchIndex < 0) {
      return Text(
        word,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Color(0xFF171B22),
        ),
      );
    }

    final start = word.substring(0, matchIndex);
    final match =
        word.substring(matchIndex, matchIndex + focusSegment.grapheme.length);
    final end = word.substring(matchIndex + focusSegment.grapheme.length);

    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Color(0xFF171B22),
        ),
        children: [
          TextSpan(text: start),
          TextSpan(
            text: match,
            style: const TextStyle(color: AppColors.primaryColor),
          ),
          TextSpan(text: end),
        ],
      ),
    );
  }
}

class _WordAudioCard extends StatelessWidget {
  final String sourceId;
  final String audioUrl;

  const _WordAudioCard({
    required this.sourceId,
    required this.audioUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7DDD0)),
      ),
      child: Row(
        children: [
          LessonAudioInlineButton(
            sourceId: sourceId,
            url: audioUrl,
            backgroundColor: AppColors.primaryColor,
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: _WaveformPlaceholder(),
          ),
        ],
      ),
    );
  }
}

class _WaveformPlaceholder extends StatelessWidget {
  const _WaveformPlaceholder();

  @override
  Widget build(BuildContext context) {
    const heights = [8.0, 12.0, 18.0, 10.0, 22.0, 14.0, 26.0, 16.0, 20.0];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final height in heights)
          Container(
            width: 4,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}
