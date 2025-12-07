import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_progress_service.dart';
import '../services/module_progress_bridge.dart';
import '../models/lesson_progress_model.dart';
import '../models/course_progress_model.dart';
import 'package:milpress/features/course/providers/module_provider.dart';
import 'package:milpress/features/user_progress/models/module_progress_model.dart';
import 'package:hive/hive.dart';
import 'package:milpress/features/course/providers/course_provider.dart';
import 'package:milpress/utils/supabase_config.dart';
import 'course_progress_providers.dart';
import 'package:milpress/features/reviews/services/bookmark_service.dart';

// Service provider
final userProgressServiceProvider = Provider<UserProgressService>((ref) {
  final supabase = Supabase.instance.client;
  return UserProgressService(supabase);
});

// Bridge service provider
final moduleProgressBridgeProvider = Provider<ModuleProgressBridge>((ref) {
  final supabase = Supabase.instance.client;
  final userProgressService = ref.read(userProgressServiceProvider);
  return ModuleProgressBridge(userProgressService, supabase);
});

// Save/update lesson progress locally
final saveLessonProgressProvider =
    FutureProvider.family<void, LessonProgressModel>((ref, progress) async {
  final service = ref.read(userProgressServiceProvider);
  await service.saveLessonProgressLocally(progress);
});

// Save/update course progress locally
final saveCourseProgressProvider =
    FutureProvider.family<void, CourseProgressModel>((ref, progress) async {
  final service = ref.read(userProgressServiceProvider);
  await service.saveCourseProgressLocally(progress);
});

// Save/update module progress locally
final saveModuleProgressProvider =
    FutureProvider.family<void, ModuleProgressModel>((ref, progress) async {
  final service = ref.read(userProgressServiceProvider);
  await service.saveModuleProgressLocally(progress);
});

// Get all pending lesson progress
final pendingLessonProgressProvider =
    FutureProvider<List<LessonProgressModel>>((ref) async {
  final service = ref.read(userProgressServiceProvider);
  return service.getPendingLessonProgress();
});

// Get all pending course progress
final pendingCourseProgressProvider =
    FutureProvider<List<CourseProgressModel>>((ref) async {
  final service = ref.read(userProgressServiceProvider);
  return service.getPendingCourseProgress();
});

// Sync all progress (lessons, courses, and bookmarks)
final syncAllProgressProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(userProgressServiceProvider);
  final results = <String, dynamic>{};
  
  try {
    print('[syncAllProgressProvider] Starting sync...');
    
    // Check if required tables exist
    final tableExistence = await service.checkTableExistence();
    results['tableExistence'] = tableExistence;
    
    // Check if any required tables are missing
    final missingTables = tableExistence.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
    
    if (missingTables.isNotEmpty) {
      final errorMsg = 'Missing database tables: ${missingTables.join(', ')}';
      print('[syncAllProgressProvider] $errorMsg');
      throw Exception(errorMsg);
    }
    
    // Get counts before sync
    final pendingLessons = await service.getPendingLessonProgress();
    final pendingCourses = await service.getPendingCourseProgress();
    final pendingModules = await service.getPendingModuleProgress();
    
    results['before'] = {
      'lessons': pendingLessons.length,
      'courses': pendingCourses.length,
      'modules': pendingModules.length,
    };
    
    print('[syncAllProgressProvider] Pending items - Lessons: ${pendingLessons.length}, Courses: ${pendingCourses.length}, Modules: ${pendingModules.length}');
    
    // Perform sync
    await service.syncAllProgress();
    
    // Also sync bookmarks
    final user = SupabaseConfig.currentUser;
    final userId = user?.id;
    if (userId != null) {
      final bookmarkService = BookmarkService();
      await bookmarkService.syncBookmarks(userId);
    }
    
    // Get counts after sync
    final remainingLessons = await service.getPendingLessonProgress();
    final remainingCourses = await service.getPendingCourseProgress();
    final remainingModules = await service.getPendingModuleProgress();
    
    results['after'] = {
      'lessons': remainingLessons.length,
      'courses': remainingCourses.length,
      'modules': remainingModules.length,
    };
    
    results['synced'] = {
      'lessons': pendingLessons.length - remainingLessons.length,
      'courses': pendingCourses.length - remainingCourses.length,
      'modules': pendingModules.length - remainingModules.length,
    };
    
    print('[syncAllProgressProvider] Sync completed - Synced: ${results['synced']}');
    
    return results;
  } catch (e) {
    print('[syncAllProgressProvider] Sync error: $e');
    results['error'] = e.toString();
    throw Exception('Sync failed: $e');
  }
});

