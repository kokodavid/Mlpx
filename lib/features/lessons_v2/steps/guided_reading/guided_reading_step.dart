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
          _Header(title: _config.title),
          const SizedBox(height: 14),
          LessonStepCard(
            color: const Color(0xFFF5F3F0),
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
                _WaveformPlayer(
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

// ---------------------------------------------------------------------------
// _Header
// ---------------------------------------------------------------------------

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
        color: Color(0xFF171B22),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _InstructionPlayButton
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// _SegmentRow
// ---------------------------------------------------------------------------

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
            _SegmentChip(
              stepKey: stepKey,
              activityIndex: activityIndex,
              segmentIndex: index,
              segment: segments[index],
              isFocused: hasExplicitFocus
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

class _SegmentChip extends ConsumerWidget {
  final String stepKey;
  final int activityIndex;
  final int segmentIndex;
  final GuidedReadingSegment segment;
  final bool isFocused;

  const _SegmentChip({
    required this.stepKey,
    required this.activityIndex,
    required this.segmentIndex,
    required this.segment,
    required this.isFocused,
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

        final bg = isPlaying
            ? AppColors.primaryColor.withValues(alpha: 0.10)
            : Colors.white;

        final labelColor =
            isFocused ? AppColors.primaryColor : AppColors.copBlue;

        return GestureDetector(
          onTap: segment.audioUrl.isEmpty
              ? null
              : () => controller.playUrl(segment.audioUrl, sourceId: sourceId),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: isFocused
                  ? null
                  : Border.all(color: const Color(0xFFDDD8D1), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isFocused
                ? CustomPaint(
                    painter: _DashedRoundedBorderPainter(
                      color: AppColors.primaryColor,
                      radius: 18,
                      dashLength: 6,
                      dashGap: 4,
                      strokeWidth: 2.0,
                    ),
                    child: _chipLabel(segment.phonemeLabel, labelColor),
                  )
                : _chipLabel(segment.phonemeLabel, labelColor),
          ),
        );
      },
    );
  }

  Widget _chipLabel(String label, Color color) {
    return Center(
      child: Text(
        label,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DashedRoundedBorderPainter
// ---------------------------------------------------------------------------

class _DashedRoundedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashLength;
  final double dashGap;
  final double strokeWidth;

  const _DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashLength,
    required this.dashGap,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final half = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          half, half, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;
    final total = metric.length;

    double distance = 0;
    bool drawing = true;

    while (distance < total) {
      final segLen = drawing ? dashLength : dashGap;
      final end = (distance + segLen).clamp(0.0, total);
      if (drawing) {
        final extracted = metric.extractPath(distance, end);
        canvas.drawPath(extracted, paint);
      }
      distance += segLen;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter old) =>
      old.color != color ||
      old.dashLength != dashLength ||
      old.dashGap != dashGap;
}

// ---------------------------------------------------------------------------
// _WordText
// ---------------------------------------------------------------------------

class _WordText extends StatelessWidget {
  final String word;
  final List<GuidedReadingSegment> segments;

  const _WordText({required this.word, required this.segments});

  @override
  Widget build(BuildContext context) {
    final explicitFocusSegment =
        segments.cast<GuidedReadingSegment?>().firstWhere(
              (s) => s?.isFocus == true,
              orElse: () => null,
            );
    final focusSegment = explicitFocusSegment ??
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

// ---------------------------------------------------------------------------
// _WordAudioCard
// ---------------------------------------------------------------------------

class _WaveformPlayer extends ConsumerStatefulWidget {
  final String sourceId;
  final String audioUrl;

  const _WaveformPlayer({required this.sourceId, required this.audioUrl});

  @override
  ConsumerState<_WaveformPlayer> createState() => _WaveformPlayerState();
}

class _WaveformPlayerState extends ConsumerState<_WaveformPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

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
    final controller = ref.watch(lessonAudioControllerProvider);

    return ValueListenableBuilder<LessonAudioState>(
      valueListenable: controller.state,
      builder: (context, state, _) {
        final isActive = state.sourceId == widget.sourceId;
        final isPlaying = isActive && state.status == LessonAudioStatus.playing;

        if (isPlaying) {
          if (!_animController.isAnimating) {
            _animController.repeat(reverse: true);
          }
        } else {
          if (_animController.isAnimating) _animController.stop();
        }

        return GestureDetector(
          onTap: widget.audioUrl.isEmpty
              ? null
              : () =>
                  controller.playUrl(widget.audioUrl, sourceId: widget.sourceId),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WaveformBars(
                    controller: _animController,
                    playing: isPlaying,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WaveformBars extends StatelessWidget {
  final AnimationController controller;
  final bool playing;

  static const List<double> _heightRatios = [
    0.30, 0.55, 0.75, 0.90, 0.65, 1.00, 0.80, 0.55, 0.95, 0.70,
    0.45, 0.85, 0.60, 1.00, 0.75, 0.50, 0.90, 0.65, 0.40, 0.80,
    0.55, 0.70, 0.95, 0.60, 0.35, 0.75, 0.50, 0.88, 0.65, 0.40,
  ];

  const _WaveformBars({required this.controller, required this.playing});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_heightRatios.length, (i) {
            final scale = playing
                ? (0.4 +
                    0.6 *
                        ((0.5 +
                                    0.5 *
                                        (controller.value * 2 * 3.14159 +
                                                i * 0.4)
                                            .abs()) %
                                1.0)
                            .clamp(0.0, 1.0))
                : 0.35;

            return Container(
              width: 3,
              height: 32 * _heightRatios[i] * scale,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}