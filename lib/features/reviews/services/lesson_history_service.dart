import 'package:flutter/foundation.dart';
import 'package:milpress/features/reviews/models/lesson_completion_model.dart';
import 'package:milpress/utils/supabase_config.dart';

class LessonHistoryService {
  Future<List<LessonCompletionModel>> getCompletedLessons(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('lesson_completion')
          .select('*, new_lessons(title, module_id)')
          .eq('user_id', userId)
          .not('completed_at', 'is', null)
          .order('completed_at', ascending: false);

      return response
          .map((row) => LessonCompletionModel.fromJson(row))
          .toList();
    } catch (e) {
      debugPrint('Error fetching lesson history from Supabase: $e');
      return [];
    }
  }
}
