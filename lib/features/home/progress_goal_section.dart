import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';

class ProgressGoalSection extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget? goalChild;
  const ProgressGoalSection({
    Key? key,
    this.onTap,
    this.goalChild,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of pills
          Row(
            children: [
              // Learning plan pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppColors.sandyLight,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  "Learning plan",
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
          
            ],
          ),
          const SizedBox(height: 16),
          // Set your weekly goal
          goalChild ??
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFEDEDED),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child:
                            Icon(Icons.flag, color: Colors.orange[700], size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        "Set your weekly goal",
                        style: TextStyle(
                          color: AppColors.textColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class WeeklyGoalProgressCard extends StatelessWidget {
  final int completed;
  final int target;
  final VoidCallback? onTap;

  const WeeklyGoalProgressCard({
    super.key,
    required this.completed,
    required this.target,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showTarget = completed < target;
    final headlineText = showTarget
        ? '$completed / $target lessons this week.'
        : '$completed lessons this week.';
    final flameColor =
        showTarget ? const Color(0xFFF4A261) : AppColors.primaryColor;
    final accentTextColor =
        showTarget ? const Color(0xFFF4A261) : AppColors.primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE9DB),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              color: flameColor,
              size: 36,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headlineText,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    showTarget
                        ? 'Keep on learning'
                        : 'Nice work today.',
                    style: TextStyle(
                      color: accentTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
