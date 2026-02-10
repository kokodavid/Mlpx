import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../course_models/course_model.dart';
import '../course_models/complete_course_model.dart';
import '../services/course_service.dart';
import 'package:flutter/foundation.dart';
import 'package:milpress/features/user_progress/providers/course_progress_providers.dart';
import 'package:milpress/utils/supabase_config.dart';
import 'package:milpress/features/user_progress/models/course_progress_model.dart';
import 'package:milpress/features/user_progress/providers/user_progress_providers.dart';
import 'package:milpress/features/assessment/providers/assessment_result_provider.dart';
import 'package:milpress/features/lessons_v2/models/lesson_models.dart';
import 'package:milpress/features/lessons_v2/providers/lesson_providers.dart'
    as lessons_v2;

final courseServiceProvider = Provider<CourseService>((ref) {
  final supabase = Supabase.instance.client;
  return CourseService(supabase);
});

String _normalizeAssessmentKey(String value) => value.trim().toLowerCase();

bool _isAssessmentModule(ModuleWithLessons module) {
  final moduleType = module.module.moduleType.trim().toLowerCase();
  final hasAssessmentId =
      module.module.assessmentId?.trim().isNotEmpty ?? false;
  return moduleType == 'assessment' || hasAssessmentId;
}

bool _isAssessmentModuleCompleted(
  ModuleWithLessons module,
  Set<String> completedAssessmentKeys,
  bool hasCompletedAnyAssessment,
) {
  final assessmentId = module.module.assessmentId?.trim();
  if (assessmentId != null && assessmentId.isNotEmpty) {
    return completedAssessmentKeys
        .contains(_normalizeAssessmentKey(assessmentId));
  }
  return hasCompletedAnyAssessment;
}

Future<int> _fetchTotalLessonsV2(
  Ref ref,
  List<ModuleWithLessons> modules,
) async {
  if (modules.isEmpty) {
    return 0;
  }

  final lessonCounts = await Future.wait(modules.map((module) async {
    final moduleId = module.module.id;
    if (moduleId.isEmpty) {
      return 0;
    }
    final lessons = await ref.watch(
      lessons_v2.moduleLessonsProvider(moduleId).future,
    );
    return lessons.length;
  }));

  return lessonCounts.fold<int>(0, (sum, count) => sum + count);
}

// Provider for courses with their module and lesson counts
final coursesWithDetailsProvider =
    FutureProvider<List<CourseWithDetails>>((ref) async {
  final courseService = ref.watch(courseServiceProvider);
  final courses = await courseService.getCourses();

  print('Fetched courses from DB:');
  for (final course in courses) {
    print('  - ${course.title} (id: ${course.id}, level: ${course.level})');
  }

  final coursesWithDetails = <CourseWithDetails>[];
  for (final course in courses) {
    try {
      final completeCourse = await courseService.getCompleteCourse(course.id);
      final totalModules = completeCourse.modules.length;
      final totalLessons =
          await _fetchTotalLessonsV2(ref, completeCourse.modules);
      print(
          '  -> ${course.title}: $totalModules modules, $totalLessons lessons');
      coursesWithDetails.add(CourseWithDetails(
        course: course,
        totalModules: totalModules,
        totalLessons: totalLessons,
      ));
    } catch (e) {
      print('  -> ${course.title}: 0 modules, 0 lessons (not cached)');
      coursesWithDetails.add(CourseWithDetails(
        course: course,
        totalModules: 0,
        totalLessons: 0,
      ));
    }
  }
  print('Total coursesWithDetails: ${coursesWithDetails.length}');
  return coursesWithDetails;
});

