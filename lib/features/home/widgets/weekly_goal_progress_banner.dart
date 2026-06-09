import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/weekly_goal/providers/user_goal_providers.dart';
import 'package:milpress/features/weekly_goal/providers/weekly_goal_progress_providers.dart';
import 'package:milpress/utils/app_colors.dart';

class WeeklyGoalProgressBanner extends ConsumerWidget {
  const WeeklyGoalProgressBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(activeWeeklyGoalProvider);
    final progressAsync = ref.watch(weeklyGoalProgressProvider);
    final goal = goalAsync.valueOrNull;

    if (goal == null) return const SizedBox.shrink();

    final completedLessons = progressAsync.valueOrNull?.completedLessons ?? 0;
    final goalValue = goal.goalValue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/streak-page'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 11, 11, 11),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8DC),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text(
                  '🔥',
                  style: TextStyle(fontSize: 34, height: 1),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$completedLessons/$goalValue this week.',
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Nice work today. Keep\nLearning',
                        style: TextStyle(
                          color: Color(0xFFC76E32),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryColor,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
