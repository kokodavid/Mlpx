import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/supabase_config.dart';
import '../models/weekly_goal_progress.dart';
import '../services/weekly_goal_progress_service.dart';

final weeklyGoalProgressServiceProvider =
    Provider<WeeklyGoalProgressService>((ref) {
  return WeeklyGoalProgressService(SupabaseConfig.client);
});

final weeklyGoalProgressProvider =
    FutureProvider<WeeklyGoalProgress>((ref) async {
  final user = SupabaseConfig.currentUser;
  if (user == null) {
    return WeeklyGoalProgress.empty(DateTime.now());
  }

  final service = ref.read(weeklyGoalProgressServiceProvider);
  return service.getWeeklyProgress(userId: user.id);
});
