import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson_progress_model.dart';
import '../models/course_progress_model.dart';
import '../models/module_progress_model.dart';

class UserProgressService {
  static const String lessonBoxName = 'lesson_progress';
  static const String courseBoxName = 'course_progress';
  static const String moduleBoxName = 'module_progress';

  final SupabaseClient supabase;

  UserProgressService(this.supabase);


  Future<void> saveLessonProgressLocally(LessonProgressModel progress) async {
    final box = await Hive.openBox<LessonProgressModel>(lessonBoxName);
    await box.put(progress.id, progress);
  }

  Future<void> saveCourseProgressLocally(CourseProgressModel progress) async {
    final box = await Hive.openBox<CourseProgressModel>(courseBoxName);
    await box.put(progress.id, progress);
  }

  Future<void> saveModuleProgressLocally(ModuleProgressModel progress) async {
    final box = await Hive.openBox<ModuleProgressModel>(moduleBoxName);
    await box.put(progress.id, progress);
  }

  Future<List<LessonProgressModel>> getPendingLessonProgress() async {
    final box = await Hive.openBox<LessonProgressModel>(lessonBoxName);
    return box.values.where((p) => p.needsSync).toList();
  }

  Future<List<CourseProgressModel>> getPendingCourseProgress() async {
    final box = await Hive.openBox<CourseProgressModel>(courseBoxName);
    return box.values.where((p) => p.needsSync).toList();
  }

  Future<List<ModuleProgressModel>> getPendingModuleProgress() async {
    final box = await Hive.openBox<ModuleProgressModel>(moduleBoxName);
    return box.values.where((p) => p.needsSync).toList();
  }


  Future<void> syncAllProgress() async {
    print('[syncAllProgress] Starting sync of all progress...');
    await syncLessonProgress();
    await syncModuleProgress();
    await syncCourseProgress();
    print('[syncAllProgress] Finished sync of all progress.');
  }

  Future<void> syncLessonProgress() async {
    print('[syncLessonProgress] Checking for pending lesson progress...');
    final pending = await getPendingLessonProgress();
    print('[syncLessonProgress] Found ${pending.length} pending lesson progress items.');
    
    if (pending.isEmpty) {
      print('[syncLessonProgress] No pending lessons to sync.');
      return;
    }
    
    int successCount = 0;
    int failureCount = 0;
    
    for (final progress in pending) {
      print('[syncLessonProgress] Uploading lesson progress: id=${progress.id}, lessonId=${progress.lessonId}, needsSync=${progress.needsSync}');
      try {
        final success = await uploadLessonProgressToSupabase(progress);
        if (success) {
          print('[syncLessonProgress] Upload successful for id=${progress.id}');
          progress.needsSync = false;
          await saveLessonProgressLocally(progress);
          successCount++;
        } else {
          print('[syncLessonProgress] Upload failed for id=${progress.id}');
          failureCount++;
        }
      } catch (e) {
        print('[syncLessonProgress] Exception during upload for id=${progress.id}: $e');
        failureCount++;
      }
    }
    print('[syncLessonProgress] Done syncing lesson progress. Success: $successCount, Failures: $failureCount');
  }

  Future<void> syncModuleProgress() async {
    print('[syncModuleProgress] Checking for pending module progress...');
    final pending = await getPendingModuleProgress();
    print('[syncModuleProgress] Found \\${pending.length} pending module progress items.');
    for (final progress in pending) {
      print('[syncModuleProgress] Uploading module progress: id=\\${progress.id}, moduleId=\\${progress.moduleId}');
      final success = await uploadModuleProgressToSupabase(progress);
      if (success) {
        print('[syncModuleProgress] Upload successful for id=\\${progress.id}');
        progress.needsSync = false;
        await saveModuleProgressLocally(progress);
      } else {
        print('[syncModuleProgress] Upload failed for id=\\${progress.id}');
      }
    }
    print('[syncModuleProgress] Done syncing module progress.');
  }

  Future<void> syncCourseProgress() async {
    print('[syncCourseProgress] Checking for pending course progress...');
    final pending = await getPendingCourseProgress();
    print('[syncCourseProgress] Found \\${pending.length} pending course progress items.');
    for (final progress in pending) {
      print('[syncCourseProgress] Uploading course progress: id=\\${progress.id}, courseId=\\${progress.courseId}');
      final success = await uploadCourseProgressToSupabase(progress);
      if (success) {
        print('[syncCourseProgress] Upload successful for id=\\${progress.id}');
        progress.needsSync = false;
        await saveCourseProgressLocally(progress);
      } else {
        print('[syncCourseProgress] Upload failed for id=\\${progress.id}');
      }
    }
    print('[syncCourseProgress] Done syncing course progress.');
  }

