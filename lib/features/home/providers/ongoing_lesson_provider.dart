import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/course/providers/course_provider.dart';

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

    final ongoingLessonInfo =
        await ref.watch(ongoingLessonInfoV2Provider(courseId).future);
    if (ongoingLessonInfo == null || ongoingLessonInfo.nextLesson == null) {
      return null;
    }

    final progress =
        await ref.watch(courseProgressV2Provider(courseId).future);
    final progressPercentage = progress.totalLessons > 0
        ? ((progress.completedLessons / progress.totalLessons) * 100).round()
        : 0;

    final nextLesson = ongoingLessonInfo.nextLesson!;

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
      moduleId: ongoingLessonInfo.module.module.id,
    );
  } catch (e) {
    print('Error getting ongoing lesson data: $e');
    return null;
  }
});
