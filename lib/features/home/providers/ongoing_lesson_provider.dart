import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/course/providers/course_provider.dart';
import 'package:milpress/features/user_progress/providers/course_progress_providers.dart';
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

    final ongoingModule =
        await ref.watch(ongoingModuleProvider(courseId).future);
    if (ongoingModule == null) return null;

    final sortedLessons = List.of(ongoingModule.lessons)
      ..sort((a, b) {
        final positionCompare = a.position.compareTo(b.position);
        if (positionCompare != 0) {
          return positionCompare;
        }
        return a.id.compareTo(b.id);
      });
    if (sortedLessons.isEmpty) return null;

    // Get course progress to calculate overall progress
    final completedLessons =
        await ref.watch(courseCompletedLessonsProvider(courseId).future);
    final totalLessons = activeCourse.totalLessons;
    final progressPercentage = totalLessons > 0
        ? ((completedLessons / totalLessons) * 100).round()
        : 0;

    // Find the next lesson based on Supabase progress for this module
    Set<String> completedLessonIds = {};
    final userId = SupabaseConfig.currentUser?.id;
    if (userId != null) {
      try {
        final response = await SupabaseConfig.client
            .from('lesson_progress')
            .select('lesson_id')
            .eq('user_id', userId)
            .eq('module_id', ongoingModule.module.id)
            .eq('status', 'completed');

        if (response is List) {
          completedLessonIds = response
              .map((row) => row['lesson_id'] as String?)
              .whereType<String>()
              .toSet();
        }
      } catch (e) {
        print('Error fetching lesson progress for ongoing lesson: $e');
      }
    }

    final nextLesson = sortedLessons.firstWhere(
      (lesson) => !completedLessonIds.contains(lesson.id),
      orElse: () => sortedLessons.first,
    );

    // Display total course duration
    final courseDurationMinutes = activeCourse.course.durationInMinutes;
    final hours = courseDurationMinutes ~/ 60;
    final minutes = courseDurationMinutes % 60;
    final timeLeft =
        hours > 0 ? "$hours Hours $minutes Minutes" : "$minutes Minutes";

    // Calculate study time (average time per day based on course duration)
    final studyTimeMinutes =
        (courseDurationMinutes / 30).round(); // Assuming 30 days to complete
    final studyTime = "$studyTimeMinutes minutes a day";

    return OngoingLessonData(
      title: nextLesson.title,
      progressPercentage: progressPercentage,
      studyTime: studyTime,
      timeLeft: timeLeft,
      courseId: courseId,
      lessonId: nextLesson.id,
      moduleId: ongoingModule.module.id,
    );
  } catch (e) {
    print('Error getting ongoing lesson data: $e');
    return null;
  }
});
