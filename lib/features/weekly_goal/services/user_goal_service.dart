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

  Future<UserGoalModel> setWeeklyGoal({
    required String userId,
    required int lessonsPerWeek,
    required String timezone,
    int weekStart = 1,
  }) async {
    _validateWeeklyGoalInput(
      userId: userId,
      lessonsPerWeek: lessonsPerWeek,
      timezone: timezone,
      weekStart: weekStart,
    );
    final now = DateTime.now().toUtc();

    await _supabase
        .from('user_goals')
        .update({'active_until': now.toIso8601String()})
        .eq('user_id', userId)
        .eq('goal_type', UserGoalModel.lessonsPerWeekGoalType)
        .filter('active_until', 'is', null);

    final insertPayload = {
      'user_id': userId,
      'goal_type': UserGoalModel.lessonsPerWeekGoalType,
      'goal_value': lessonsPerWeek,
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

  void _validateWeeklyGoalInput({
    required String userId,
    required int lessonsPerWeek,
    required String timezone,
    required int weekStart,
  }) {
    if (userId.trim().isEmpty) {
      throw ArgumentError('User id is required.');
    }
    if (lessonsPerWeek <= 0) {
      throw ArgumentError('Weekly goal must be greater than 0.');
    }
    if (timezone.trim().isEmpty) {
      throw ArgumentError('Timezone is required.');
    }
    if (weekStart < 1 || weekStart > 7) {
      throw ArgumentError('Week start must be between 1 and 7.');
    }
  }
}
