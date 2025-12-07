import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';

class CourseProgressCard extends StatelessWidget {
  final int totalModules;
  final int totalLessons;
  final int completedLessons;
  final int completedModules;

  const CourseProgressCard({
    Key? key,
    required this.totalModules,
    required this.totalLessons,
    required this.completedLessons,
    required this.completedModules,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = totalLessons > 0 ? completedLessons / totalLessons : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school, size: 40, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            '$completedModules Module${completedModules == 1 ? '' : 's'} completed',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF232B3A)),
          ),
          const SizedBox(height: 6),
          Text(
            '${totalLessons - completedLessons} lesson${totalLessons - completedLessons == 1 ? '' : 's'} remaining',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% complete',
                style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              const Spacer(),
              Text(
                'You study 20 minutes a day',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: AppColors.primaryColor.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
