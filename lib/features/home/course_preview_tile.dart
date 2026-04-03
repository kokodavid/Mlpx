import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/lessons_v2/providers/lesson_audio_providers.dart';
import 'package:milpress/features/lessons_v2/services/lesson_audio_controller.dart';
import 'package:milpress/utils/app_colors.dart';

class CoursePreviewTile extends ConsumerWidget {
  final String sourceId;
  final String url;
  final String title;
  final String subtitle;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const CoursePreviewTile({
    super.key,
    required this.sourceId,
    required this.url,
    this.title = 'Tap to listen',
    this.subtitle = 'Course Preview',
    this.margin = EdgeInsets.zero,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(lessonAudioControllerProvider);

    return ValueListenableBuilder<LessonAudioState>(
      valueListenable: controller.state,
      builder: (context, state, _) {
        final isActive = state.sourceId == sourceId;
        final isLoading = isActive && state.status == LessonAudioStatus.loading;
        final isPlaying = isActive && state.status == LessonAudioStatus.playing;

        return Container(
          width: double.infinity,
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (url.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No preview audio available yet.'),
              ),
            );
            return;
          }
          controller.playUrl(url, sourceId: sourceId);
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.copBlue,
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10131A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
