import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/lessons_v2/providers/lesson_audio_providers.dart';
import 'package:milpress/features/lessons_v2/services/lesson_audio_controller.dart';

class AudioPreviewWidget extends ConsumerWidget {
  final String? soundUrl;
  final String sourceId;

  const AudioPreviewWidget({
    super.key,
    required this.soundUrl,
    required this.sourceId,
  });

  bool get _hasAudio => soundUrl != null && soundUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_hasAudio) {
      // No audio — render identical visual, tap does nothing
      return _AudioWidget(onTap: null);
    }

    final audioController = ref.watch(lessonAudioControllerProvider);

    return ValueListenableBuilder<LessonAudioState>(
      valueListenable: audioController.state,
      builder: (context, audioState, _) {
        final isThisSource = audioState.sourceId == sourceId;
        final isLoading =
            isThisSource && audioState.status == LessonAudioStatus.loading;
        final isPlaying =
            isThisSource && audioState.status == LessonAudioStatus.playing;

        return _AudioWidget(
          isLoading: isLoading,
          isPlaying: isPlaying,
          onTap: () async {
            if (isPlaying) {
              await audioController.stop();
            } else {
              await audioController.playUrl(soundUrl!, sourceId: sourceId);
            }
          },
        );
      },
    );
  }
}


// _AudioWidget — the pure visual, exactly as in the screenshot

class _AudioWidget extends StatelessWidget {
  final bool isLoading;
  final bool isPlaying;
  final VoidCallback? onTap;

  const _AudioWidget({
    this.isLoading = false,
    this.isPlaying = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // "Introduction Audio"
          const Text(
            'Introduction Audio',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),

          // white inner container
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // orange circle — loader / stop / speaker
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8844A),
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isLoading
                          ? const Padding(
                        key: ValueKey('loading'),
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                      )
                          : Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.volume_up_rounded,
                        key: ValueKey(isPlaying ? 'pause' : 'speaker'),
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // "Tap to preview this course"
                  const Text(
                    'Tap to preview this course',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}