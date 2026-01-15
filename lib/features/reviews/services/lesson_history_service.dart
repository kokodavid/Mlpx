import 'package:milpress/features/user_progress/models/lesson_progress_model.dart';
import 'package:milpress/utils/supabase_config.dart';

class LessonHistoryService {
  Future<List<LessonProgressModel>> getCompletedLessons(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('lesson_progress')
          .select()
          .eq('user_id', userId)
          .eq('status', 'completed')
          .order('completed_at', ascending: false)
          .order('updated_at', ascending: false);

      if (response is! List) {
        return [];
      }

      return response
          .map((row) => LessonProgressModel.fromJson(row))
          .toList();
    } catch (e) {
      print('Error fetching lesson history from Supabase: $e');
      return [];
    }
  }
} 