// Fetch and cache course progress from Supabase for a user
final fetchAndCacheCourseProgressProvider = FutureProvider.family<void, String>((ref, userId) async {
  final service = ref.read(userProgressServiceProvider);
  await service.fetchAndCacheCourseProgressFromSupabase(userId);
});

// Fetch and cache module progress from Supabase for a user
final fetchAndCacheModuleProgressProvider = FutureProvider.family<void, String>((ref, userId) async {
  final service = ref.read(userProgressServiceProvider);
  await service.fetchAndCacheModuleProgressFromSupabase(userId);
});

// Fetch and cache lesson progress from Supabase for a user
final fetchAndCacheLessonProgressProvider = FutureProvider.family<void, String>((ref, userId) async {
  final service = ref.read(userProgressServiceProvider);
  await service.fetchAndCacheLessonProgressFromSupabase(userId);
  
  // Also fetch bookmarks from cloud
  final bookmarkService = BookmarkService();
  await bookmarkService.fetchBookmarksFromCloud(userId);
});

// Count completed lessons for a course from Hive
final courseCompletedLessonsProvider = FutureProvider.family<int, String>((ref, courseId) async {
  // Get the courseProgressId for this course
  final courseProgressId = await ref.watch(getOrCreateCourseProgressProvider(courseId).future);
  if (courseProgressId.isEmpty) return 0;
  
  final box = await Hive.openBox<LessonProgressModel>('lesson_progress');
  // Count lessons with courseProgressId matching and status == 'completed'
  return box.values.where((lp) => lp.courseProgressId == courseProgressId && lp.status == 'completed').length;
});

// Fraction of unique lessons in Hive for a course divided by total lessons in the course
final courseLessonProgressValueProvider = FutureProvider.family<double, String>((ref, courseId) async {
  print('\n=== courseLessonProgressValueProvider Debug ===');
  print('Course ID: $courseId');
  
  // Get the courseProgressId for this course
  final courseProgressId = await ref.watch(getOrCreateCourseProgressProvider(courseId).future);
  print('Course Progress ID: $courseProgressId');
  if (courseProgressId.isEmpty) {
    print('Course Progress ID is empty, returning 0.0');
    return 0.0;
  }
  
  final box = await Hive.openBox<LessonProgressModel>('lesson_progress');
  
  // Log ALL lessons in Hive
  print('\n--- ALL Lessons in Hive ---');
  for (final lesson in box.values) {
    print('Lesson ID: ${lesson.lessonId}');
    print('  Course Progress ID: ${lesson.courseProgressId}');
    print('  Status: ${lesson.status}');
    print('  Title: ${lesson.lessonTitle}');
    print('  User ID: ${lesson.userId}');
    print('  ---');
  }
  
  // Get all lesson progress for this course (any status)
  final lessons = box.values.where((lp) => lp.courseProgressId == courseProgressId);
  print('\n--- Filtered Lessons (matching courseProgressId: $courseProgressId) ---');
  for (final lesson in lessons) {
    print('Lesson ID: ${lesson.lessonId}');
    print('  Status: ${lesson.status}');
    print('  Title: ${lesson.lessonTitle}');
    print('  ---');
  }
  
  // Count unique lesson IDs
  final uniqueLessonIds = lessons.map((lp) => lp.lessonId).toSet();
  print('\n--- Unique Lesson IDs ---');
  print('Unique lesson IDs: ${uniqueLessonIds.toList()}');
  print('Count: ${uniqueLessonIds.length}');

  // Get total lessons for this course from course data
  final completeCourse = await ref.watch(completeCourseProvider(courseId).future);
  if (completeCourse == null) {
    print('Complete course is null, returning 0.0');
    return 0.0;
  }
  final totalLessons = completeCourse.modules.fold<int>(0, (sum, m) => sum + m.lessons.length);
  print('\n--- Course Structure ---');
  print('Total lessons in course: $totalLessons');
  for (int i = 0; i < completeCourse.modules.length; i++) {
    final module = completeCourse.modules[i];
    print('Module $i: ${module.module.description}');
    print('  Lessons: ${module.lessons.map((l) => '${l.id} (${l.title})').toList()}');
  }

  if (totalLessons == 0) {
    print('Total lessons is 0, returning 0.0');
    return 0.0;
  }
  
  final progressValue = uniqueLessonIds.length / totalLessons;
  print('\n--- Final Calculation ---');
  print('Unique lessons with progress: ${uniqueLessonIds.length}');
  print('Total lessons in course: $totalLessons');
  print('Progress value: $progressValue');
  print('=====================================\n');
  
  return progressValue;
});

