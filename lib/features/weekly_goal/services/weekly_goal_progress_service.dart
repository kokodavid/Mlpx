import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/weekly_goal_progress.dart';

class WeeklyGoalProgressService {
  final SupabaseClient _supabase;

  WeeklyGoalProgressService(this._supabase);

  Future<WeeklyGoalProgress> getWeeklyProgress({
    required String userId,
    DateTime? nowLocal,
  }) async {
    final now = nowLocal ?? DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final weekStartLocal =
        startOfDay.subtract(Duration(days: startOfDay.weekday - 1));
    final weekEndLocal = weekStartLocal.add(const Duration(days: 7));

    final weekStartUtc = weekStartLocal.toUtc();
    final weekEndUtc = weekEndLocal.toUtc();

    final response = await _supabase
        .from('lesson_progress')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'completed')
        .gte('completed_at', weekStartUtc.toIso8601String())
        .lt('completed_at', weekEndUtc.toIso8601String());

    final completedLessons = (response as List).length;

    return WeeklyGoalProgress(
      completedLessons: completedLessons,
      weekStart: weekStartLocal,
      weekEnd: weekEndLocal,
    );
  }
}
