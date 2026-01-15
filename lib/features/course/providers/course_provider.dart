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

final courseServiceProvider = Provider<CourseService>((ref) {
  final supabase = Supabase.instance.client;
  return CourseService(supabase);
});

// Provider for courses with their module and lesson counts
final coursesWithDetailsProvider = FutureProvider<List<CourseWithDetails>>((ref) async {
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
      final totalLessons = completeCourse.modules.fold(0, (sum, module) => sum + module.lessons.length);
      print('  -> ${course.title}: $totalModules modules, $totalLessons lessons');
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
final activeCourseWithDetailsProvider = FutureProvider<CourseWithDetails?>((ref) async {
  final coursesWithDetails = await ref.watch(coursesWithDetailsProvider.future);
  // Sort by level ascending
  final sortedCourses = List<CourseWithDetails>.from(coursesWithDetails)
    ..sort((a, b) => a.course.level.compareTo(b.course.level));
  // Try to find the lowest-level, not completed course
  for (final courseWithDetails in sortedCourses) {
    final course = courseWithDetails.course;
    final completedModules = await ref.watch(completedModulesProvider(course.id).future);
    final totalModules = courseWithDetails.totalModules;
    final completedModulesCount = completedModules.values.where((completed) => completed).length;
    if (completedModulesCount < totalModules) {
      return courseWithDetails;
    }
  }
  // If all are completed, try to promote the first upcoming course (by level, not completed)
  for (final courseWithDetails in sortedCourses) {
    final course = courseWithDetails.course;
    final completedModules = await ref.watch(completedModulesProvider(course.id).future);
    final totalModules = courseWithDetails.totalModules;
    final completedModulesCount = completedModules.values.where((completed) => completed).length;
    if (totalModules == 0 || completedModulesCount < totalModules) {
      return courseWithDetails;
    }
  }
  return null;
});

// Provider for completed courses with details
final completedCoursesWithDetailsProvider = FutureProvider<List<CourseWithDetails>>((ref) async {
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
    final completedModules = await ref.watch(completedModulesProvider(course.id).future);
    final totalModules = courseWithDetails.totalModules;
    final completedModulesCount = completedModules.values.where((completed) => completed).length;
    if (completedModulesCount >= totalModules && totalModules > 0) {
      completedCourses.add(courseWithDetails);
    }
  }
  completedCourses.sort((a, b) => a.course.level.compareTo(b.course.level));
  return completedCourses;
});

// Provider for upcoming courses with details (not completed, not active)
final upcomingCoursesWithDetailsProvider = FutureProvider<List<CourseWithDetails>>((ref) async {
  final coursesWithDetails = await ref.watch(coursesWithDetailsProvider.future);
  final activeCourse = await ref.watch(activeCourseWithDetailsProvider.future);
  final activeLevel = activeCourse?.course.level ?? 0;
  final upcomingCourses = <CourseWithDetails>[];

  for (final courseWithDetails in coursesWithDetails) {
    final course = courseWithDetails.course;
    if (course.level <= activeLevel) continue; // Only higher levels than active
    final completedModules = await ref.watch(completedModulesProvider(course.id).future);
    final totalModules = courseWithDetails.totalModules;
    final completedModulesCount = completedModules.values.where((completed) => completed).length;
    if (totalModules == 0 || completedModulesCount < totalModules) {
      upcomingCourses.add(courseWithDetails);
    }
  }
  upcomingCourses.sort((a, b) => a.course.level.compareTo(b.course.level));
  return upcomingCourses;
});

final courseByIdProvider = FutureProvider.family<CourseModel, String>((ref, id) async {
  final courseService = ref.watch(courseServiceProvider);
  return courseService.getCourseById(id);
});

final completeCourseProvider = FutureProvider.family<CompleteCourseModel, String>((ref, courseId) async {
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

final courseRefreshProvider = Provider.family<void Function(), String>((ref, courseId) {
  return () {
    // Invalidate the complete course provider to force a refresh
    ref.invalidate(completeCourseProvider(courseId));
  };
});

// Provider to get the first module (position 1) for ongoing module card
final firstModuleProvider = FutureProvider.family<ModuleWithLessons?, String>((ref, courseId) async {
  final completeCourse = await ref.watch(completeCourseProvider(courseId).future);
  if (completeCourse.modules.isNotEmpty) {
    // Return the first module (position 1) instead of the last
    return completeCourse.modules.first;
  }
  return null;
});

Future<Set<String>> _fetchCompletedModuleIds(String courseProgressId) async {
  try {
    final response = await Supabase.instance.client
        .from('module_progress')
        .select('module_id')
        .eq('course_progress_id', courseProgressId)
        .eq('status', 'completed');

    if (response is! List) {
      return <String>{};
    }

    return response
        .map((row) => row['module_id'] as String?)
        .whereType<String>()
        .toSet();
  } catch (e) {
    debugPrint('Error fetching completed modules: $e');
    return <String>{};
  }
}

// Provider to get completed modules for a course
final completedModulesProvider = FutureProvider.family<Map<String, bool>, String>((ref, courseId) async {
  final completeCourse = await ref.watch(completeCourseProvider(courseId).future);
  final completedModules = <String, bool>{};
  
  // Get courseProgressId for this course
  final courseProgressId = await ref.watch(getOrCreateCourseProgressProvider(courseId).future);
  
  // Check module progress records in Supabase
  final moduleProgressRecords = await _fetchCompletedModuleIds(courseProgressId);
  
  print('\n=== Completed Modules Provider Debug ===');
  print('Course ID: $courseId');
  print('Course Progress ID: $courseProgressId');
  print('Completed modules from progress records: ${moduleProgressRecords.toList()}');
  
  for (final module in completeCourse.modules) {
    final isCompletedFromRecord = moduleProgressRecords.contains(module.module.id);

    completedModules[module.module.id] = isCompletedFromRecord;

    print('Module: ${module.module.description} (${module.module.id})');
    print('  Completed from record: $isCompletedFromRecord');
  }
  
  print('Final completed modules: ${completedModules.entries.where((e) => e.value).map((e) => e.key).toList()}');
  print('=====================================\n');
  
  return completedModules;
});

// Provider to get the ongoing module (first incomplete module)
final ongoingModuleProvider = FutureProvider.family<ModuleWithLessons?, String>((ref, courseId) async {
  final completeCourse = await ref.watch(completeCourseProvider(courseId).future);
  final completedModules = await ref.watch(completedModulesProvider(courseId).future);
  
  // Get courseProgressId for this course
  final courseProgressId = await ref.watch(getOrCreateCourseProgressProvider(courseId).future);
  
  // Check module progress records in Supabase
  final moduleProgressRecords = await _fetchCompletedModuleIds(courseProgressId);
  
  print('\n=== Ongoing Module Provider Debug ===');
  print('Course ID: $courseId');
  print('Course Progress ID: $courseProgressId');
  print('Completed modules from progress records: ${moduleProgressRecords.toList()}');
  print('Completed modules from progress records: ${moduleProgressRecords.toList()}');
  
  // Find the first incomplete module
  for (final module in completeCourse.modules) {
    final isCompletedFromRecord = moduleProgressRecords.contains(module.module.id);

    print('Module: ${module.module.description} (${module.module.id})');
    print('  Completed from record: $isCompletedFromRecord');

    if (!isCompletedFromRecord) {
      print('  -> Returning as ongoing module');
      print('=====================================\n');
      return module;
    }
  }
  
  // If all modules are completed, return null (no ongoing module)
  print('All modules are completed, returning null');
  print('=====================================\n');
  return null;
});

// Provider to get course progress statistics
final courseProgressProvider = FutureProvider.family<CourseProgressStats, String>((ref, courseId) async {
  final completeCourse = await ref.watch(completeCourseProvider(courseId).future);
  final completedModules = await ref.watch(completedModulesProvider(courseId).future);
  
  int totalModules = completeCourse.modules.length;
  int completedModulesCount = completedModules.values.where((completed) => completed).length;
  int totalLessons = completeCourse.modules.fold<int>(0, (sum, module) => sum + module.lessons.length);
  int completedLessons = 0;
  int totalQuizzes = 0;
  int completedQuizzes = 0;
  
  // Calculate lesson and quiz progress
  // for (final module in completeCourse.modules) {
  //   final moduleProgress = ref.watch(moduleQuizProgressProvider(module.module.id));
  //   if (moduleProgress != null) {
  //     completedLessons += moduleProgress.lessonScores.length;
  //     totalQuizzes += moduleProgress.totalQuizzes;
  //     completedQuizzes += moduleProgress.completedQuizzes;
  //   }
  // }
  
  return CourseProgressStats(
    totalModules: totalModules,
    completedModules: completedModulesCount,
    totalLessons: totalLessons,
    completedLessons: completedLessons,
    totalQuizzes: totalQuizzes,
    completedQuizzes: completedQuizzes,
    courseCompletionPercentage: totalModules > 0 ? (completedModulesCount / totalModules) * 100 : 0,
  );
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

final refreshCompleteCourseProvider = FutureProvider.family<CompleteCourseModel, String>((ref, courseId) async {
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

  CourseProgressStats({
    required this.totalModules,
    required this.completedModules,
    required this.totalLessons,
    required this.completedLessons,
    required this.totalQuizzes,
    required this.completedQuizzes,
    required this.courseCompletionPercentage,
  });
}

// Provider to trigger course progress refresh
final courseProgressRefreshProvider = StateProvider<int>((ref) => 0);

// Stream-based refresh mechanism for more efficient updates
final courseProgressRefreshStreamProvider = StreamProvider.family<void, String>((ref, courseId) async* {
  // Watch the refresh provider
  ref.watch(courseProgressRefreshProvider);
  
  // Yield to trigger stream update
  yield null;
  
  // Invalidate all related providers
  ref.invalidate(completedModulesProvider(courseId));
  ref.invalidate(ongoingModuleProvider(courseId));
  ref.invalidate(courseCompletedLessonsProvider(courseId));
  ref.invalidate(courseCompletedModulesProvider(courseId));
  ref.invalidate(courseProgressProvider(courseId));
  
  debugPrint('CourseProgressRefreshStream: Refreshed data for course $courseId');
});

// Provider to check and update course completion status
final checkAndUpdateCourseCompletionProvider = FutureProvider.family<void, String>((ref, courseId) async {
  final completeCourse = await ref.watch(completeCourseProvider(courseId).future);
  final completedModules = await ref.watch(completedModulesProvider(courseId).future);
  
  final totalModules = completeCourse.modules.length;
  final completedModulesCount = completedModules.values.where((completed) => completed).length;
  
  // If all modules are completed, mark the course as completed
  if (totalModules > 0 && completedModulesCount >= totalModules) {
    final courseProgressId = await ref.watch(getOrCreateCourseProgressProvider(courseId).future);
    final existingCourseProgress = await ref.watch(courseProgressByIdProvider(courseProgressId).future);
    
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

// Provider that combines course progress data and refreshes when needed
final courseProgressWithRefreshProvider = FutureProvider.family<CourseProgressStats, String>((ref, courseId) async {
  // Watch the refresh provider to trigger updates
  ref.watch(courseProgressRefreshProvider);
  
  final completeCourse = await ref.watch(completeCourseProvider(courseId).future);
  final completedModules = await ref.watch(completedModulesProvider(courseId).future);
  
  int totalModules = completeCourse.modules.length;
  int completedModulesCount = completedModules.values.where((completed) => completed).length;
  int totalLessons = completeCourse.modules.fold<int>(0, (sum, module) => sum + module.lessons.length);
  int completedLessons = 0;
  int totalQuizzes = 0;
  int completedQuizzes = 0;
  
  // Calculate lesson and quiz progress
  // for (final module in completeCourse.modules) {
  //   final moduleProgress = ref.watch(moduleQuizProgressProvider(module.module.id));
  //   if (moduleProgress != null) {
  //     completedLessons += moduleProgress.lessonScores.length;
  //     totalQuizzes += moduleProgress.totalQuizzes;
  //     completedQuizzes += moduleProgress.completedQuizzes;
  //   }
  // }
  
  return CourseProgressStats(
    totalModules: totalModules,
    completedModules: completedModulesCount,
    totalLessons: totalLessons,
    completedLessons: completedLessons,
    totalQuizzes: totalQuizzes,
    completedQuizzes: completedQuizzes,
    courseCompletionPercentage: totalModules > 0 ? (completedModulesCount / totalModules) * 100 : 0,
  );
});

// Enhanced provider that automatically refreshes all course-related data
final autoRefreshCourseDataProvider = FutureProvider.family<void, String>((ref, courseId) async {
  // Watch the refresh provider to trigger updates
  ref.watch(courseProgressRefreshProvider);
  
  // Invalidate all related providers to ensure fresh data
  ref.invalidate(completedModulesProvider(courseId));
  ref.invalidate(ongoingModuleProvider(courseId));
  ref.invalidate(courseCompletedLessonsProvider(courseId));
  ref.invalidate(courseCompletedModulesProvider(courseId));
  ref.invalidate(courseProgressProvider(courseId));
  
  // Force refresh of all module progress
  final completeCourse = await ref.watch(completeCourseProvider(courseId).future);
  // for (final module in completeCourse.modules) {
  //   ref.read(moduleQuizProgressProvider(module.module.id).notifier).loadModuleProgress(module.module.id);
  // }
  
  debugPrint('AutoRefreshCourseDataProvider: Refreshed all data for course $courseId');
});

// Provider to get course progress with automatic refresh
final courseProgressWithAutoRefreshProvider = FutureProvider.family<CourseProgressStats, String>((ref, courseId) async {
  // Trigger auto refresh
  await ref.watch(autoRefreshCourseDataProvider(courseId).future);
  
  // Get the refreshed data
  return ref.watch(courseProgressWithRefreshProvider(courseId).future);
});

// Assessment Course Suggestions Provider
final assessmentCourseSuggestionsProvider = FutureProvider<Map<String, List<CourseModel>>>((ref) async {
  final courseService = ref.watch(courseServiceProvider);
  
  // Define the course types that correspond to assessment stages
  const assessmentCourseTypes = ['Letter', 'Word', 'Sentence', 'Writing'];
  
  try {
    final coursesByType = await courseService.getCoursesByTypes(assessmentCourseTypes);
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
