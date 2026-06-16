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
    final activeGoal = await _fetchActiveGoal(userId: userId);
    final weekStartDay = activeGoal?['week_start'] as int? ?? 1;
    final activeFrom = _parseDateTime(activeGoal?['active_from']);
    final weekStartLocal = _startOfGoalWindow(
      date: startOfDay,
      weekStart: weekStartDay,
      activeFrom: activeFrom,
    );
    final weekEndLocal = weekStartLocal.add(const Duration(days: 7));

    final completedLessonsById =
        await _fetchCompletedLessonsById(userId: userId);
    final completedAtValues = completedLessonsById.values.toList()
      ..sort();

    final completedLessons = completedAtValues.where((date) {
      return !date.isBefore(weekStartLocal) && date.isBefore(weekEndLocal);
    }).length;

    final completedDates = completedAtValues
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet();
    final brokenDates = _calculateBrokenDates(
      completedDates: completedDates,
      today: startOfDay,
    );

    return WeeklyGoalProgress(
      completedLessons: completedLessons,
      weekStart: weekStartLocal,
      weekEnd: weekEndLocal,
      currentStreakDays: _calculateCurrentStreak(
        completedDates: completedDates,
        today: startOfDay,
      ),
      completedDates: completedDates,
      brokenDates: brokenDates,
      longestDailyStreak: _calculateLongestDailyStreak(completedDates),
      longestWeeklyStreak: _calculateLongestWeeklyStreak(completedDates),
    );
  }

  Future<Map<String, dynamic>?> _fetchActiveGoal({
    required String userId,
  }) async {
    final response = await _supabase
        .from('user_goals')
        .select('week_start, active_from')
        .eq('user_id', userId)
        .eq('goal_type', 'lessons_per_week')
        .filter('active_until', 'is', null)
        .order('active_from', ascending: false)
        .maybeSingle();

    return response;
  }

  Future<Map<String, DateTime>> _fetchCompletedLessonsById({
    required String userId,
  }) async {
    final completedLessonsById = <String, DateTime>{};

    final lessonCompletionResponse = await _supabase
        .from('lesson_completion')
        .select('lesson_id, completed_at')
        .eq('user_id', userId)
        .not('completed_at', 'is', null)
        .order('completed_at', ascending: true);

    _addCompletedLessons(
      completedLessonsById,
      lessonCompletionResponse as List,
    );

    return completedLessonsById;
  }

  void _addCompletedLessons(
    Map<String, DateTime> completedLessonsById,
    List rows,
  ) {
    for (final row in rows) {
      if (row is! Map) continue;

      final completedAt = _parseDateTime(row['completed_at']);
      if (completedAt == null) continue;

      final lessonId = row['lesson_id'] as String?;
      if (lessonId == null || lessonId.isEmpty) continue;

      final localCompletedAt = completedAt.toLocal();
      final existing = completedLessonsById[lessonId];
      if (existing == null || localCompletedAt.isBefore(existing)) {
        completedLessonsById[lessonId] = localCompletedAt;
      }
    }
  }

  DateTime _startOfWeek(DateTime date, int weekStart) {
    final normalizedWeekStart = weekStart.clamp(1, 7).toInt();
    final daysSinceWeekStart =
        (date.weekday - normalizedWeekStart + DateTime.daysPerWeek) %
            DateTime.daysPerWeek;
    return date.subtract(Duration(days: daysSinceWeekStart));
  }

  DateTime _startOfGoalWindow({
    required DateTime date,
    required int weekStart,
    required DateTime? activeFrom,
  }) {
    if (activeFrom == null) return _startOfWeek(date, weekStart);

    final localActiveFrom = activeFrom.toLocal();
    final anchor = DateTime(
      localActiveFrom.year,
      localActiveFrom.month,
      localActiveFrom.day,
    );
    final elapsedDays = date.difference(anchor).inDays;
    if (elapsedDays < 0) return anchor;

    final elapsedWeeks = elapsedDays ~/ DateTime.daysPerWeek;
    return anchor.add(Duration(days: elapsedWeeks * DateTime.daysPerWeek));
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Set<DateTime> _calculateBrokenDates({
    required Set<DateTime> completedDates,
    required DateTime today,
  }) {
    if (completedDates.isEmpty) return {};
    final firstDate = completedDates.reduce(
      (first, date) => date.isBefore(first) ? date : first,
    );
    final brokenDates = <DateTime>{};

    for (var date = firstDate;
        !date.isAfter(today);
        date = date.add(const Duration(days: 1))) {
      if (!completedDates.contains(date)) {
        brokenDates.add(date);
      }
    }

    return brokenDates;
  }

  int _calculateCurrentStreak({
    required Set<DateTime> completedDates,
    required DateTime today,
  }) {
    var streak = 0;
    var cursor = today;

    while (completedDates.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int _calculateLongestDailyStreak(Set<DateTime> completedDates) {
    if (completedDates.isEmpty) return 0;

    final sortedDates = completedDates.toList()..sort();
    var longest = 1;
    var current = 1;

    for (var index = 1; index < sortedDates.length; index += 1) {
      final previous = sortedDates[index - 1];
      final currentDate = sortedDates[index];
      if (currentDate.difference(previous).inDays == 1) {
        current += 1;
      } else {
        current = 1;
      }
      if (current > longest) longest = current;
    }

    return longest;
  }

  int _calculateLongestWeeklyStreak(Set<DateTime> completedDates) {
    if (completedDates.isEmpty) return 0;

    final fullWeeks = completedDates
        .map((date) => date.subtract(Duration(days: date.weekday - 1)))
        .toSet()
        .toList()
      ..sort();

    fullWeeks.removeWhere((weekStart) {
      for (var dayOffset = 0; dayOffset < DateTime.daysPerWeek; dayOffset++) {
        final day = weekStart.add(Duration(days: dayOffset));
        if (!completedDates.contains(day)) {
          return true;
        }
      }
      return false;
    });

    if (fullWeeks.isEmpty) return 0;

    var longest = 1;
    var current = 1;

    for (var index = 1; index < fullWeeks.length; index += 1) {
      final previous = fullWeeks[index - 1];
      final currentWeek = fullWeeks[index];
      if (currentWeek.difference(previous).inDays == 7) {
        current += 1;
      } else {
        current = 1;
      }
      if (current > longest) longest = current;
    }

    return longest;
  }
}
