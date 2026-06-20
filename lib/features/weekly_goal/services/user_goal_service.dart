import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_goal_model.dart';

class UserGoalService {
  final SupabaseClient _supabase;

  UserGoalService(this._supabase);

  Future<UserGoalModel?> fetchActiveGoal({
    required String userId,
    required String goalType,
  }) async {
    final response = await _supabase
        .from('user_goals')
        .select()
        .eq('user_id', userId)
        .eq('goal_type', goalType)
        .filter('active_until', 'is', null)
        .order('active_from', ascending: false)
        .maybeSingle();

    if (response == null) return null;
    return UserGoalModel.fromJson(response);
  }

  Future<UserGoalModel> setStreakGoal({
    required String userId,
    required int streakDays,
    required String timezone,
    int weekStart = 1,
  }) async {
    _validateStreakGoalInput(
      userId: userId,
      streakDays: streakDays,
      timezone: timezone,
      weekStart: weekStart,
    );
    final now = DateTime.now().toUtc();

    await _supabase
        .from('user_goals')
        .update({'active_until': now.toIso8601String()})
        .eq('user_id', userId)
        .eq('goal_type', UserGoalModel.streakDaysGoalType)
        .filter('active_until', 'is', null);

    final insertPayload = {
      'user_id': userId,
      'goal_type': UserGoalModel.streakDaysGoalType,
      'goal_value': streakDays,
      'timezone': timezone,
      'week_start': weekStart,
      'active_from': now.toIso8601String(),
    };

    final response = await _supabase
        .from('user_goals')
        .insert(insertPayload)
        .select()
        .single();

    return UserGoalModel.fromJson(response);
  }

  void _validateStreakGoalInput({
    required String userId,
    required int streakDays,
    required String timezone,
    required int weekStart,
  }) {
    if (userId.trim().isEmpty) {
      throw ArgumentError('User id is required.');
    }
    if (streakDays <= 0) {
      throw ArgumentError('Streak goal must be greater than 0.');
    }
    if (timezone.trim().isEmpty) {
      throw ArgumentError('Timezone is required.');
    }
    if (weekStart < 1 || weekStart > 7) {
      throw ArgumentError('Week start must be between 1 and 7.');
    }
  }
}
