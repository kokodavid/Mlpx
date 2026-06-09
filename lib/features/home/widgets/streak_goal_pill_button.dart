import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';

class StreakGoalPillButton extends StatelessWidget {
  final int completedLessons;
  final int goalValue;
  final VoidCallback? onTap;

  const StreakGoalPillButton({
    super.key,
    required this.completedLessons,
    required this.goalValue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: AppColors.copBlue,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department_outlined,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(width: 4),
              Text(
                '$completedLessons/$goalValue',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