// Provider for the active course with details (not completed, lowest level)
final activeCourseWithDetailsProvider =
    FutureProvider<CourseWithDetails?>((ref) async {
  final coursesWithDetails = await ref.watch(coursesWithDetailsProvider.future);
  // Sort by level ascending
  final sortedCourses = List<CourseWithDetails>.from(coursesWithDetails)
    ..sort((a, b) => a.course.level.compareTo(b.course.level));
  // Try to find the lowest-level, not completed course
  for (final courseWithDetails in sortedCourses) {
    final course = courseWithDetails.course;
    final completedModules =
        await ref.watch(completedModulesProvider(course.id).future);
    final totalModules = courseWithDetails.totalModules;
    final completedModulesCount =
        completedModules.values.where((completed) => completed).length;
    if (completedModulesCount < totalModules) {
      return courseWithDetails;
    }
  }
  // If all are completed, try to promote the first upcoming course (by level, not completed)
  for (final courseWithDetails in sortedCourses) {
    final course = courseWithDetails.course;
    final completedModules =
        await ref.watch(completedModulesProvider(course.id).future);
    final totalModules = courseWithDetails.totalModules;
    final completedModulesCount =
        completedModules.values.where((completed) => completed).length;
    if (totalModules == 0 || completedModulesCount < totalModules) {
      return courseWithDetails;
    }
  }
  return null;
});

// Provider for completed courses with details
final completedCoursesWithDetailsProvider =
    FutureProvider<List<CourseWithDetails>>((ref) async {
  final coursesWithDetails = await ref.watch(coursesWithDetailsProvider.future);
  final user = SupabaseConfig.currentUser;
  final userId = user?.id;
  final completedCourses = <CourseWithDetails>[];

  if (userId == null) {
    // If no user, return empty list
    return completedCourses;
  }

  // Check each course to see if it's completed
  for (final courseWithDetails in coursesWithDetails) {
    final course = courseWithDetails.course;
    final completedModules =
        await ref.watch(completedModulesProvider(course.id).future);
    final totalModules = courseWithDetails.totalModules;
    final completedModulesCount =
        completedModules.values.where((completed) => completed).length;
    if (completedModulesCount >= totalModules && totalModules > 0) {
      completedCourses.add(courseWithDetails);
    }
  }
  completedCourses.sort((a, b) => a.course.level.compareTo(b.course.level));
  return completedCourses;
});

// Provider for upcoming courses with details (not completed, not active)
final upcomingCoursesWithDetailsProvider =
    FutureProvider<List<CourseWithDetails>>((ref) async {
  final coursesWithDetails = await ref.watch(coursesWithDetailsProvider.future);
  final activeCourse = await ref.watch(activeCourseWithDetailsProvider.future);
  final activeLevel = activeCourse?.course.level ?? 0;
  final upcomingCourses = <CourseWithDetails>[];

  for (final courseWithDetails in coursesWithDetails) {
    final course = courseWithDetails.course;
    if (course.level <= activeLevel) continue; // Only higher levels than active
    final completedModules =
        await ref.watch(completedModulesProvider(course.id).future);
    final totalModules = courseWithDetails.totalModules;
    final completedModulesCount =
        completedModules.values.where((completed) => completed).length;
    if (totalModules == 0 || completedModulesCount < totalModules) {
      upcomingCourses.add(courseWithDetails);
    }
  }
  upcomingCourses.sort((a, b) => a.course.level.compareTo(b.course.level));
  return upcomingCourses;
});

final courseByIdProvider =
    FutureProvider.family<CourseModel, String>((ref, id) async {
  final courseService = ref.watch(courseServiceProvider);
  return courseService.getCourseById(id);
});

final completeCourseProvider =
    FutureProvider.family<CompleteCourseModel, String>((ref, courseId) async {
  final courseService = ref.watch(courseServiceProvider);
  final completeCourse = await courseService.getCompleteCourse(courseId);

  // Ensure modules are sorted by position when retrieved from Supabase
  final sortedModules = List<ModuleWithLessons>.from(completeCourse.modules)
    ..sort((a, b) => a.module.position.compareTo(b.module.position));

  // Ensure lessons within each module are also sorted by position
  for (final module in sortedModules) {
    module.lessons.sort((a, b) => a.position.compareTo(b.position));
  }

  return CompleteCourseModel(
    course: completeCourse.course,
    modules: sortedModules,
    lastUpdated: completeCourse.lastUpdated,
  );
});

final courseRefreshProvider =
    Provider.family<void Function(), String>((ref, courseId) {
  return () {
    // Invalidate the complete course provider to force a refresh
    ref.invalidate(completeCourseProvider(courseId));
  };
});