  Future<bool> uploadLessonProgressToSupabase(
      LessonProgressModel progress) async {
    print('[uploadLessonProgressToSupabase] Uploading: id=${progress.id}, lessonId=${progress.lessonId}');
    try {
      final jsonData = progressToJson(progress);
      print('[uploadLessonProgressToSupabase] JSON data: $jsonData');
      
      final response = await supabase
          .from('lesson_progress')
          .upsert(
            jsonData,
            onConflict: 'id',
          );
      
      print('[uploadLessonProgressToSupabase] Supabase response: $response');
      print('[uploadLessonProgressToSupabase] Success for id=${progress.id}');
      return true;
    } catch (e, st) {
      print('[uploadLessonProgressToSupabase] Error for id=${progress.id}: $e');
      print('[uploadLessonProgressToSupabase] Stack trace: $st');
      return false;
    }
  }

  Future<bool> uploadCourseProgressToSupabase(
      CourseProgressModel progress) async {
    print('[uploadCourseProgressToSupabase] Uploading: id=\\${progress.id}, courseId=\\${progress.courseId}');
    try {
      await supabase
          .from('course_progress')
          .upsert(
            progressToJson(progress),
            onConflict: 'user_id,course_id',
          );
      print('[uploadCourseProgressToSupabase] Success for id=\\${progress.id}');
      return true;
    } catch (e, st) {
      print('[uploadCourseProgressToSupabase] Error for id=\\${progress.id}: $e\\n$st');
      return false;
    }
  }

  Future<bool> uploadModuleProgressToSupabase(ModuleProgressModel progress) async {
    print('[uploadModuleProgressToSupabase] Uploading: id=\\${progress.id}, moduleId=\\${progress.moduleId}');
    try {
      await supabase
          .from('module_progress')
          .upsert(
            progressToJson(progress),
            onConflict: 'id',
          );
      print('[uploadModuleProgressToSupabase] Success for id=\\${progress.id}');
      return true;
    } catch (e, st) {
      print('[uploadModuleProgressToSupabase] Error for id=\\${progress.id}: $e\\n$st');
      return false;
    }
  }


  Map<String, dynamic> progressToJson(dynamic progress) {
    if (progress is LessonProgressModel) {
      return {
        'id': progress.id,
        'user_id': progress.userId,
        'lesson_id': progress.lessonId,
        'course_progress_id': (progress.courseProgressId == null || progress.courseProgressId.isEmpty) ? null : progress.courseProgressId,
        'status': progress.status,
        'started_at': progress.startedAt?.toIso8601String(),
        'completed_at': progress.completedAt?.toIso8601String(),
        'video_progress': progress.videoProgress,
        'quiz_score': progress.quizScore,
        'quiz_attempted_at': progress.quizAttemptedAt?.toIso8601String(),
        'created_at': progress.createdAt.toIso8601String(),
        'updated_at': progress.updatedAt.toIso8601String(),
      };
    } else if (progress is ModuleProgressModel) {
      return {
        'id': progress.id,
        'user_id': progress.userId,
        'module_id': progress.moduleId,
        'course_progress_id': (progress.courseProgressId == null || progress.courseProgressId.isEmpty) ? null : progress.courseProgressId,
        'status': progress.status,
        'started_at': progress.startedAt?.toIso8601String(),
        'completed_at': progress.completedAt?.toIso8601String(),
        'average_score': progress.averageScore,
        'total_lessons': progress.totalLessons,
        'completed_lessons': progress.completedLessons,
        'created_at': progress.createdAt.toIso8601String(),
        'updated_at': progress.updatedAt.toIso8601String(),
      };
    } else if (progress is CourseProgressModel) {
      return {
        'id': progress.id,
        'user_id': progress.userId,
        'course_id': progress.courseId,
        'started_at': progress.startedAt?.toIso8601String(),
        'completed_at': progress.completedAt?.toIso8601String(),
        'current_module_id': (progress.currentModuleId == null || progress.currentModuleId!.isEmpty) ? null : progress.currentModuleId,
        'current_lesson_id': (progress.currentLessonId == null || progress.currentLessonId!.isEmpty) ? null : progress.currentLessonId,
        'is_completed': progress.isCompleted,
        'created_at': progress.createdAt.toIso8601String(),
        'updated_at': progress.updatedAt.toIso8601String(),
      };
    }
    throw Exception('Unknown progress type');
  }

