import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/weekly_goal/providers/weekly_goal_progress_providers.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';

class StreakPage extends ConsumerStatefulWidget {
  const StreakPage({super.key});

  @override
  ConsumerState<StreakPage> createState() => _StreakPageState();
}

class _StreakPageState extends ConsumerState<StreakPage> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _moveMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(weeklyGoalProgressProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1D1D1D)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Streak Tracking',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: progressAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          ),
          error: (_, __) => const Center(
            child: Text(
              'Unable to load streaks.',
              style: TextStyle(color: AppColors.textColor),
            ),
          ),
          data: (progress) {
            final currentDays = progress.currentStreakDays;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$currentDays',
                                    style: const TextStyle(
                                      color: AppColors.primaryColor,
                                      fontSize: 48,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Streak Days !',
                                    style: TextStyle(
                                      color: Color(0xFF111111),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    currentDays > 0
                                        ? 'This is the longest Streak\nyou have had'
                                        : 'This is the longest Streak\nyou have ever had',
                                    style: const TextStyle(
                                      color: Color(0xFF777777),
                                      fontSize: 12,
                                      height: 1.1,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.local_fire_department,
                              color: AppColors.primaryColor,
                              size: 96,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _StreakTrack(
                          currentDays: currentDays,
                          longestDays: progress.longestDailyStreak,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SetGoalTile(onTap: () => context.push('/weekly-goal')),
                  const SizedBox(height: 16),
                  _MonthHeader(
                    month: _visibleMonth,
                    onPrevious: () => _moveMonth(-1),
                    onNext: () => _moveMonth(1),
                  ),
                  const SizedBox(height: 10),
                  _StreakCalendar(
                    visibleMonth: _visibleMonth,
                    completedDates: progress.completedDates,
                    brokenDates: progress.brokenDates,
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Your record',
                    style: TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _RecordTile(
                    value: '${progress.longestDailyStreak} Day',
                    label: 'Longest Daily Streak',
                  ),
                  const SizedBox(height: 12),
                  _RecordTile(
                    value: '${progress.longestWeeklyStreak} Week',
                    label: 'Longest Weekly Streak',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StreakTrack extends StatelessWidget {
  final int currentDays;
  final int longestDays;

  const _StreakTrack({
    required this.currentDays,
    required this.longestDays,
  });

  @override
  Widget build(BuildContext context) {
    final maxDays = longestDays > currentDays ? longestDays : currentDays;
    final fraction = maxDays == 0 ? 0.0 : (currentDays / maxDays).clamp(0.0, 1.0);

    return SizedBox(
      height: 30,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final knobLeft = (width - 24) * fraction;

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                left: 14,
                right: 8,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                width: (width - 22) * fraction,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                left: knobLeft,
                child: _MiniFlameBadge(value: currentDays),
              ),
              if (currentDays > 0)
                Positioned(
                  right: 0,
                  child: _MiniFlameBadge(value: maxDays),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniFlameBadge extends StatelessWidget {
  final int value;

  const _MiniFlameBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryColor,
      ),
      alignment: Alignment.center,
      child: Text(
        value.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SetGoalTile extends StatelessWidget {
  final VoidCallback onTap;

  const _SetGoalTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEEEEEE),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.local_fire_department,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Set Streak Goal',
                  style: TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEFEFEF),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF333333),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left, color: Color(0xFF333333)),
        ),
        Expanded(
          child: Text(
            _monthName(month.month),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF222222),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, color: Color(0xFF333333)),
        ),
      ],
    );
  }

  static String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }
}

class _StreakCalendar extends StatelessWidget {
  final DateTime visibleMonth;
  final Set<DateTime> completedDates;
  final Set<DateTime> brokenDates;

  const _StreakCalendar({
    required this.visibleMonth,
    required this.completedDates,
    required this.brokenDates,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TableCalendar<DateTime>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: visibleMonth,
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerVisible: false,
        availableGestures: AvailableGestures.none,
        daysOfWeekHeight: 28,
        rowHeight: 32,
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          cellMargin: EdgeInsets.zero,
          defaultTextStyle: TextStyle(fontSize: 0),
          weekendTextStyle: TextStyle(fontSize: 0),
          todayTextStyle: TextStyle(fontSize: 0),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: Color(0xFF111111),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: TextStyle(
            color: Color(0xFF111111),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        calendarBuilders: CalendarBuilders<DateTime>(
          defaultBuilder: (context, day, focusedDay) {
            return _buildDay(day);
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildDay(day);
          },
          outsideBuilder: (context, day, focusedDay) {
            return const SizedBox.shrink();
          },
          disabledBuilder: (context, day, focusedDay) {
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _CalendarMarker(
      day: day.day,
      isCompleted: completedDates.contains(date),
      isBroken: brokenDates.contains(date),
    );
  }
}

class _CalendarMarker extends StatelessWidget {
  final int day;
  final bool isCompleted;
  final bool isBroken;

  const _CalendarMarker({
    required this.day,
    required this.isCompleted,
    required this.isBroken,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return const Center(
        child: Icon(
          Icons.local_fire_department,
          color: AppColors.primaryColor,
          size: 18,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isBroken ? const Color(0xFFE6E7E8) : Colors.transparent,
      ),
      alignment: Alignment.center,
      child: Text(
        day.toString(),
        style: TextStyle(
          color: isBroken ? Colors.white : const Color(0xFF333333),
          fontSize: 12,
          fontWeight: isBroken ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final String value;
  final String label;

  const _RecordTile({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: AppColors.primaryColor,
            size: 38,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFC76325),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
