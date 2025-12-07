import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/course/providers/course_provider.dart';
import 'package:milpress/features/user_progress/providers/user_progress_providers.dart';
import 'package:milpress/features/course/providers/module_provider.dart';
import 'package:milpress/utils/supabase_config.dart';

class OngoingLessonData {
  final String title;
  final int progressPercentage;
  final String studyTime;
  final String timeLeft;
  final String? courseId;
  final String? lessonId;
  final String? moduleId;

  OngoingLessonData({
    required this.title,
    required this.progressPercentage,
    required this.studyTime,
    required this.timeLeft,
    this.courseId,
    this.lessonId,
    this.moduleId,
  });
}

final ongoingLessonProvider = FutureProvider<OngoingLessonData?>((ref) async {
  try {
    // Get the active course
    final activeCourse =
        await ref.watch(activeCourseWithDetailsProvider.future);
    if (activeCourse == null) return null;

    final courseId = activeCourse.course.id;

    // Get the ongoing module for this course
    final ongoingModule =
        await ref.watch(ongoingModuleProvider(courseId).future);
    if (ongoingModule == null) return null;

    // Get course progress to calculate overall progress
    final completedLessons =
        await ref.watch(courseCompletedLessonsProvider(courseId).future);
    final totalLessons = activeCourse.totalLessons;
    final progressPercentage = totalLessons > 0
        ? ((completedLessons / totalLessons) * 100).round()
        : 0;

    // Get the first lesson in the ongoing module
    final currentLesson =
        ongoingModule.lessons.isNotEmpty ? ongoingModule.lessons.first : null;
    if (currentLesson == null) return null;

    // Calculate time left based on course duration and progress
    final courseDurationMinutes = activeCourse.course.durationInMinutes;
    final remainingLessons = totalLessons - completedLessons;
    final estimatedTimePerLesson = courseDurationMinutes / totalLessons;
    final remainingTimeMinutes =
        (remainingLessons * estimatedTimePerLesson).round();

    final hours = remainingTimeMinutes ~/ 60;
    final minutes = remainingTimeMinutes % 60;
    final timeLeft =
        hours > 0 ? "$hours Hours $minutes Minutes" : "$minutes Minutes";

    // Calculate study time (average time per day based on course duration)
    final studyTimeMinutes =
        (courseDurationMinutes / 30).round(); // Assuming 30 days to complete
    final studyTime = "$studyTimeMinutes minutes a day";

    return OngoingLessonData(
      title: "${ongoingModule.module.description}: ${currentLesson.title}",
      progressPercentage: progressPercentage,
      studyTime: studyTime,
      timeLeft: timeLeft,
      courseId: courseId,
      lessonId: currentLesson.id,
      moduleId: ongoingModule.module.id,
    );
  } catch (e) {
    print('Error getting ongoing lesson data: $e');
    return null;
  }
});
