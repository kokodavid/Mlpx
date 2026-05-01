import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/app_colors.dart';

import '../../providers/lesson_audio_providers.dart';
import '../../services/lesson_audio_controller.dart';

class LessonWaveformBars extends StatelessWidget {
  final AnimationController controller;
  final bool playing;

  static const List<double> _heightRatios = [
    0.30, 0.55, 0.75, 0.90, 0.65, 1.00, 0.80, 0.55, 0.95, 0.70,
    0.45, 0.85, 0.60, 1.00, 0.75, 0.50, 0.90, 0.65, 0.40, 0.80,
    0.55, 0.70, 0.95, 0.60, 0.35, 0.75, 0.50, 0.88, 0.65, 0.40,
  ];

  const LessonWaveformBars({
    super.key,
    required this.controller,
    required this.playing,
  });

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
                                        (controller.value * 2 * math.pi +
                                                i * 0.4)
                                            .abs()) %
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

class LessonWaveformPlayer extends ConsumerStatefulWidget {
  final String sourceId;
  final String audioUrl;
  final Color borderColor;
  final Color backgroundColor;

  const LessonWaveformPlayer({
    super.key,
    required this.sourceId,
    required this.audioUrl,
    this.borderColor = const Color(0xFFE8E3DC),
    this.backgroundColor = Colors.white,
  });

  @override
  ConsumerState<LessonWaveformPlayer> createState() =>
      _LessonWaveformPlayerState();
}

class _LessonWaveformPlayerState extends ConsumerState<LessonWaveformPlayer>
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

  Future<void> _handleTap(LessonAudioController controller) async {
    final state = controller.state.value;
    if (state.sourceId == widget.sourceId &&
        state.status == LessonAudioStatus.playing) {
      await controller.stop();
      return;
    }
    await controller.playUrl(widget.audioUrl, sourceId: widget.sourceId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(lessonAudioControllerProvider);

    return ValueListenableBuilder<LessonAudioState>(
      valueListenable: controller.state,
      builder: (context, state, _) {
        final isActive = state.sourceId == widget.sourceId;
        final isPlaying = isActive && state.status == LessonAudioStatus.playing;
        final isLoading = isActive && state.status == LessonAudioStatus.loading;

        return GestureDetector(
          onTap: () => _handleTap(controller),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.borderColor, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LessonWaveformBars(
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
  }
}
