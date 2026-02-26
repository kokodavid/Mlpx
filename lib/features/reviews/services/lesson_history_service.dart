import 'package:flutter/foundation.dart';
import 'package:milpress/features/reviews/models/lesson_completion_model.dart';
import 'package:milpress/utils/supabase_config.dart';

class LessonHistoryService {
  Future<List<LessonCompletionModel>> getCompletedLessons(String userId) async {
    // Step 1: fetch completion rows (no join to avoid FK issues)
    final raw = await SupabaseConfig.client
        .from('lesson_completion')
        .select('*')
        .eq('user_id', userId)
        .order('completed_at', ascending: false);

    debugPrint('[LessonHistory] Raw rows from lesson_completion: ${raw.length}');

    // Step 2: filter completed_at in Dart
    final completed =
        raw.where((r) => r['completed_at'] != null).toList();

    debugPrint('[LessonHistory] Rows with completed_at set: ${completed.length}');

    if (completed.isEmpty) return [];

    // Step 3: batch-fetch lesson titles from new_lessons
    final lessonIds =
        completed.map((r) => r['lesson_id'] as String).toSet().toList();

    final lessonRows = await SupabaseConfig.client
        .from('new_lessons')
        .select('id, title, module_id')
        .inFilter('id', lessonIds);

    debugPrint('[LessonHistory] Fetched ${lessonRows.length} lesson titles');

    final lessonMap = {
      for (final l in lessonRows) l['id'] as String: l,
    };

    // Step 4: build models
    return completed.map((row) {
      final lessonData = lessonMap[row['lesson_id'] as String];
      return LessonCompletionModel.fromJson({...row, 'new_lessons': lessonData});
    }).toList();
  }
}
