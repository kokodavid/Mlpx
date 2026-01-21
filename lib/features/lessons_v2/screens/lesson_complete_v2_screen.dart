import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/utils/app_colors.dart';
import '../providers/lesson_providers.dart' as lessons_v2;
import '../../course/providers/module_provider.dart';

class LessonCompleteV2Screen extends ConsumerWidget {
  final String lessonId;
  final String moduleId;
  final String lessonTitle;
  final String? timeRemainingLabel;

  const LessonCompleteV2Screen({
    super.key,
    required this.lessonId,
    required this.moduleId,
    required this.lessonTitle,
    this.timeRemainingLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moduleLessonsAsync =
        ref.watch(lessons_v2.moduleLessonsProvider(moduleId));
    final moduleLessons = moduleLessonsAsync.value ?? const [];
    final currentIndex =
        moduleLessons.indexWhere((lesson) => lesson.id == lessonId);
    final safeIndex = currentIndex >= 0 ? currentIndex : 0;
    final totalLessons = moduleLessons.isNotEmpty ? moduleLessons.length : 1;
    final progressLabel = '${safeIndex + 1} of $totalLessons LESSON';
    final nextLesson =
        (safeIndex + 1 < moduleLessons.length) ? moduleLessons[safeIndex + 1] : null;
    final hasNext = nextLesson != null;
    final moduleAsync = ref.watch(moduleFromSupabaseProvider(moduleId));
    final courseId = moduleAsync.value?.module.courseId;

    return Scaffold(
      backgroundColor: AppColors.sandyLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {},
          ),
        ],
        centerTitle: true,
        title: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      lessonTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(
                          '/lesson-attempt',
                          extra: {'lessonId': lessonId},
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryColor,
                          side: const BorderSide(
                            color: AppColors.primaryColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.replay),
                        label: const Text('Review Lesson'),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                progressLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.correctAnswerColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'You are almost there',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.copBlue,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: hasNext
                      ? () => context.push(
                            '/lesson-attempt',
                            extra: {'lessonId': nextLesson!.id},
                          )
                      : (courseId == null || courseId.isEmpty)
                          ? null
                          : () => context.go('/course/$courseId'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasNext
                        ? AppColors.primaryColor
                        : AppColors.correctAnswerColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        (hasNext
                                ? AppColors.primaryColor
                                : AppColors.correctAnswerColor)
                            .withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hasNext ? 'Next Lesson' : 'Finish Module',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasNext) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward),
                      ],
                    ],
                  ),
                ),
              ),
              if (timeRemainingLabel != null &&
                  timeRemainingLabel!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    timeRemainingLabel!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textColor,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (hasNext)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Upcoming lesson',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nextLesson!.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.copBlue,
                        ),
                      ),
                      if (timeRemainingLabel != null &&
                          timeRemainingLabel!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          timeRemainingLabel!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
