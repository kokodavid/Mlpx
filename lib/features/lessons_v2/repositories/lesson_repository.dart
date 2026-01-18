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
}
