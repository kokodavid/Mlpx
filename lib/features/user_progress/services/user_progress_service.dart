import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson_progress_model.dart';
import '../models/course_progress_model.dart';
import '../models/module_progress_model.dart';

class UserProgressService {
  final SupabaseClient supabase;

  UserProgressService(this.supabase);


  Future<void> saveLessonProgressLocally(LessonProgressModel progress) async {
    await uploadLessonProgressToSupabase(progress);
  }

  Future<void> saveCourseProgressLocally(CourseProgressModel progress) async {
    await uploadCourseProgressToSupabase(progress);
  }

  Future<void> saveModuleProgressLocally(ModuleProgressModel progress) async {
    await uploadModuleProgressToSupabase(progress);
  }

  Future<List<LessonProgressModel>> getPendingLessonProgress() async {
    return <LessonProgressModel>[];
  }

  Future<List<CourseProgressModel>> getPendingCourseProgress() async {
    return <CourseProgressModel>[];
  }

  Future<List<ModuleProgressModel>> getPendingModuleProgress() async {
    return <ModuleProgressModel>[];
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
            onConflict: 'user_id,lesson_id',
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
        'module_id': (progress.moduleId == null || progress.moduleId!.isEmpty) ? null : progress.moduleId,
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

  /// Fetch all course progress for a user from Supabase
  Future<void> fetchAndCacheCourseProgressFromSupabase(String userId) async {
    print('[fetchAndCacheCourseProgressFromSupabase] Called for userId: $userId');
    final response = await supabase
        .from('course_progress')
        .select()
        .eq('user_id', userId);
    print('[fetchAndCacheCourseProgressFromSupabase] Supabase response: $response');
    if (response != null && response is List) {
      print('[fetchAndCacheCourseProgressFromSupabase] Fetched \\${response.length} items from Supabase');
      if (response.isEmpty) {
        print('[fetchAndCacheCourseProgressFromSupabase] No progress found for user in Supabase.');
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
      if (response.isEmpty) {
        print('[fetchAndCacheModuleProgressFromSupabase] No module progress found for user in Supabase.');
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
      if (response.isEmpty) {
        print('[fetchAndCacheLessonProgressFromSupabase] No lesson progress found for user in Supabase.');
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
