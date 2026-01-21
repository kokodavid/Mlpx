import 'package:flutter/material.dart';
import 'package:milpress/features/course/course_widgets/course_info_pill.dart';

class CourseDetailHeader extends StatelessWidget {
  final String courseTitle;
  final int level;
  final int totalModules;
  final int totalLessons;

  const CourseDetailHeader({
    Key? key,
    required this.courseTitle,
    required this.level,
    required this.totalModules,
    required this.totalLessons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('ACTIVE',
            style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Level $level',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          courseTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF232B3A)),
        ),
      ],
    );
  }
}
