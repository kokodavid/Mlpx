import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/lessons_v2/services/lesson_audio_controller.dart';
import 'package:milpress/features/lessons_v2/widgets/lesson_step_widget.dart';
import 'package:milpress/utils/app_colors.dart';
import '../../models/lesson_models.dart';
import '../../providers/lesson_audio_providers.dart';
import '../../widgets/lesson_audio_buttons.dart';
import 'model.dart';

class MiniStoryCardStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;

  const MiniStoryCardStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
  });

  @override
  State<MiniStoryCardStep> createState() => _MiniStoryCardStepState();
}

class _MiniStoryCardStepState extends State<MiniStoryCardStep> {
  late final MiniStoryCardConfig _config;

  int _itemIndex = 0;

  MiniStoryCardItem get _item =>
      _config.items[_itemIndex.clamp(0, _config.items.length - 1)];

  bool get _isLastItem => _itemIndex >= _config.items.length - 1;

  @override
  void initState() {
    super.initState();
    _config = MiniStoryCardConfig.fromMap(widget.step.config);
    WidgetsBinding.instance.addPostFrameCallback((_) => _publishUiState());
  }

  void _publishUiState() {
    widget.onStepStateChanged(
      const LessonStepUiState(
        canAdvance: false,
        isPrimaryEnabled: false,
        showBottomActionBar: false,
      ),
    );
  }

  void _handleNext() {
    if (_isLastItem) {
      widget.onStepStateChanged(const LessonStepUiState(canAdvance: true));
      return;
    }
    setState(() {
      _itemIndex += 1;
    });
    _publishUiState();
  }

  @override
  Widget build(BuildContext context) {
    if (_config.items.isEmpty) {
      return const Center(child: Text('No story cards configured.'));
    }

    final item = _item;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.step.key.isNotEmpty) ...[
            Text(
              widget.step.key,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF171B22),
              ),
            ),
            const SizedBox(height: 12),
          ],
          LessonStepCard(
            color: const Color(0xFFF6F6F6),
            elevation: 3,
            borderRadius: 24,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LessonStepProgressHeader(
                  current: _itemIndex + 1,
                  total: _config.items.length,
                  itemLabel: 'Sentence',
                  barColor: AppColors.copBlue,
                  barHeight: 8,
                  barBackgroundColor: const Color(0xFFDDD8D1),
                ),
                const SizedBox(height: 20),
                Center(
                  child: LessonAudioInlineButton(
                    sourceId: '${widget.step.key}-top-story-$_itemIndex',
                    url: item.storyAudioUrl,
                    isCircular: true,
                    backgroundColor: AppColors.primaryColor,
                    iconColor: Colors.white,
                    defaultIcon: Icons.play_arrow,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  item.heading,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF171B22),
                  ),
                ),
                const SizedBox(height: 12),
                _StoryCard(
                  stepKey: widget.step.key,
                  itemIndex: _itemIndex,
                  item: item,
                ),
                const SizedBox(height: 14),
                _MiniStoryWaveformPlayer(
                  stepKey: widget.step.key,
                  itemIndex: _itemIndex,
                  audioUrl: item.storyAudioUrl,
                ),
                const SizedBox(height: 10),
                _ListenToSentenceButton(
                  sourceId: '${widget.step.key}-listen-$_itemIndex',
                  audioUrl: item.storyAudioUrl,
                  label: item.ctaLabel ?? 'Listen to the sentence',
                ),
                const SizedBox(height: 16),
                LessonStepNextButton(
                  label: _isLastItem ? 'Finish' : 'Continue',
                  onPressed: _handleNext,
                  borderRadius: 28,
                  height: 50,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final String stepKey;
  final int itemIndex;
  final MiniStoryCardItem item;

  const _StoryCard({
    required this.stepKey,
    required this.itemIndex,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final bodyLines = item.bodyLines
        .where((line) => line.trim() != item.heading.trim())
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E3DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (bodyLines.isNotEmpty)
            ...bodyLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textColor,
                    height: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniStoryWaveformPlayer extends StatefulWidget {
  final String stepKey;
  final int itemIndex;
  final String audioUrl;

  const _MiniStoryWaveformPlayer({
    required this.stepKey,
    required this.itemIndex,
    required this.audioUrl,
  });

  @override
  State<_MiniStoryWaveformPlayer> createState() =>
      _MiniStoryWaveformPlayerState();
}

class _MiniStoryWaveformPlayerState extends State<_MiniStoryWaveformPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  String get _sourceId =>
      '${widget.stepKey}-story-preview-${widget.itemIndex}';

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

  Future<void> _handleTap(LessonAudioController controller) async {
    final state = controller.state.value;
    if (state.sourceId == _sourceId &&
        state.status == LessonAudioStatus.playing) {
      await controller.stop();
      return;
    }
    await controller.playUrl(widget.audioUrl, sourceId: _sourceId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final controller = ref.watch(lessonAudioControllerProvider);

        return ValueListenableBuilder<LessonAudioState>(
          valueListenable: controller.state,
          builder: (context, state, _) {
            final isActive = state.sourceId == _sourceId;
            final isPlaying =
                isActive && state.status == LessonAudioStatus.playing;
            final isLoading =
                isActive && state.status == LessonAudioStatus.loading;

            return GestureDetector(
              onTap: () => _handleTap(controller),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFE8E3DC), width: 1),
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
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.volume_up_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WaveformBars(
                        controller: _animController,
                        playing: isPlaying || isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
            double scale = playing
                ? (0.4 +
                    0.6 *
                        (0.5 +
                                0.5 *
                                    (controller.value * 2 * 3.14159 +
                                                i * 0.4)
                                        .clamp(-100.0, 100.0)
                                        .abs() %
                                1.0)
                            .clamp(0.0, 1.0))
                : 0.35;

            return Container(
              width: 3,
              height: 32 * _heightRatios[i] * scale,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.85),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ListenToSentenceButton extends StatelessWidget {
  final String sourceId;
  final String audioUrl;
  final String label;

  const _ListenToSentenceButton({
    required this.sourceId,
    required this.audioUrl,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textColor,
          side: const BorderSide(color: Color(0xFFE8E3DC), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textColor,
          ),
        ),
      ),
    );
  }
}