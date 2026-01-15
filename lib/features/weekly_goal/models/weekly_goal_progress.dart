class WeeklyGoalProgress {
  final int completedLessons;
  final DateTime weekStart;
  final DateTime weekEnd;

  WeeklyGoalProgress({
    required this.completedLessons,
    required this.weekStart,
    required this.weekEnd,
  });

  factory WeeklyGoalProgress.empty(DateTime nowLocal) {
    final startOfDay = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final weekStart =
        startOfDay.subtract(Duration(days: startOfDay.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return WeeklyGoalProgress(
      completedLessons: 0,
      weekStart: weekStart,
      weekEnd: weekEnd,
    );
  }
}