// Provider to get the first module (position 1) for ongoing module card
final firstModuleProvider =
    FutureProvider.family<ModuleWithLessons?, String>((ref, courseId) async {
  final completeCourse =
      await ref.watch(completeCourseProvider(courseId).future);
  if (completeCourse.modules.isNotEmpty) {
    // Return the first module (position 1) instead of the last
    return completeCourse.modules.first;
  }
  return null;
});

// Provider to get completed modules for a course
final completedModulesProvider =
    FutureProvider.family<Map<String, bool>, String>((ref, courseId) async {
  final completeCourse =
      await ref.watch(completeCourseProvider(courseId).future);
  final latestAssessmentResult =
      await ref.watch(latestAssessmentResultProvider.future);
  final hasCompletedAnyAssessment = latestAssessmentResult != null;
  final completedAssessmentKeys = latestAssessmentResult?.stageScores.keys
          .map(_normalizeAssessmentKey)
          .toSet() ??
      <String>{};
  final moduleCompletion = await Future.wait(
    completeCourse.modules.map((module) async {
      final moduleId = module.module.id;
      if (moduleId.isEmpty) {
        return MapEntry(moduleId, false);
      }
      if (_isAssessmentModule(module)) {
        final isCompleted = _isAssessmentModuleCompleted(
          module,
          completedAssessmentKeys,
          hasCompletedAnyAssessment,
        );
        return MapEntry(moduleId, isCompleted);
      }
      final lessons = await ref.watch(
        lessons_v2.moduleLessonsProvider(moduleId).future,
      );
      if (lessons.isEmpty) {
        return MapEntry(moduleId, false);
      }
      final completedLessonIds = await ref.watch(
        lessons_v2.completedLessonIdsV2Provider(moduleId).future,
      );
      final isCompleted = completedLessonIds.length >= lessons.length;
      return MapEntry(moduleId, isCompleted);
    }),
  );

  return Map<String, bool>.fromEntries(moduleCompletion);
});

// Provider to get the ongoing module (first incomplete module)
final ongoingModuleProvider =
    FutureProvider.family<ModuleWithLessons?, String>((ref, courseId) async {
  final completeCourse =
      await ref.watch(completeCourseProvider(courseId).future);
  final completedModules =
      await ref.watch(completedModulesProvider(courseId).future);

  for (final module in completeCourse.modules) {
    final isCompleted = completedModules[module.module.id] ?? false;
    if (!isCompleted) {
      return module;
    }
  }

  return null;
});

class _ModuleLessonInfo {
  final String moduleId;
  final List<String> lessonIds;

  const _ModuleLessonInfo({
    required this.moduleId,
    required this.lessonIds,
  });
}

