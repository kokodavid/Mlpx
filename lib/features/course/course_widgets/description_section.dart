import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';

class DescriptionSection extends StatelessWidget {
  final String courseTitle;
  final int level;
  final int totalModules;
  final int totalLessons;
  final String description;

  const DescriptionSection({
    Key? key,
    required this.courseTitle,
    required this.level,
    required this.totalModules,
    required this.totalLessons,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What you'll learn in this level:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                courseTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 15, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.grey, thickness: 0.2),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.menu_book, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('$totalModules Modules',
                      style: const TextStyle(fontSize: 15, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.menu, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('$totalLessons Lessons',
                      style: const TextStyle(fontSize: 15, color: Colors.black87)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