  /// Fetch all course progress for a user from Supabase and cache in Hive
  Future<void> fetchAndCacheCourseProgressFromSupabase(String userId) async {
    print('[fetchAndCacheCourseProgressFromSupabase] Called for userId: $userId');
    final response = await supabase
        .from('course_progress')
        .select()
        .eq('user_id', userId);
    print('[fetchAndCacheCourseProgressFromSupabase] Supabase response: $response');
    if (response != null && response is List) {
      print('[fetchAndCacheCourseProgressFromSupabase] Fetched \\${response.length} items from Supabase');
      final box = await Hive.openBox<CourseProgressModel>(courseBoxName);
      if (response.isEmpty) {
        print('[fetchAndCacheCourseProgressFromSupabase] No progress found for user in Supabase.');
      }
      for (final item in response) {
        print('[fetchAndCacheCourseProgressFromSupabase] Supabase item: $item');
        final model = CourseProgressModel.fromJson(item as Map<String, dynamic>);
        // Set needsSync to false since this record is already in Supabase
        model.needsSync = false;
        await box.put(model.id, model);
        print('[fetchAndCacheCourseProgressFromSupabase] Cached to Hive: id=\\${model.id}, courseId=\\${model.courseId}, needsSync=false');
      }
      if (response.isNotEmpty) {
        print('[fetchAndCacheCourseProgressFromSupabase] Hive box updated with Supabase data.');
      }
    } else {
      print('[fetchAndCacheCourseProgressFromSupabase] Error: response is not a List or is null');
    }
  }

  Future<void> fetchAndCacheModuleProgressFromSupabase(String userId) async {
    print('[fetchAndCacheModuleProgressFromSupabase] Called for userId: $userId');
    final response = await supabase
        .from('module_progress')
        .select()
        .eq('user_id', userId);
    print('[fetchAndCacheModuleProgressFromSupabase] Supabase response: $response');
    if (response != null && response is List) {
      print('[fetchAndCacheModuleProgressFromSupabase] Fetched \\${response.length} items from Supabase');
      final box = await Hive.openBox<ModuleProgressModel>('module_progress');
      if (response.isEmpty) {
        print('[fetchAndCacheModuleProgressFromSupabase] No module progress found for user in Supabase.');
      }
      for (final item in response) {
        print('[fetchAndCacheModuleProgressFromSupabase] Supabase item: $item');
        final model = ModuleProgressModel.fromJson(item as Map<String, dynamic>);
        model.needsSync = false;
        await box.put(model.id, model);
        print('[fetchAndCacheModuleProgressFromSupabase] Cached to Hive: id=\\${model.id}, moduleId=\\${model.moduleId}, needsSync=false');
      }
      if (response.isNotEmpty) {
        print('[fetchAndCacheModuleProgressFromSupabase] Hive box updated with Supabase data.');
      }
    } else {
      print('[fetchAndCacheModuleProgressFromSupabase] Error: response is not a List or is null');
    }
  }

  Future<void> fetchAndCacheLessonProgressFromSupabase(String userId) async {
    print('[fetchAndCacheLessonProgressFromSupabase] Called for userId: $userId');
    final response = await supabase
        .from('lesson_progress')
        .select()
        .eq('user_id', userId);
    print('[fetchAndCacheLessonProgressFromSupabase] Supabase response: $response');
    if (response != null && response is List) {
      print('[fetchAndCacheLessonProgressFromSupabase] Fetched \\${response.length} items from Supabase');
      final box = await Hive.openBox<LessonProgressModel>('lesson_progress');
      if (response.isEmpty) {
        print('[fetchAndCacheLessonProgressFromSupabase] No lesson progress found for user in Supabase.');
      }
      for (final item in response) {
        print('[fetchAndCacheLessonProgressFromSupabase] Supabase item: $item');
        final model = LessonProgressModel.fromJson(item as Map<String, dynamic>);
        model.needsSync = false;
        await box.put(model.id, model);
        print('[fetchAndCacheLessonProgressFromSupabase] Cached to Hive: id=\\${model.id}, lessonId=\\${model.lessonId}, needsSync=false');
      }
      if (response.isNotEmpty) {
        print('[fetchAndCacheLessonProgressFromSupabase] Hive box updated with Supabase data.');
      }
    } else {
      print('[fetchAndCacheLessonProgressFromSupabase] Error: response is not a List or is null');
    }
  }

  /// Check if required tables exist in Supabase
  Future<Map<String, bool>> checkTableExistence() async {
    final results = <String, bool>{};
    
    try {
      // Check lesson_progress table
      await supabase.from('lesson_progress').select('id').limit(1);
      results['lesson_progress'] = true;
      print('[checkTableExistence] lesson_progress table exists');
    } catch (e) {
      results['lesson_progress'] = false;
      print('[checkTableExistence] lesson_progress table does not exist: $e');
    }
    
    try {
      // Check course_progress table
      await supabase.from('course_progress').select('id').limit(1);
      results['course_progress'] = true;
      print('[checkTableExistence] course_progress table exists');
    } catch (e) {
      results['course_progress'] = false;
      print('[checkTableExistence] course_progress table does not exist: $e');
    }
    
    try {
      // Check module_progress table
      await supabase.from('module_progress').select('id').limit(1);
      results['module_progress'] = true;
      print('[checkTableExistence] module_progress table exists');
    } catch (e) {
      results['module_progress'] = false;
      print('[checkTableExistence] module_progress table does not exist: $e');
    }
    
    return results;
  }
}
