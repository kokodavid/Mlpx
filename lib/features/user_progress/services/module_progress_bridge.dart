import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:milpress/features/course/providers/module_provider.dart';
import 'package:milpress/features/user_progress/models/lesson_progress_model.dart';
import 'package:milpress/features/user_progress/models/course_progress_model.dart';
import 'package:milpress/features/user_progress/services/user_progress_service.dart';
import 'package:milpress/features/user_progress/providers/user_progress_providers.dart';

/// Bridge service to sync ModuleQuizProgress with Firebase via UserProgress models
class ModuleProgressBridge {
  final UserProgressService _userProgressService;
  final SupabaseClient _supabase;

  ModuleProgressBridge(this._userProgressService, this._supabase);

  /// Convert ModuleQuizProgress to LessonProgressModel entries and sync to Firebase
  Future<void> syncModuleQuizProgress(
    String moduleId,
    Map<String, LessonQuizScore> lessonScores,
    String userId,
    String courseId,
  ) async {
    print('\n=== Module Progress Bridge: Syncing Module Quiz Progress ===');
    print('Module ID: $moduleId');
    print('User ID: $userId');
    print('Course ID: $courseId');
    print('Lesson scores count: ${lessonScores.length}');

    try {
      // Get or create course progress
      final courseProgressId = await _getOrCreateCourseProgress(userId, courseId);
      
      // Convert each lesson score to LessonProgressModel
      for (final entry in lessonScores.entries) {
        final lessonId = entry.key;
        final lessonScore = entry.value;
        
        print('Processing lesson: ${lessonScore.lessonTitle}');
        print('  Score: ${lessonScore.score}/${lessonScore.totalQuestions}');
        print('  Completed: ${lessonScore.isCompleted}');
        
        if (lessonScore.isCompleted) {
          await _createOrUpdateLessonProgress(
            lessonId,
            lessonScore,
            userId,
            courseProgressId,
            moduleId,
          );
        }
      }

      // Update course progress if module is complete
      await _updateCourseProgressIfModuleComplete(userId, courseId, moduleId);
      
      print('Module quiz progress sync completed successfully');
    } catch (e) {
      print('Error syncing module quiz progress: $e');
      rethrow;
    }
    print('=====================================\n');
  }

  /// Sync complete module progress with module completion status
  Future<void> syncCompleteModuleProgress(
    String moduleId,
    Map<String, LessonQuizScore> lessonScores,
    String userId,
    String courseId,
    bool isModuleComplete,
  ) async {
    print('\n=== Module Progress Bridge: Syncing Complete Module Progress ===');
    print('Module ID: $moduleId');
    print('User ID: $userId');
    print('Course ID: $courseId');
    print('Module Complete: $isModuleComplete');
    print('Lesson scores count: ${lessonScores.length}');

    try {
      // Get or create course progress
      final courseProgressId = await _getOrCreateCourseProgress(userId, courseId);
      
      // Convert each lesson score to LessonProgressModel
      for (final entry in lessonScores.entries) {
        final lessonId = entry.key;
        final lessonScore = entry.value;
        
        print('Processing lesson: ${lessonScore.lessonTitle}');
        print('  Score: ${lessonScore.score}/${lessonScore.totalQuestions}');
        print('  Completed: ${lessonScore.isCompleted}');
        
        if (lessonScore.isCompleted) {
          await _createOrUpdateLessonProgress(
            lessonId,
            lessonScore,
            userId,
            courseProgressId,
            moduleId,
          );
        }
      }

      // Update course progress with module completion status
      await _updateCourseProgressWithModuleCompletion(
        userId, 
        courseId, 
        moduleId, 
        isModuleComplete,
      );
      
      print('Complete module progress sync completed successfully');
    } catch (e) {
      print('Error syncing complete module progress: $e');
      rethrow;
    }
    print('=====================================\n');
  }

  /// Get existing course progress or create new one
  Future<String> _getOrCreateCourseProgress(String userId, String courseId) async {
    try {
      // Try to get existing course progress
      final response = await _supabase
          .from('course_progress')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .single();

      if (response != null) {
        print('Found existing course progress: ${response['id']}');
        return response['id'] as String;
      }
    } catch (e) {
      // Course progress doesn't exist, create new one
      print('No existing course progress found, creating new one');
    }

    // Create new course progress
    final courseProgress = CourseProgressModel(
      id: _generateId(),
      userId: userId,
      courseId: courseId,
      startedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      needsSync: false, // Will be synced immediately
    );

    // Save locally and sync to Firebase
    await _userProgressService.saveCourseProgressLocally(courseProgress);
    final success = await _userProgressService.uploadCourseProgressToSupabase(courseProgress);
    
    if (success) {
      print('Created new course progress: ${courseProgress.id}');
      return courseProgress.id;
    } else {
      throw Exception('Failed to create course progress');
    }
  }

