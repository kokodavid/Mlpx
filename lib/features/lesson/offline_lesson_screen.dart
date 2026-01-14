import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/lesson/providers/lesson_download_provider.dart';
import 'package:milpress/features/lesson/providers/lesson_video_provider.dart';
import 'package:milpress/features/lesson/lesson_widgets/video_player_widget.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:video_player/video_player.dart';

class OfflineLessonScreen extends ConsumerWidget {
  final String lessonId;

  const OfflineLessonScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(offlineLessonProvider(lessonId));

    return lessonAsync.when(
      data: (lesson) {
        if (lesson == null) {
          return const Scaffold(
            body: Center(
              child: Text('Lesson not available offline.'),
            ),
          );
        }

        final videoUrl = lesson.videoUrl ?? '';
        final videoControllerAsync =
            ref.watch(lessonVideoPlayerControllerProvider(videoUrl));

        return Scaffold(
          backgroundColor: AppColors.sandyLight,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            centerTitle: true,
            title: Text(
              lesson.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (videoUrl.isNotEmpty) ...[
                  videoControllerAsync.when(
                    data: (controller) => Column(
                      children: [
                        VideoPlayerWidget(
                          videoUrl: videoUrl,
                          externalController: controller,
                        ),
                        const SizedBox(height: 12),
                        _OfflineVideoControls(controller: controller),
                      ],
                    ),
                    loading: () => const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox(
                      height: 200,
                      child: Center(child: Text('Error loading offline video')),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('No offline video available'),
                    ),
                  ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${lesson.durationMinutes} min • ${lesson.quizzes.length} quiz${lesson.quizzes.length == 1 ? '' : 'es'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (lesson.description != null &&
                    lesson.description!.isNotEmpty) ...[
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF232B3A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lesson.description!,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Error loading offline lesson')),
      ),
    );
  }
}

class _OfflineVideoControls extends StatelessWidget {
  final VideoPlayerController controller;

  const _OfflineVideoControls({required this.controller});

  void _seekRelative(Duration offset) {
    final newPosition = controller.value.position + offset;
    final duration = controller.value.duration;
    controller.seekTo(
      newPosition < Duration.zero
          ? Duration.zero
          : (newPosition > duration ? duration : newPosition),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, VideoPlayerValue value, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_10, color: Colors.black, size: 28),
              onPressed: () => _seekRelative(const Duration(seconds: -10)),
            ),
            IconButton(
              icon: Icon(
                value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                color: Colors.black,
                size: 42,
              ),
              onPressed: () {
                if (value.isPlaying) {
                  controller.pause();
                } else {
                  controller.play();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.forward_10, color: Colors.black, size: 28),
              onPressed: () => _seekRelative(const Duration(seconds: 10)),
            ),
          ],
        );
      },
    );
  }
}
