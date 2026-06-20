class WeeklyGoalProgress {
  final int completedStreakDays;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int currentStreakDays;
  final Set<DateTime> completedDates;
  final Set<DateTime> brokenDates;
  final int longestDailyStreak;
  final int longestWeeklyStreak;

  WeeklyGoalProgress({
    required this.completedStreakDays,
    required this.weekStart,
    required this.weekEnd,
    required this.currentStreakDays,
    required this.completedDates,
    required this.brokenDates,
    required this.longestDailyStreak,
    required this.longestWeeklyStreak,
  });

  factory WeeklyGoalProgress.empty(DateTime nowLocal) {
    final startOfDay = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final weekStart =
        startOfDay.subtract(Duration(days: startOfDay.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return WeeklyGoalProgress(
      completedStreakDays: 0,
      weekStart: weekStart,
      weekEnd: weekEnd,
      currentStreakDays: 0,
      completedDates: const {},
      brokenDates: const {},
      longestDailyStreak: 0,
      longestWeeklyStreak: 0,
    );
  }

  factory WeeklyGoalProgress.fromJson(Map<String, dynamic> json) {
    return WeeklyGoalProgress(
      completedStreakDays: (json['completedStreakDays'] as int?) ??
          (json['completedLessons'] as int?) ??
          0,
      weekStart: DateTime.parse(json['weekStart'] as String),
      weekEnd: DateTime.parse(json['weekEnd'] as String),
      currentStreakDays: json['currentStreakDays'] as int? ?? 0,
      completedDates: _dateSetFromJson(json['completedDates']),
      brokenDates: _dateSetFromJson(json['brokenDates']),
      longestDailyStreak: json['longestDailyStreak'] as int? ?? 0,
      longestWeeklyStreak: json['longestWeeklyStreak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completedStreakDays': completedStreakDays,
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'currentStreakDays': currentStreakDays,
      'completedDates': completedDates
          .map((date) => date.toIso8601String())
          .toList(growable: false),
      'brokenDates': brokenDates
          .map((date) => date.toIso8601String())
          .toList(growable: false),
      'longestDailyStreak': longestDailyStreak,
      'longestWeeklyStreak': longestWeeklyStreak,
    };
  }

  static Set<DateTime> _dateSetFromJson(dynamic value) {
    if (value is! List) return {};
    return value
        .whereType<String>()
        .map(DateTime.parse)
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet();
  }
}