  /// Create or update lesson progress for a completed quiz
  Future<void> _createOrUpdateLessonProgress(
    String lessonId,
    LessonQuizScore lessonScore,
    String userId,
    String courseProgressId,
    String moduleId,
  ) async {
    try {
      // Try to get existing lesson progress
      final response = await _supabase
          .from('lesson_progress')
          .select('id')
          .eq('user_id', userId)
          .eq('lesson_id', lessonId)
          .single();

      String lessonProgressId;
      bool isNew = false;

      if (response != null) {
        lessonProgressId = response['id'] as String;
        print('Found existing lesson progress: $lessonProgressId');
      } else {
        lessonProgressId = _generateId();
        isNew = true;
        print('Creating new lesson progress: $lessonProgressId');
      }

      // Create or update lesson progress model
      final lessonProgress = LessonProgressModel(
        id: lessonProgressId,
        userId: userId,
        lessonId: lessonId,
        courseProgressId: courseProgressId,
        moduleId: moduleId,
        status: 'completed',
        startedAt: lessonScore.completedAt,
        completedAt: lessonScore.completedAt,
        videoProgress: 100, // Assume video is completed if quiz is done
        quizScore: lessonScore.score,
        quizTotalQuestions: lessonScore.totalQuestions,
        quizAttemptedAt: lessonScore.completedAt,
        lessonTitle: lessonScore.lessonTitle,
        createdAt: isNew ? DateTime.now() : DateTime.now(), // Would need to get from existing if updating
        updatedAt: DateTime.now(),
        needsSync: false, // Will be synced immediately
      );

      // Sync to Supabase
      final success = await _userProgressService.uploadLessonProgressToSupabase(lessonProgress);
      
      if (success) {
        print('Lesson progress ${isNew ? 'created' : 'updated'}: $lessonProgressId');
      } else {
        print('Failed to sync lesson progress: $lessonProgressId');
      }
    } catch (e) {
      print('Error processing lesson progress for $lessonId: $e');
      // Continue with other lessons even if one fails
    }
  }

  /// Update course progress if the module is complete
  Future<void> _updateCourseProgressIfModuleComplete(
    String userId,
    String courseId,
    String moduleId,
  ) async {
    try {
      // Check if this module is the last one in the course
      // This is a simplified check - in a real implementation, you'd need to
      // check the course structure to determine if this is the final module
      
      // For now, we'll just update the current module ID
      final response = await _supabase
          .from('course_progress')
          .update({
            'current_module_id': moduleId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('course_id', courseId);

      print('Updated course progress current module to: $moduleId');
    } catch (e) {
      print('Error updating course progress: $e');
    }
  }

  /// Update course progress with module completion status
  Future<void> _updateCourseProgressWithModuleCompletion(
    String userId,
    String courseId,
    String moduleId,
    bool isModuleComplete,
  ) async {
    try {
      final updateData = <String, dynamic>{
        'current_module_id': moduleId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // If module is complete, update completion status
      if (isModuleComplete) {
        updateData['is_completed'] = true;
        updateData['completed_at'] = DateTime.now().toIso8601String();
        print('Marking course as completed');
      }

      final response = await _supabase
          .from('course_progress')
          .update(updateData)
          .eq('user_id', userId)
          .eq('course_id', courseId);

      print('Updated course progress:');
      print('  Current module: $moduleId');
      print('  Module complete: $isModuleComplete');
      if (isModuleComplete) {
        print('  Course marked as completed');
      }
    } catch (e) {
      print('Error updating course progress with module completion: $e');
    }
  }

  /// Generate a unique ID for new progress entries
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

/// Provider for the ModuleProgressBridge
final moduleProgressBridgeProvider = Provider<ModuleProgressBridge>((ref) {
  final supabase = Supabase.instance.client;
  final userProgressService = ref.read(userProgressServiceProvider);
  return ModuleProgressBridge(userProgressService, supabase);
});

/// Provider to trigger module progress sync
final syncModuleProgressProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final bridge = ref.read(moduleProgressBridgeProvider);
  final moduleId = params['moduleId'] as String;
  final lessonScores = params['lessonScores'] as Map<String, LessonQuizScore>;
  final userId = params['userId'] as String;
  final courseId = params['courseId'] as String;
  
  await bridge.syncModuleQuizProgress(moduleId, lessonScores, userId, courseId);
}); 