// Course progress stats based on lessons_v2 and lesson_completion.
final courseProgressV2Provider =
    FutureProvider.family<CourseProgressStats, String>((ref, courseId) async {
  final completeCourse =
      await ref.watch(completeCourseProvider(courseId).future);
  final modules = completeCourse.modules;
  final totalModules = modules.length;
  final lessonModules = modules
      .where((module) => !_isAssessmentModule(module))
      .toList(growable: false);
  final assessmentModules =
      modules.where(_isAssessmentModule).toList(growable: false);

  final moduleLessons = await Future.wait(lessonModules.map((module) async {
    final lessons = await ref.watch(
      lessons_v2.moduleLessonsProvider(module.module.id).future,
    );
    final lessonIds = lessons
        .map((lesson) => lesson.id)
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    return _ModuleLessonInfo(
      moduleId: module.module.id,
      lessonIds: lessonIds,
    );
  }));

  final totalLessons = moduleLessons.fold<int>(
    0,
    (sum, module) => sum + module.lessonIds.length,
  );

  final completedModuleMap =
      await ref.watch(completedModulesProvider(courseId).future);
  final completedLessonModules = lessonModules
      .where((module) => completedModuleMap[module.module.id] == true)
      .length;
  final completedAssessmentModules = assessmentModules
      .where((module) => completedModuleMap[module.module.id] == true)
      .length;
  final completedModules = completedLessonModules + completedAssessmentModules;

  final allLessonIds = moduleLessons
      .expand((module) => module.lessonIds)
      .toList(growable: false);

  Set<String> completedLessonIds = {};
  final userId = SupabaseConfig.currentUser?.id;
  if (userId != null && allLessonIds.isNotEmpty) {
    try {
      final response = await SupabaseConfig.client
          .from('lesson_completion')
          .select('lesson_id')
          .eq('user_id', userId)
          .inFilter('lesson_id', allLessonIds);
      completedLessonIds = (response as List)
          .map((row) => row['lesson_id'] as String?)
          .whereType<String>()
          .toSet();
    } catch (e) {
      debugPrint('courseProgressV2Provider: failed to load completion: $e');
    }
  }

  final completedLessons = completedLessonIds.length;
  double completionPercentage;
  if (assessmentModules.isNotEmpty && lessonModules.isNotEmpty) {
    // Weight lesson-module completion to 80% and assessment-module completion to 20%.
    final lessonModuleProgress = completedLessonModules / lessonModules.length;
    final assessmentModuleProgress =
        completedAssessmentModules / assessmentModules.length;
    completionPercentage =
        ((lessonModuleProgress * 0.8) + (assessmentModuleProgress * 0.2)) * 100;
  } else if (assessmentModules.isNotEmpty) {
    completionPercentage =
        (completedAssessmentModules / assessmentModules.length) * 100;
  } else {
    completionPercentage =
        totalLessons > 0 ? (completedLessons / totalLessons) * 100 : 0.0;
  }
  completionPercentage = completionPercentage.clamp(0.0, 100.0).toDouble();

  return CourseProgressStats(
    totalModules: totalModules,
    completedModules: completedModules,
    totalLessons: totalLessons,
    completedLessons: completedLessons,
    totalQuizzes: 0,
    completedQuizzes: 0,
    courseCompletionPercentage: completionPercentage,
    totalLessonModules: lessonModules.length,
    completedLessonModules: completedLessonModules,
    totalAssessmentModules: assessmentModules.length,
    completedAssessmentModules: completedAssessmentModules,
  );
});

class OngoingLessonInfo {
  final ModuleWithLessons module;
  final LessonDefinition? nextLesson;

  const OngoingLessonInfo({
    required this.module,
    required this.nextLesson,
  });
}

final ongoingLessonInfoV2Provider =
    FutureProvider.family<OngoingLessonInfo?, String>((ref, courseId) async {
  final completeCourse =
      await ref.watch(completeCourseProvider(courseId).future);

  for (final module in completeCourse.modules) {
    // Skip assessment modules — they have their own flow
    if (module.module.isAssessment) {
      continue;
    }

    final lessons = await ref.watch(
      lessons_v2.moduleLessonsProvider(module.module.id).future,
    );
    if (lessons.isEmpty) {
      continue;
    }

    final completedLessonIds = await ref.watch(
      lessons_v2.completedLessonIdsV2Provider(module.module.id).future,
    );

    LessonDefinition? nextLesson;
    for (final lesson in lessons) {
      if (!completedLessonIds.contains(lesson.id)) {
        nextLesson = lesson;
        break;
      }
    }

    if (nextLesson != null) {
      return OngoingLessonInfo(module: module, nextLesson: nextLesson);
    }
  }

  return null;
});

// Helper class to combine course with its module and lesson counts
class CourseWithDetails {
  final CourseModel course;
  final int totalModules;
  final int totalLessons;

  CourseWithDetails({
    required this.course,
    required this.totalModules,
    required this.totalLessons,
  });
}

final refreshCompleteCourseProvider =
    FutureProvider.family<CompleteCourseModel, String>((ref, courseId) async {
  final courseService = ref.watch(courseServiceProvider);
  return courseService.getCompleteCourse(courseId);
});

// Course Progress Statistics Model
class CourseProgressStats {
  final int totalModules;
  final int completedModules;
  final int totalLessons;
  final int completedLessons;
  final int totalQuizzes;
  final int completedQuizzes;
  final double courseCompletionPercentage;
  final int totalLessonModules;
  final int completedLessonModules;
  final int totalAssessmentModules;
  final int completedAssessmentModules;

