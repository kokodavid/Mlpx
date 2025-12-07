import 'package:flutter/material.dart';
import 'package:milpress/features/course/course_models/course_model.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:milpress/features/widgets/custom_button.dart';

class CourseSuggestionCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback? onTakeCourse;
  final VoidCallback? onRetryAssessment;

  const CourseSuggestionCard({
    Key? key,
    required this.course,
    this.onTakeCourse,
    this.onRetryAssessment,
  }) : super(key: key);

  String get formattedDuration {
    final hours = course.durationInMinutes ~/ 60;
    final minutes = course.durationInMinutes % 60;
    if (hours > 0) {
      return '$hours Hours ${minutes > 0 ? "$minutes Minutes" : ""}';
    } else {
      return '$minutes Minutes';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.school,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reccomended Course',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Course description
          Text(
            course.description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          
          // Course details
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                formattedDuration,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 20),
              Icon(Icons.signal_cellular_alt, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Level ${course.level}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Start',
                  fillColor: AppColors.successColor,
                  onPressed: onTakeCourse,
                  isFilled: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Retry',
                  onPressed: onRetryAssessment,
                  isFilled: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 