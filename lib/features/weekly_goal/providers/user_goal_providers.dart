import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/supabase_config.dart';
import '../models/user_goal_model.dart';
import '../services/user_goal_service.dart';

final userGoalServiceProvider = Provider<UserGoalService>((ref) {
  return UserGoalService(SupabaseConfig.client);
});

final activeWeeklyGoalProvider = FutureProvider<UserGoalModel?>((ref) async {
  final user = SupabaseConfig.currentUser;
  if (user == null) return null;

  final service = ref.read(userGoalServiceProvider);
  return service.fetchActiveGoal(
    userId: user.id,
    goalType: UserGoalModel.lessonsPerWeekGoalType,
  );
});

final setWeeklyGoalProvider =
    FutureProvider.family<UserGoalModel, Map<String, dynamic>>((ref, params) async {
  final user = SupabaseConfig.currentUser;
  if (user == null) {
    throw Exception('User not logged in');
  }

  final service = ref.read(userGoalServiceProvider);
  final result = await service.setWeeklyGoal(
    userId: user.id,
    lessonsPerWeek: params['lessonsPerWeek'] as int,
    timezone: params['timezone'] as String,
    weekStart: (params['weekStart'] as int?) ?? 1,
  );

  ref.invalidate(activeWeeklyGoalProvider);
  return result;
});
