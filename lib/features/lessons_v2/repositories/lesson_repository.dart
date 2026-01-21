import 'package:flutter/foundation.dart';
import 'package:milpress/utils/supabase_config.dart';
import '../models/lesson_models.dart';

class LessonRepository {
  Future<LessonDefinition?> fetchLessonById(String lessonId) async {
    try {
      final lessonRow = await SupabaseConfig.client
          .from('new_lessons')
          .select()
          .eq('id', lessonId)
          .maybeSingle();

      if (lessonRow == null || lessonRow is! Map) {
        return null;
      }

      final stepRows = await SupabaseConfig.client
          .from('lesson_steps')
          .select()
          .eq('lesson_id', lessonId)
          .order('position', ascending: true);

      final steps = (stepRows as List).cast<Map<String, dynamic>>();

      return LessonDefinition.fromSupabase(
        lessonRow.cast<String, dynamic>(),
        steps,
      );
    } catch (e) {
      debugPrint('LessonRepository: failed to load lesson $lessonId: $e');
      return null;
    }
  }

  Future<List<LessonDefinition>> fetchLessonsForModule(String moduleId) async {
    try {
      final lessonRows = await SupabaseConfig.client
          .from('new_lessons')
          .select()
          .eq('module_id', moduleId)
          .order('display_order', ascending: true);

      final lessons = <LessonDefinition>[];
      for (final row in (lessonRows as List).cast<Map<String, dynamic>>()) {
        lessons.add(
          LessonDefinition.fromSupabase(
            row,
            const <Map<String, dynamic>>[],
          ),
        );
      }
      return lessons;
    } catch (e) {
      debugPrint('LessonRepository: failed to load lessons for $moduleId: $e');
      return [];
    }
  }

  Future<int> recordLessonAttempt({
    required String lessonId,
    String? userId,
    bool markCompleted = false,
  }) async {
    try {
      final resolvedUserId = userId ?? SupabaseConfig.currentUser?.id;
      if (resolvedUserId == null || resolvedUserId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now().toIso8601String();
      final existing = await SupabaseConfig.client
          .from('lesson_completion')
          .select('attempt_count, completed_at')
          .eq('user_id', resolvedUserId)
          .eq('lesson_id', lessonId)
          .maybeSingle();

      if (existing == null) {
        await SupabaseConfig.client.from('lesson_completion').insert({
          'user_id': resolvedUserId,
          'lesson_id': lessonId,
          'attempt_count': 1,
          'last_attempt_at': now,
          if (markCompleted) 'completed_at': now,
        });
        return 1;
      }

      final currentAttempts = (existing['attempt_count'] as int?) ?? 0;
      final updates = <String, dynamic>{
        'attempt_count': currentAttempts + 1,
        'last_attempt_at': now,
      };
      if (markCompleted && existing['completed_at'] == null) {
        updates['completed_at'] = now;
      }

      await SupabaseConfig.client
          .from('lesson_completion')
          .update(updates)
          .eq('user_id', resolvedUserId)
          .eq('lesson_id', lessonId);

      return currentAttempts + 1;
    } catch (e) {
      debugPrint('LessonRepository: failed to record attempt for $lessonId: $e');
      rethrow;
    }
  }
}
