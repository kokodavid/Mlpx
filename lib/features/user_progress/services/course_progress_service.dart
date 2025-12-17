import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course_progress_model.dart';
import 'package:milpress/utils/supabase_config.dart';
import 'package:uuid/uuid.dart';

class CourseProgressService {
  static const String courseBoxName = 'course_progress';
  final SupabaseClient supabase;

  CourseProgressService(this.supabase);

  /// Get or create course progress for a user and course
  /// Returns the courseProgressId (either existing or newly created)
  Future<String> getOrCreateCourseProgress(String courseId) async {
    // Use SupabaseConfig.currentUser directly (not reactive)
    final user = SupabaseConfig.currentUser;
    final userId = user?.id;

    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // First check Hive for existing course progress
    final box = await Hive.openBox<CourseProgressModel>(courseBoxName);
    CourseProgressModel? existing;
    
    try {
      existing = box.values.cast<CourseProgressModel>().firstWhere(
        (cp) => cp.userId == userId && cp.courseId == courseId,
      );
      print('Found existing course progress in Hive: ${existing.id}');
      return existing.id;
    } catch (_) {
      // Not found in Hive, check Supabase
      print('Course progress not found in Hive, checking Supabase...');
    }

    // Check Supabase for existing course progress
    try {
      final response = await supabase
          .from('course_progress')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .single();

      if (response != null) {
        final courseProgressId = response['id'] as String;
        print('Found existing course progress in Supabase: $courseProgressId');
        
        // Fetch the full record and cache it in Hive
        final fullResponse = await supabase
            .from('course_progress')
            .select()
            .eq('id', courseProgressId)
            .single();
        
        final courseProgress = CourseProgressModel.fromJson(fullResponse);
        await box.put(courseProgress.id, courseProgress);
        print('Cached course progress in Hive: ${courseProgress.id}');
        
        return courseProgressId;
      }
    } catch (e) {
      // Course progress doesn't exist in Supabase, create new one
      print('Course progress not found in Supabase, creating new one...');
    }

    // Create new course progress
    final now = DateTime.now();
    final newId = const Uuid().v4();
    final courseProgress = CourseProgressModel(
      id: newId,
      userId: userId,
      courseId: courseId,
      startedAt: now,
      completedAt: null,
      currentModuleId: null,
      currentLessonId: null,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      needsSync: true,
    );

    // Save locally first
    await box.put(newId, courseProgress);
    print('Created new course progress locally: $newId');
    
    // Try to upload to Supabase with upsert to handle conflicts
    final success = await uploadCourseProgressToSupabase(courseProgress);
    
    if (success) {
      // After successful upload, fetch the actual record from Supabase
      // to get the correct ID (in case there was a conflict)
      try {
        final response = await supabase
            .from('course_progress')
            .select()
            .eq('user_id', userId)
            .eq('course_id', courseId)
            .single();

        final actualId = response['id'] as String;
        if (actualId != newId) {
          print('Upload resulted in different ID: expected $newId, got $actualId');
          // Remove the local record with wrong ID
          await box.delete(newId);
          
          // Cache the actual record
          final actualCourseProgress = CourseProgressModel.fromJson(response);
          await box.put(actualCourseProgress.id, actualCourseProgress);
          print('Cached actual course progress in Hive: ${actualCourseProgress.id}');
          
          return actualId;
        }
      } catch (e) {
        print('Error fetching actual course progress after upload: $e');
      }
      
      print('Successfully uploaded new course progress: $newId');
      return newId;
    } else {
      throw Exception('Failed to create course progress');
    }
  }

  /// Upload course progress to Supabase
  Future<bool> uploadCourseProgressToSupabase(CourseProgressModel progress) async {
    print('[uploadCourseProgressToSupabase] Uploading: id=${progress.id}, courseId=${progress.courseId}');
    try {
      // Use upsert with conflict resolution on user_id and course_id
      await supabase
          .from('course_progress')
          .upsert(
            progressToJson(progress),
            onConflict: 'user_id,course_id',
          );
      print('[uploadCourseProgressToSupabase] Success for id=${progress.id}');
      return true;
    } catch (e, st) {
      print('[uploadCourseProgressToSupabase] Error for id=${progress.id}: $e\n$st');
      return false;
    }
  }

  /// Convert CourseProgressModel to JSON for Supabase
  Map<String, dynamic> progressToJson(CourseProgressModel progress) {
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

  /// Get course progress by ID from Hive
  Future<CourseProgressModel?> getCourseProgressById(String courseProgressId) async {
    final box = await Hive.openBox<CourseProgressModel>(courseBoxName);
    return box.get(courseProgressId);
  }

  /// Update course progress
  Future<void> updateCourseProgress(CourseProgressModel progress) async {
    final box = await Hive.openBox<CourseProgressModel>(courseBoxName);
    await box.put(progress.id, progress);
  }
} 