// Count completed modules for a course from Hive
final courseCompletedModulesProvider = FutureProvider.family<int, String>((ref, courseId) async {
  print('\n=== courseCompletedModulesProvider Debug ===');
  print('Course ID: $courseId');
  
  // Get the courseProgressId for this course
  final courseProgressId = await ref.watch(getOrCreateCourseProgressProvider(courseId).future);
  print('Course Progress ID: $courseProgressId');
  if (courseProgressId.isEmpty) {
    print('Course Progress ID is empty, returning 0');
    return 0;
  }
  
  final box = await Hive.openBox<ModuleProgressModel>('module_progress');
  
  // Log ALL modules in Hive
  print('\n--- ALL Modules in Hive ---');
  for (final module in box.values) {
    print('Module ID: ${module.moduleId}');
    print('  Course Progress ID: ${module.courseProgressId}');
    print('  Status: ${module.status}');
    print('  Completed Lessons: ${module.completedLessons}/${module.totalLessons}');
    print('  ---');
  }
  
  // Count modules with courseProgressId matching and status == 'completed'
  final completedModules = box.values.where((mp) => 
    mp.courseProgressId == courseProgressId && mp.status == 'completed'
  );
  
  print('\n--- Completed Modules ---');
  for (final module in completedModules) {
    print('Module ID: ${module.moduleId}');
    print('  Status: ${module.status}');
    print('  Completed Lessons: ${module.completedLessons}/${module.totalLessons}');
    print('  ---');
  }
  
  final count = completedModules.length;
  print('\n--- Final Count ---');
  print('Completed modules: $count');
  print('=====================================\n');
  
  return count;
});

// Manual trigger for module progress sync (for testing)
final manualModuleProgressSyncProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final bridge = ref.read(moduleProgressBridgeProvider);
  final moduleId = params['moduleId'] as String;
  final lessonScoresData = params['lessonScores'] as Map<String, dynamic>;
  final userId = params['userId'] as String;
  final courseId = params['courseId'] as String;

  // Convert lessonScores to the expected format
  final convertedLessonScores = <String, LessonQuizScore>{};
  for (final entry in lessonScoresData.entries) {
    final lessonId = entry.key;
    final scoreData = entry.value as Map<String, dynamic>;

    convertedLessonScores[lessonId] = LessonQuizScore(
      lessonId: lessonId,
      lessonTitle: scoreData['lessonTitle'] as String? ?? '',
      score: scoreData['score'] as int? ?? 0,
      totalQuestions: scoreData['totalQuestions'] as int? ?? 0,
      isCompleted: scoreData['isCompleted'] as bool? ?? false,
      completedAt: scoreData['completedAt'] != null
          ? DateTime.parse(scoreData['completedAt'] as String)
          : null,
    );
  }

  await bridge.syncModuleQuizProgress(
      moduleId, convertedLessonScores, userId, courseId);
});

class ModuleProgressNotifier extends StateNotifier<ModuleProgressModel?> {
  final String moduleId;

  ModuleProgressNotifier(this.moduleId) : super(null) {
    _loadModuleProgress();
  }

  Future<void> _loadModuleProgress() async {
    final box = await Hive.openBox<ModuleProgressModel>('module_progress');
    final matches = box.values.where((p) => p.moduleId == moduleId);
    final progress = matches.isNotEmpty ? matches.first : null;
    state = progress;
  }

  Future<void> updateModuleProgress(ModuleProgressModel updated) async {
    final box = await Hive.openBox<ModuleProgressModel>('module_progress');
    await box.put(updated.id, updated);
    state = updated;
  }

  Future<void> syncModuleProgress() async {
    if (state != null) {
      state = state!.copyWith(needsSync: false);
      await updateModuleProgress(state!);
    }
  }
}

final moduleProgressProvider = StateNotifierProvider.family<ModuleProgressNotifier, ModuleProgressModel?, String>(
  (ref, moduleId) => ModuleProgressNotifier(moduleId),
);
