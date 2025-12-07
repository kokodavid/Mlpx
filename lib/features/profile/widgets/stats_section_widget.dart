import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/app_colors.dart';

class StatsSectionWidget extends ConsumerWidget {
  final Map<String, int> stats;

  const StatsSectionWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Courses\nCompleted', 
              stats['courses_completed']?.toString() ?? '0'
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.borderColor,
          ),
          Expanded(
            child: _buildStatItem(
              'Lessons\nCompleted', 
              stats['lessons_completed']?.toString() ?? '0'
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.borderColor,
          ),
          Expanded(
            child: _buildStatItem(
              'Total\nModules', 
              stats['modules_completed']?.toString() ?? '0'
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textColor,
          ),
        ),
      ],
    );
  }
} 