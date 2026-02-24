import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/course/providers/course_provider.dart';

// ---------------------------------------------------------------------------
// CourseCardState — drives the CTA button label, style, and tap behaviour
// ---------------------------------------------------------------------------
enum CourseCardState {
  // Active course, zero modules completed → orange "Start Course" button
  startCourse,
  // Active course, at least one module completed but not all → orange "Continue"
  continueCourse,
  // Course level is higher than the current active course → grey "Coming Next"
  comingNext,
  // All modules completed → green "Review Course"
  reviewCourse,
}

// ---------------------------------------------------------------------------
// CourseCardViewModel — everything a CourseCardWidget needs
// ---------------------------------------------------------------------------
class CourseCardViewModel {
  final CourseWithDetails courseWithDetails;
  final CourseCardState state;

  /// The next incomplete lessonId — non-null for startCourse / continueCourse
  final String? nextLessonId;

  /// The next incomplete moduleId — non-null for startCourse / continueCourse
  final String? nextModuleId;

  const CourseCardViewModel({
    required this.courseWithDetails,
    required this.state,
    this.nextLessonId,
    this.nextModuleId,
  });
}

// ---------------------------------------------------------------------------
// homeV2Provider — resolves the full list of CourseCardViewModels
// ---------------------------------------------------------------------------
final homeV2Provider =
FutureProvider<List<CourseCardViewModel>>((ref) async {
  // Watch courseProgressRefreshProvider — the same StateProvider<int> that
  // course_details_screen.dart increments after every lesson completion.
  // This causes homeV2Provider to re-run automatically whenever progress
  // changes, keeping the home UI in sync without any manual refresh.
  ref.watch(courseProgressRefreshProvider);

  // 1. Fetch all courses sorted by level ascending
  final allCourses = await ref.watch(coursesWithDetailsProvider.future);
  final sorted = List<CourseWithDetails>.from(allCourses)
    ..sort((a, b) => a.course.level.compareTo(b.course.level));

  if (sorted.isEmpty) return [];

  // 2. Use courseDetailsProgressProvider — the same provider CourseDetailsScreen
  //    uses — because it reads from the correct `lesson_completion` table and
  //    correctly accounts for both lesson modules and assessment modules.
  //    Register all watches synchronously before any await.
  final progressFutures = sorted
      .map((c) => ref.watch(courseDetailsProgressProvider(c.course.id).future))
      .toList();

  final ongoingFutures = sorted
      .map((c) => ref.watch(ongoingLessonInfoV2Provider(c.course.id).future))
      .toList();

  // Now await them all
  final progressDataList = await Future.wait(progressFutures);
  final ongoingInfos = await Future.wait(ongoingFutures);

  // 3. Determine which course is the "active" one using courseDetailsProgress
  CourseWithDetails? activeCourse;
  for (var i = 0; i < sorted.length; i++) {
    final stats = progressDataList[i].stats;
    if (stats.totalModules == 0 ||
        stats.completedModules < stats.totalModules) {
      activeCourse = sorted[i];
      break;
    }
  }

  final activeLevel = activeCourse?.course.level ?? 0;

  // 4. Build a CourseCardViewModel for each course
  final viewModels = <CourseCardViewModel>[];

  for (var i = 0; i < sorted.length; i++) {
    final courseWithDetails = sorted[i];
    final course = courseWithDetails.course;
    final stats = progressDataList[i].stats;
    final totalModules = stats.totalModules;
    final completedCount = stats.completedModules;

    CourseCardState cardState;
    String? nextLessonId;
    String? nextModuleId;

    final allCompleted = totalModules > 0 && completedCount >= totalModules;

    if (allCompleted) {
      cardState = CourseCardState.reviewCourse;
    } else if (course.level > activeLevel) {
      cardState = CourseCardState.comingNext;
    } else if (completedCount == 0) {
      cardState = CourseCardState.startCourse;
      nextLessonId = ongoingInfos[i]?.nextLesson?.id;
      nextModuleId = ongoingInfos[i]?.module.module.id;
    } else {
      cardState = CourseCardState.continueCourse;
      nextLessonId = ongoingInfos[i]?.nextLesson?.id;
      nextModuleId = ongoingInfos[i]?.module.module.id;
    }

    viewModels.add(CourseCardViewModel(
      courseWithDetails: courseWithDetails,
      state: cardState,
      nextLessonId: nextLessonId,
      nextModuleId: nextModuleId,
    ));
  }

  return viewModels;
});