  CourseProgressStats({
    required this.totalModules,
    required this.completedModules,
    required this.totalLessons,
    required this.completedLessons,
    required this.totalQuizzes,
    required this.completedQuizzes,
    required this.courseCompletionPercentage,
    required this.totalLessonModules,
    required this.completedLessonModules,
    required this.totalAssessmentModules,
    required this.completedAssessmentModules,
  });
}

// Provider to trigger course progress refresh
final courseProgressRefreshProvider = StateProvider<int>((ref) => 0);

// Stream-based refresh mechanism for more efficient updates
final courseProgressRefreshStreamProvider =
    StreamProvider.family<void, String>((ref, courseId) async* {
  // Watch the refresh provider
  ref.watch(courseProgressRefreshProvider);

  // Yield to trigger stream update
  yield null;

  // Invalidate all related providers
  ref.invalidate(completedModulesProvider(courseId));
  ref.invalidate(ongoingModuleProvider(courseId));
  ref.invalidate(courseProgressV2Provider(courseId));
  ref.invalidate(ongoingLessonInfoV2Provider(courseId));

  debugPrint(
      'CourseProgressRefreshStream: Refreshed data for course $courseId');
});

// Provider to check and update course completion status
final checkAndUpdateCourseCompletionProvider =
    FutureProvider.family<void, String>((ref, courseId) async {
  final completeCourse =
      await ref.watch(completeCourseProvider(courseId).future);
  final completedModules =
      await ref.watch(completedModulesProvider(courseId).future);

  final totalModules = completeCourse.modules.length;
  final completedModulesCount =
      completedModules.values.where((completed) => completed).length;

  // If all modules are completed, mark the course as completed
  if (totalModules > 0 && completedModulesCount >= totalModules) {
    final courseProgressId =
        await ref.watch(getOrCreateCourseProgressProvider(courseId).future);
    final existingCourseProgress =
        await ref.watch(courseProgressByIdProvider(courseProgressId).future);

    if (existingCourseProgress != null && !existingCourseProgress.isCompleted) {
      final updatedCourseProgress = CourseProgressModel(
        id: existingCourseProgress.id,
        userId: existingCourseProgress.userId,
        courseId: existingCourseProgress.courseId,
        startedAt: existingCourseProgress.startedAt,
        completedAt: DateTime.now(),
        currentModuleId: existingCourseProgress.currentModuleId,
        currentLessonId: existingCourseProgress.currentLessonId,
        isCompleted: true,
        createdAt: existingCourseProgress.createdAt,
        updatedAt: DateTime.now(),
        needsSync: true,
      );

      // Save the updated course progress
      await ref.read(saveCourseProgressProvider(updatedCourseProgress).future);
      debugPrint('Course $courseId marked as completed');
    }
  }
});

// Enhanced provider that automatically refreshes all course-related data
final autoRefreshCourseDataProvider =
    FutureProvider.family<void, String>((ref, courseId) async {
  // Watch the refresh provider to trigger updates
  ref.watch(courseProgressRefreshProvider);

  // Invalidate all related providers to ensure fresh data
  ref.invalidate(completedModulesProvider(courseId));
  ref.invalidate(ongoingModuleProvider(courseId));
  ref.invalidate(courseProgressV2Provider(courseId));
  ref.invalidate(ongoingLessonInfoV2Provider(courseId));

  debugPrint(
      'AutoRefreshCourseDataProvider: Refreshed all data for course $courseId');
});

// Assessment Course Suggestions Provider
final assessmentCourseSuggestionsProvider =
    FutureProvider<Map<String, List<CourseModel>>>((ref) async {
  final courseService = ref.watch(courseServiceProvider);

  // Define the course types that correspond to assessment stages
  const assessmentCourseTypes = ['Letter', 'Word', 'Sentence', 'Writing'];

  try {
    final coursesByType =
        await courseService.getCoursesByTypes(assessmentCourseTypes);
    debugPrint('Assessment course suggestions fetched:');
    for (final entry in coursesByType.entries) {
      debugPrint('  ${entry.key}: ${entry.value.length} courses');
    }
    return coursesByType;
  } catch (e) {
    debugPrint('Error fetching assessment course suggestions: $e');
    return {};
  }
});
