import 'package:flutter/material.dart';

enum CourseHeaderStatus {
  active,
  completed,
  none,
}

class CourseDetailHeader extends StatelessWidget {
  final String courseTitle;
  final int level;
  final int totalModules;
  final int totalLessons;
  final CourseHeaderStatus status;

  const CourseDetailHeader({
    Key? key,
    required this.courseTitle,
    required this.level,
    required this.totalModules,
    required this.totalLessons,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? statusLabel;
    Color? statusColor;

    switch (status) {
      case CourseHeaderStatus.active:
        statusLabel = 'ACTIVE';
        statusColor = Colors.green[700];
        break;
      case CourseHeaderStatus.completed:
        statusLabel = 'COMPLETED';
        statusColor = Colors.green[800];
        break;
      case CourseHeaderStatus.none:
        statusLabel = null;
        statusColor = null;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (statusLabel != null) ...[
          Text(statusLabel,
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 8),
        ],
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
