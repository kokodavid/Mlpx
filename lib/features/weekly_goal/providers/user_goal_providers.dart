import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/supabase_config.dart';
import '../models/user_goal_model.dart';
import '../services/user_goal_service.dart';

final userGoalServiceProvider = Provider<UserGoalService>((ref) {
  return UserGoalService(SupabaseConfig.client);
});

final activeStreakGoalProvider = FutureProvider<UserGoalModel?>((ref) async {
  final user = SupabaseConfig.currentUser;
  if (user == null) return null;

  final service = ref.read(userGoalServiceProvider);
  return service.fetchActiveGoal(
    userId: user.id,
    goalType: UserGoalModel.streakDaysGoalType,
  );
});

final setStreakGoalProvider =
    FutureProvider.family<UserGoalModel, Map<String, dynamic>>((ref, params) async {
  final user = SupabaseConfig.currentUser;
  if (user == null) {
    throw Exception('User not logged in');
  }

  final service = ref.read(userGoalServiceProvider);
  final result = await service.setStreakGoal(
    userId: user.id,
    streakDays: params['streakDays'] as int,
    timezone: params['timezone'] as String,
    weekStart: (params['weekStart'] as int?) ?? 1,
  );

  ref.invalidate(activeStreakGoalProvider);
  return result;
});
